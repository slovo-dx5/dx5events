import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../dioServices/base_url.dart';
import '../dioServices/dioClient.dart';
import '../models/agendaModel.dart';
import 'activity_logger.dart';
import 'agenda_bookmarks.dart';

/// One thing a delegate can rate: a plenary session with speakers, or one
/// breakout inside a breakout block.
class RateableItem {
  /// Stable identity, see [SessionRatingService.keyFor].
  final String key;
  final String title;

  /// Speaker names, already resolved for display ("Jane Doe, John Roe").
  final String speakerNames;

  /// When the slot starts and ends (for breakouts: the parent block's times).
  final DateTime start;
  final DateTime? end;

  const RateableItem({
    required this.key,
    required this.title,
    required this.speakerNames,
    required this.start,
    this.end,
  });
}

/// Session ratings: what this attendee has rated, which post-session prompts
/// they've already seen, and submitting a rating to Directus `Session_Rating`.
///
/// Rated/prompted state is cached per attendee + event in SharedPreferences.
/// On load the attendee's recent server rows are merged in by title, so a
/// rating made on another device still shows as rated.
class SessionRatingService extends ChangeNotifier {
  SessionRatingService._();
  static final SessionRatingService instance = SessionRatingService._();

  /// How long after a session ends the agenda still offers the prompt.
  static const Duration promptWindow = Duration(hours: 3);

  final DioClient _client = DioClient();

  int? _attendeeId;
  String? _eventId;
  final Set<String> _rated = {};
  final Set<String> _ratedTitles = {};
  final Set<String> _prompted = {};

  static String _norm(dynamic title) => (title ?? '')
      .toString()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();

  /// `yyyy-MM-dd|HH:mm|session title[|breakout title]`.
  static String keyFor(DateTime day, Session s, {BreakoutSession? breakout}) {
    final base = AgendaBookmarkService.keyFor(day, s);
    return breakout == null ? base : '$base|${_norm(breakout.title)}';
  }

  /// Parses an agenda "HH:mm[:ss]" on [day]; null when unparseable.
  static DateTime? timeOn(DateTime day, dynamic time) {
    final parts = (time ?? '').toString().trim().split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1].replaceAll(RegExp(r'\D'), ''));
    if (h == null || m == null) return null;
    return DateTime(day.year, day.month, day.day, h, m);
  }

  bool isRated(RateableItem item) =>
      _rated.contains(item.key) || _ratedTitles.contains(_norm(item.title));

  bool wasPrompted(String key) => _prompted.contains(key);

  String _prefsKey(String kind) => 'session_ratings_v1_${kind}_${_attendeeId}_$_eventId';

  Future<void> load({required String eventId, required int attendeeId}) async {
    if (_attendeeId == attendeeId && _eventId == eventId) return;
    _attendeeId = attendeeId;
    _eventId = eventId;
    _rated.clear();
    _ratedTitles.clear();
    _prompted.clear();

    try {
      final prefs = await SharedPreferences.getInstance();
      _rated.addAll(prefs.getStringList(_prefsKey('rated')) ?? const []);
      _prompted.addAll(prefs.getStringList(_prefsKey('prompted')) ?? const []);
    } catch (e) {
      debugPrint('[SessionRatings] cache read failed: $e');
    }
    notifyListeners();

    // Ratings from other devices. Session_Rating has no event or date field,
    // so only recent rows count, matched on the session title.
    try {
      final since = DateTime.now()
          .toUtc()
          .subtract(const Duration(days: 7))
          .toIso8601String();
      final res = await _client.init().get(
        '${BaseURL.Baseurl}/items/Session_Rating',
        queryParameters: {
          'filter': jsonEncode({
            'attendeeID': {'_eq': attendeeId},
            'date_created': {'_gte': since},
          }),
          'fields': 'sessionTitle',
          'limit': -1,
        },
      );
      final rows = (res.data['data'] as List?) ?? const [];
      for (final r in rows) {
        final t = _norm((r as Map)['sessionTitle']);
        if (t.isNotEmpty) _ratedTitles.add(t);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[SessionRatings] server read failed: $e');
    }
  }

  Future<void> markPrompted(String key) async {
    if (!_prompted.add(key)) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey('prompted'), _prompted.toList());
    } catch (_) {}
  }

  /// Sends one rating. Throws on failure so the dialog can stay open and let
  /// the delegate retry; nothing is marked rated unless the server took it.
  Future<void> submit({
    required RateableItem item,
    required int attendeeId,
    required int sessionRating,
    required int speakerRating,
    required String sessionComment,
    required String speakerComment,
  }) async {
    await _client.init().post(
      '${BaseURL.Baseurl}/items/Session_Rating',
      data: {
        'attendeeID': attendeeId,
        'sessionTitle': item.title.trim(),
        'sessionRating': sessionRating,
        'sessionComment': sessionComment.trim(),
        'speakerName': item.speakerNames,
        // 0 = not rated (no speaker, or left blank).
        'speakerRating': speakerRating,
        'speakerComment': speakerComment.trim(),
      },
    );

    _rated.add(item.key);
    _prompted.add(item.key);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey('rated'), _rated.toList());
      await prefs.setStringList(_prefsKey('prompted'), _prompted.toList());
    } catch (_) {}

    ActivityLogger.instance.log(
      action: ActivityAction.sessionRated,
      userId: attendeeId,
      eventId: _eventId,
      targetType: 'session',
      // Same shape the gamification rules expect: day|title.
      targetId: '${item.key.split('|').first}|${item.title.trim().toLowerCase()}',
      metadata: {
        'rating': sessionRating,
        if (speakerRating > 0) 'speaker_rating': speakerRating,
        'date': item.key.split('|').first,
      },
    );
  }
}
