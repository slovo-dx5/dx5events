import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../dioServices/base_url.dart';
import '../../dioServices/dioClient.dart';
import 'active_event.dart';

/// Holds the event the app opens on. Switching events is done in Directus
/// (the `app_config` singleton's `active_event`), not with a new build.
///
/// Startup: [loadCached] restores the last fetched event synchronously enough
/// for cold starts from a notification, then [refresh] fetches the current
/// one in the background and notifies listeners if it changed. With no cache
/// and no network the app runs on [ActiveEvent.fallback].
class ActiveEventService extends ChangeNotifier {
  ActiveEventService._();
  static final ActiveEventService instance = ActiveEventService._();

  static const String _prefsKey = 'active_event_cache';
  static const String _fields = 'tagline,card_image,cover_image,'
      'active_event.id,active_event.title,active_event.date_from,'
      'active_event.date_to,active_event.country,active_event.venue,'
      'active_event.summary,active_event.banner';

  // ---- Companion event (e.g. ACLS alongside CIO100) ----
  // Lives in its own app_config fields, fetched in a separate request: asking
  // Directus for a field that doesn't exist yet fails the whole request, and
  // that must never take the active event down with it.
  static const String _companionPrefsKey = 'companion_event_cache';
  static const String _companionFields = 'companion_enabled,'
      'companion_event.id,companion_event.title,companion_event.date_from,'
      'companion_event.date_to,companion_event.country,companion_event.venue,'
      'companion_event.summary';

  /// Demo switch: true makes every build (release too) treat today as ACLS
  /// day and replay the Signal Hijack intro on every launch. Keep false in
  /// release builds; the takeover then opens by itself on the ACLS date.
  static const bool kAclsDemoMode = false;

  static const String _companionDisabledKey = 'companion_disabled';

  /// Built-in companion: ACLS on CIO100's last day. Used until Directus says
  /// otherwise (`app_config.companion_event`), so the gate opens on 27 Nov
  /// even if those fields are never set up.
  static final ActiveEvent _builtInCompanion = ActiveEvent(
    id: ActiveEvent.aclsEventId,
    title: ActiveEvent.aclsTitle,
    dateFrom: DateTime(2026, 11, 27, 8),
    dateTo: DateTime(2026, 11, 27, 18),
    country: 'Kenya',
    venue: ActiveEvent.fallback.venue,
  );

  /// Hard lock: the takeover never opens before this day (Nairobi time), even
  /// if Directus gives the companion an earlier date. Demo/force bypass it.
  static final DateTime _companionLockedUntil = DateTime(2026, 11, 27);

  /// Debug builds can also force it with `--dart-define=ACLS_FORCE_DAY=true`.
  static const bool _forceCompanionDay = kAclsDemoMode ||
      (kDebugMode && bool.fromEnvironment('ACLS_FORCE_DAY'));

  /// Time source for the ACLS date gate; tests replace it.
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  ActiveEvent _current = ActiveEvent.fallback;
  ActiveEvent get current => _current;

  ActiveEvent? _companion;

  /// Directus set `app_config.companion_enabled` to false: the kill switch.
  bool _companionDisabled = false;

  /// The event running alongside [current]: `app_config.companion_event`
  /// when set, else the built-in ACLS. Null only when Directus switched it
  /// off with `companion_enabled = false` (demo mode ignores that).
  ActiveEvent? get companion {
    if (_companion != null) return _companion;
    if (_companionDisabled && !_forceCompanionDay) return null;
    return _builtInCompanion;
  }

  /// True on the companion's day(s) at the venue (Nairobi time, UTC+3 all
  /// year), which is when the takeover UI shows. False after it ends.
  bool get isCompanionDay {
    final c = companion;
    if (c == null) return false;
    if (_forceCompanionDay) return true;
    final now = clock().toUtc().add(const Duration(hours: 3));
    final today = DateTime(now.year, now.month, now.day);
    if (today.isBefore(_companionLockedUntil)) return false;
    final from = DateTime(c.dateFrom.year, c.dateFrom.month, c.dateFrom.day);
    final to = DateTime(c.dateTo.year, c.dateTo.month, c.dateTo.day);
    return !today.isBefore(from) && !today.isAfter(to);
  }

  /// True until the companion has ended (Nairobi time), for teasers that
  /// lead up to it, such as the agenda link.
  bool get isCompanionUpcomingOrLive {
    final c = companion;
    if (c == null) return false;
    if (_forceCompanionDay) return true;
    final now = clock().toUtc().add(const Duration(hours: 3));
    final today = DateTime(now.year, now.month, now.day);
    return !today.isAfter(DateTime(c.dateTo.year, c.dateTo.month, c.dateTo.day));
  }

  Future<void> loadCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        final cached = ActiveEvent.fromJson(jsonDecode(raw));
        if (cached != null) _current = cached;
      }
      _companionDisabled = prefs.getBool(_companionDisabledKey) ?? false;
      final rawCompanion = prefs.getString(_companionPrefsKey);
      if (rawCompanion != null) {
        _companion = ActiveEvent.fromJson(jsonDecode(rawCompanion));
      }
    } catch (e) {
      debugPrint('ActiveEvent: ignoring unreadable cache ($e)');
    }
  }

  Future<void> refresh() async {
    await Future.wait([_refreshActive(), _refreshCompanion()]);
  }

  Future<void> _refreshCompanion() async {
    ActiveEvent? fetched;
    var disabled = false;
    try {
      final response = await DioClient().init().get(
            '${BaseURL.Baseurl}/items/app_config',
            queryParameters: {'fields': _companionFields},
          );
      final data = response.data is Map ? response.data['data'] : null;
      if (data is Map && data['companion_enabled'] == false) {
        disabled = true;
      } else if (data is Map && data['companion_enabled'] == true) {
        fetched = ActiveEvent.fromAppConfig(
            {'active_event': data['companion_event']});
      }
    } on DioError catch (e) {
      // Offline: keep the cached state. A response (403 while the fields
      // don't exist yet) means "not configured": use the built-in ACLS.
      if (e.response == null) return;
      debugPrint('ActiveEvent: no companion (${e.response?.statusCode})');
    } catch (e) {
      debugPrint('ActiveEvent: companion refresh failed ($e)');
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_companionDisabledKey, disabled);
      if (fetched == null) {
        await prefs.remove(_companionPrefsKey);
      } else {
        await prefs.setString(
            _companionPrefsKey, jsonEncode(fetched.toJson()));
      }
    } catch (_) {}
    final before = _companion == null ? null : jsonEncode(_companion!.toJson());
    final after = fetched == null ? null : jsonEncode(fetched.toJson());
    if (before != after || disabled != _companionDisabled) {
      _companion = fetched;
      _companionDisabled = disabled;
      notifyListeners();
    }
  }

  Future<void> _refreshActive() async {
    try {
      final response = await DioClient().init().get(
            '${BaseURL.Baseurl}/items/app_config',
            queryParameters: {'fields': _fields},
          );
      final data = response.data is Map ? response.data['data'] : null;
      final fetched =
          data is Map<String, dynamic> ? ActiveEvent.fromAppConfig(data) : null;
      if (fetched == null) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(fetched.toJson()));
      if (jsonEncode(fetched.toJson()) != jsonEncode(_current.toJson())) {
        _current = fetched;
        notifyListeners();
      }
    } on DioError catch (e) {
      // Offline, or app_config missing/forbidden: keep the cached event.
      debugPrint('ActiveEvent: refresh failed (${e.response?.statusCode ?? e.message})');
    } catch (e) {
      debugPrint('ActiveEvent: refresh failed ($e)');
    }
  }
}
