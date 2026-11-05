import 'dart:convert';
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../dioServices/base_url.dart';
import '../../dioServices/dioClient.dart';
import '../../providers.dart';
import '../active_event/active_event.dart';

/// Links to hosted forms shown in a WebView, read from the Directus
/// `app_webview_links` singleton. Changing a form is done in Directus, not
/// with a new build.
///
/// Startup mirrors ActiveEventService: [loadCached] restores the last fetched
/// links, then [refresh] fetches the current ones in the background.
class WebviewLinksService extends ChangeNotifier {
  WebviewLinksService._();
  static final WebviewLinksService instance = WebviewLinksService._();

  static const String _prefsKey = 'webview_links_cache';
  static const String _fields = 'event_feedback_form';

  Map<String, dynamic> _links = const {};

  /// The feedback form URL, or null when unset or not an http(s) URL.
  String? get feedbackFormUrl => _validUrl(_links['event_feedback_form']);

  Future<void> loadCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final cached = jsonDecode(raw);
      if (cached is Map<String, dynamic>) _links = cached;
    } catch (e) {
      debugPrint('WebviewLinks: ignoring unreadable cache ($e)');
    }
  }

  Future<void> refresh() async {
    try {
      final response = await DioClient().init().get(
            '${BaseURL.Baseurl}/items/app_webview_links',
            queryParameters: {'fields': _fields},
          );
      var data = response.data is Map ? response.data['data'] : null;
      // A singleton collection returns an object; a regular one a list of
      // rows. Accept both and use the first row.
      if (data is List) data = data.isNotEmpty ? data.first : null;
      if (data is! Map<String, dynamic>) return;
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(data);
      await prefs.setString(_prefsKey, encoded);
      if (encoded != jsonEncode(_links)) {
        _links = data;
        notifyListeners();
      }
    } on DioError catch (e) {
      // Offline, or the collection missing/forbidden: keep the cached links.
      debugPrint('WebviewLinks: refresh failed (${e.response?.statusCode ?? e.message})');
    } catch (e) {
      debugPrint('WebviewLinks: refresh failed ($e)');
    }
  }

  static String? _validUrl(Object? value) {
    final s = value?.toString().trim() ?? '';
    if (s.isEmpty) return null;
    final uri = Uri.tryParse(s);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https')) || uri.host.isEmpty) {
      return null;
    }
    return s;
  }
}

/// The attendee details stored with every WebView form submission
/// (`app_webview_links_data.user_details`) and handed to the page as
/// `window.DX5_USER`.
///
/// `attendee_id` is [ProfileProvider.userID] (event_registrations.attendeeId).
/// Not `profileId`: that one holds the profile photo file id.
Map<String, dynamic> buildUserDetails(ProfileProvider profile, ActiveEvent event) {
  final name = '${profile.firstName} ${profile.lastName}'.trim();
  return {
    'attendee_id': profile.userID,
    'first_name': profile.firstName,
    'last_name': profile.lastName,
    'name': name,
    'email': profile.email,
    'phone': profile.phone,
    'company': profile.company,
    'role': profile.role,
    'event_id': event.id,
    'event_title': event.title,
    'platform': kIsWeb ? 'web' : Platform.operatingSystem,
  };
}
