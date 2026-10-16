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

  ActiveEvent _current = ActiveEvent.fallback;
  ActiveEvent get current => _current;

  Future<void> loadCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final cached = ActiveEvent.fromJson(jsonDecode(raw));
      if (cached != null) _current = cached;
    } catch (e) {
      debugPrint('ActiveEvent: ignoring unreadable cache ($e)');
    }
  }

  Future<void> refresh() async {
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
