import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../screens/shop/shop_repository.dart';

/// A low-battery suggestion ready to show: the level that triggered it and
/// the in-stock power banks to offer, cheapest first.
class BatteryNudge {
  const BatteryNudge({required this.level, required this.powerBanks});

  final int level;
  final List<Product> powerBanks;

  Product get featured => powerBanks.first;
}

/// Gently suggests a power bank from the shop when the phone is running low.
///
/// Rules, kept deliberately conservative so it reads as helpful, not naggy:
/// - battery below [kBatteryNudgeThreshold]% and not plugged in;
/// - the shop actually has an in-stock product in [kPowerBankCategory];
/// - at most once per app run, then [shownCooldown] before the next, or
///   [declinedCooldown] after the attendee taps "Not now";
/// - never while checkout or payment is on screen ([mute]).
///
/// The battery is read on start, on resume, whenever the charging state
/// changes, and every [_pollEvery] while the app is in the foreground. No
/// permission is needed on Android or iOS.
class BatteryNudgeService with WidgetsBindingObserver {
  BatteryNudgeService._();

  static final BatteryNudgeService instance = BatteryNudgeService._();

  static const Duration shownCooldown = Duration(hours: 6);
  static const Duration declinedCooldown = Duration(hours: 24);
  static const Duration _pollEvery = Duration(minutes: 5);

  /// Grace period after launch, so the app has settled before anything slides in.
  static const Duration _startDelay = Duration(seconds: 10);

  static const String _shownKey = 'battery_nudge_last_v1';
  static const String _declinedKey = 'battery_nudge_declined_v1';

  /// The suggestion to show, or null. Listened to by `BatteryNudgeHost`.
  final ValueNotifier<BatteryNudge?> nudge = ValueNotifier(null);

  /// True while the battery is low and unplugged, whatever the cooldowns say.
  /// The shop uses it to pin power banks first; that's passive, so it isn't
  /// rate-limited the way the nudge is.
  final ValueNotifier<bool> lowBattery = ValueNotifier(false);

  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _stateSub;
  Timer? _poll;
  Timer? _start;
  bool _initialized = false;
  bool _shownThisRun = false;
  bool _checking = false;
  int _muted = 0;

  bool get enabled => kShopFeatureEnabled && kBatteryNudgeEnabled;

  /// Call once the attendee is inside the app (MainNavigationPage).
  void init() {
    if (_initialized || !enabled) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    _stateSub = _battery.onBatteryStateChanged.listen(
      (_) => unawaited(check()),
      onError: (Object e) => debugPrint('[BatteryNudge] state stream: $e'),
    );
    _start = Timer(_startDelay, () => unawaited(check()));
    _startPolling();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startPolling();
      unawaited(check());
    } else if (state == AppLifecycleState.paused) {
      _poll?.cancel();
      _poll = null;
    }
  }

  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(_pollEvery, (_) => unawaited(check()));
  }

  /// Suppresses the nudge while a checkout or payment screen is open. Calls
  /// nest, so pair every [mute] with an [unmute].
  void mute() {
    _muted++;
    nudge.value = null;
  }

  void unmute() {
    if (_muted > 0) _muted--;
  }

  /// Reads the battery and shows a nudge if every rule allows it.
  Future<void> check() async {
    if (!enabled || _checking) return;
    _checking = true;
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      final low = isLow(level, state);
      lowBattery.value = low;

      if (!low) {
        // Plugged in or recovered: take down a nudge that is still showing.
        nudge.value = null;
        return;
      }
      if (nudge.value != null || _muted > 0) return;

      final prefs = await SharedPreferences.getInstance();
      final allowed = shouldNudge(
        level: level,
        state: state,
        now: DateTime.now(),
        shownThisRun: _shownThisRun,
        lastShown: _readTime(prefs, _shownKey),
        lastDeclined: _readTime(prefs, _declinedKey),
      );
      if (!allowed) return;

      // Only touch the catalogue once the cheap checks pass. Usually cached.
      final catalogue = await ShopRepository.load();
      final banks = powerBanksIn(catalogue.products);
      if (banks.isEmpty || _muted > 0) return;

      _shownThisRun = true;
      await prefs.setInt(_shownKey, DateTime.now().millisecondsSinceEpoch);
      nudge.value = BatteryNudge(level: level, powerBanks: banks);
    } catch (e) {
      // Some devices (emulators, desktops) report no battery. Never a crash.
      debugPrint('[BatteryNudge] check failed: $e');
    } finally {
      _checking = false;
    }
  }

  /// Updates [lowBattery] only, never shows a nudge. For the shop screen,
  /// which reacts to low battery passively and shouldn't pop a card on top of
  /// itself.
  Future<void> refreshLowBattery() async {
    if (!enabled) return;
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      lowBattery.value = isLow(level, state);
    } catch (e) {
      debugPrint('[BatteryNudge] refresh failed: $e');
    }
  }

  /// Hides the nudge. [declined] ("Not now") starts the longer cooldown.
  Future<void> dismiss({bool declined = false}) async {
    nudge.value = null;
    if (!declined) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_declinedKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('[BatteryNudge] save failed: $e');
    }
  }

  static DateTime? _readTime(SharedPreferences prefs, String key) {
    final ms = prefs.getInt(key);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  @visibleForTesting
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stateSub?.cancel();
    _poll?.cancel();
    _start?.cancel();
    _initialized = false;
  }

  // ── Pure rules (unit-tested in test/battery_nudge_test.dart) ──────────────

  /// Low and running on battery. Charging, full, or plugged in but not
  /// charging all count as "not a problem right now"; unknown is treated as
  /// unplugged, because the level alone is still meaningful.
  static bool isLow(int level, BatteryState state) {
    if (level < 0 || level >= kBatteryNudgeThreshold) return false;
    switch (state) {
      case BatteryState.charging:
      case BatteryState.full:
      case BatteryState.connectedNotCharging:
        return false;
      case BatteryState.discharging:
      case BatteryState.unknown:
        return true;
    }
  }

  /// Whether a nudge may be shown now, ignoring stock (see [powerBanksIn]).
  static bool shouldNudge({
    required int level,
    required BatteryState state,
    required DateTime now,
    required bool shownThisRun,
    DateTime? lastShown,
    DateTime? lastDeclined,
  }) {
    if (!isLow(level, state) || shownThisRun) return false;
    if (lastShown != null && now.difference(lastShown) < shownCooldown) {
      return false;
    }
    if (lastDeclined != null &&
        now.difference(lastDeclined) < declinedCooldown) {
      return false;
    }
    return true;
  }

  /// In-stock power banks, cheapest first (after any discount).
  static List<Product> powerBanksIn(List<Product> products) {
    final want = kPowerBankCategory.toLowerCase();
    return products
        .where((p) => p.category.trim().toLowerCase() == want && !p.soldOut)
        .toList()
      ..sort((a, b) => a.price.compareTo(b.price));
  }
}
