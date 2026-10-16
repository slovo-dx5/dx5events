import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants.dart';
import '../activity_logger.dart';
import 'gamification_config.dart';
import 'gamification_models.dart';

export 'gamification_models.dart';

/// Reads points and progress from the gamification Flows and tells the user
/// when they have earned something.
///
/// The app never awards points itself: it logs activities through
/// [ActivityLogger] and a Directus Flow scores them. Awards therefore land a
/// moment after the log is flushed, so this re-reads progress shortly after
/// each successful flush and toasts the difference.
class GamificationService extends ChangeNotifier with WidgetsBindingObserver {
  GamificationService._();

  static final GamificationService instance = GamificationService._();

  /// Time for the award Flow to run after a flush before re-reading.
  static const Duration _awardDelay = Duration(seconds: 4);

  static const String _seenTotalKey = 'gamification_seen_total_v1_';
  static const String _lastOpenKey = 'gamification_last_open_day_v1';

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: 15000,
    receiveTimeout: 20000,
    validateStatus: (_) => true,
  ));

  bool _initialized = false;
  Timer? _refreshTimer;
  RewardsProgress? _progress;
  Future<RewardsProgress?>? _inFlight;

  /// Latest progress, or null before the first successful fetch.
  RewardsProgress? get progress => _progress;

  bool get isEnabled => kRewardsFeatureEnabled && GamificationConfig.isConfigured;

  /// Call once after [GamificationConfig.load] and [ActivityLogger.init].
  void init() {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    ActivityLogger.instance.addFlushListener(_scheduleRefresh);
    unawaited(logDailyOpen());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The app often stays in memory overnight, so "opened today" is checked on
    // resume as well as on launch.
    if (state == AppLifecycleState.resumed) unawaited(logDailyOpen());
  }

  /// Logs `app_open` at most once per local day — the Daily check-in signal.
  Future<void> logDailyOpen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt(kUserID);
      if (userId == null || userId <= 0) return;
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final key = '$_lastOpenKey$userId';
      if (prefs.getString(key) == today) return;
      await prefs.setString(key, today);
      await ActivityLogger.instance.log(
        action: ActivityAction.appOpen,
        userId: userId,
        metadata: {'local_day': today},
      );
    } catch (e) {
      debugPrint('GamificationService.logDailyOpen failed: $e');
    }
  }

  void _scheduleRefresh() {
    if (!isEnabled) return;
    _refreshTimer?.cancel();
    _refreshTimer = Timer(_awardDelay, () => unawaited(refresh()));
  }

  /// Fetches progress for the signed-in user. Concurrent calls share one
  /// request. Returns null when the feature is off, nobody is signed in, or
  /// the request failed (the previous [progress] is kept).
  Future<RewardsProgress?> refresh({bool announce = true}) {
    return _inFlight ??= _refresh(announce).whenComplete(() => _inFlight = null);
  }

  Future<RewardsProgress?> _refresh(bool announce) async {
    if (!isEnabled) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt(kUserID);
      if (userId == null || userId <= 0) return null;

      final res = await _dio.get(GamificationConfig.progressEndpoint,
          queryParameters: {'user_id': userId});
      final body = res.data;
      if (res.statusCode != 200 || body is! Map || body['error'] != null) {
        debugPrint('Gamification progress failed: ${res.statusCode} $body');
        return null;
      }
      final p = RewardsProgress.fromJson(Map<String, dynamic>.from(body));
      final previous = _progress;
      _progress = p;
      notifyListeners();

      final seenKey = '$_seenTotalKey$userId';
      final seen = prefs.getInt(seenKey);
      await prefs.setInt(seenKey, p.total);
      // No toast on the very first read — that would announce every point the
      // user earned before this install as if it were new.
      if (announce && seen != null && p.total > seen) {
        _announce(p.total - seen, previous, p);
      }
      return p;
    } catch (e) {
      debugPrint('Gamification progress error: $e');
      return null;
    }
  }

  void _announce(int gained, RewardsProgress? before, RewardsProgress after) {
    // Name the rule that moved when exactly one did; otherwise just the sum.
    String? what;
    if (before != null) {
      final earnedBefore = {for (final r in before.rules) r.id: r.earned};
      final moved = after.rules.where((r) => r.earned > (earnedBefore[r.id] ?? 0)).toList();
      if (moved.length == 1) what = moved.single.name;
    }
    Fluttertoast.showToast(
      msg: what == null ? '+$gained pts earned!' : '+$gained pts · $what',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: kPrimaryColor,
      textColor: const Color(0xFFFFFFFF),
    );
  }

  /// Top players plus the caller's own row. Throws [GamificationException].
  Future<Leaderboard> fetchLeaderboard({required int userId, int limit = 50}) async {
    if (!GamificationConfig.hasLeaderboard) {
      throw const GamificationException('The leaderboard is not set up yet.');
    }
    try {
      final res = await _dio.get(GamificationConfig.leaderboardEndpoint,
          queryParameters: {'user_id': userId, 'limit': limit});
      final body = res.data;
      if (res.statusCode != 200 || body is! Map) {
        throw GamificationException('Leaderboard unavailable (${res.statusCode}).');
      }
      return Leaderboard.fromJson(Map<String, dynamic>.from(body));
    } on DioError catch (e) {
      throw GamificationException('Check your connection and try again. (${e.type.name})');
    }
  }
}

class GamificationException implements Exception {
  final String message;
  const GamificationException(this.message);

  @override
  String toString() => message;
}
