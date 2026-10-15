import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../dioServices/base_url.dart';
import '../dioServices/dioClient.dart';
import '../models/agendaModel.dart';
import '../widgets/app_sponsor.dart';
import 'activity_logger.dart';
import 'meeting_reminders.dart';

/// One bookmarked agenda session.
///
/// Agenda sessions have no ids of their own — the agenda is a single JSON
/// repeater in Directus and `session_id` is null on every session — so a
/// session is identified by [AgendaBookmarkService.keyFor]: day, start time and
/// title. The title and start time are also stored so a bookmark can still be
/// matched after an editor fixes a typo or moves the session.
class AgendaBookmark {
  AgendaBookmark({
    required this.key,
    required this.title,
    required this.date,
    required this.startTime,
    this.rowId,
  });

  /// See [AgendaBookmarkService.keyFor].
  String key;
  String title;

  /// yyyy-MM-dd
  String date;

  /// HH:mm
  String startTime;

  /// The `user_sessions` row, once the server has it.
  int? rowId;

  Map<String, dynamic> toJson() => {
        'key': key,
        'title': title,
        'date': date,
        'start': startTime,
        'row': rowId,
      };

  factory AgendaBookmark.fromJson(Map<String, dynamic> j) => AgendaBookmark(
        key: j['key'] as String,
        title: (j['title'] ?? '') as String,
        date: (j['date'] ?? '') as String,
        startTime: (j['start'] ?? '') as String,
        rowId: j['row'] as int?,
      );

  factory AgendaBookmark.fromRow(Map<String, dynamic> r) => AgendaBookmark(
        key: (r['session_key'] ?? '') as String,
        title: (r['session_title'] ?? '') as String,
        date: (r['event_date'] ?? '').toString(),
        startTime: (r['start_time'] ?? '') as String,
        rowId: r['id'] as int?,
      );
}

/// Bookmarked ("My agenda") sessions for one attendee and event.
///
/// Stored in Directus `user_sessions` so they follow the attendee to a new
/// phone and organisers can see what's popular, and cached in
/// SharedPreferences so the agenda shows them instantly and offline. Each
/// bookmark schedules a local reminder [leadTime] before the session.
class AgendaBookmarkService extends ChangeNotifier {
  AgendaBookmarkService._();

  static final AgendaBookmarkService instance = AgendaBookmarkService._();

  static const Duration leadTime = Duration(minutes: 10);
  static const String _channelId = 'session_reminders';
  static const String _channelName = 'Session Reminders';
  static const String _channelDescription =
      'Reminds you 10 minutes before a session in My agenda';

  final DioClient _client = DioClient();

  String? _eventId;
  int? _attendeeId;
  final Map<String, AgendaBookmark> _byKey = {};
  final Set<String> _busy = {};

  int get count => _byKey.length;
  bool isBookmarked(String key) => _byKey.containsKey(key);
  bool isBusy(String key) => _busy.contains(key);

  // ── Session identity ──────────────────────────────────────────────────────

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String dateKey(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

  /// "9:5:00" / "09:05" → "09:05"; anything unparseable is returned trimmed.
  static String hhmm(dynamic time) {
    final parts = (time ?? '').toString().trim().split(':');
    if (parts.length < 2) return (time ?? '').toString().trim();
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1].replaceAll(RegExp(r'\D'), ''));
    if (h == null || m == null) return (time ?? '').toString().trim();
    return '${_two(h)}:${_two(m)}';
  }

  static String _norm(dynamic title) => (title ?? '')
      .toString()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();

  /// Stable identity for a session: `yyyy-MM-dd|HH:mm|normalised title`.
  static String keyFor(DateTime day, Session s) =>
      '${dateKey(day)}|${hhmm(s.startTime)}|${_norm(s.title)}';

  // ── Loading ───────────────────────────────────────────────────────────────

  String _prefsKey(int attendeeId, String eventId) =>
      'agenda_bookmarks_v1_${attendeeId}_$eventId';

  /// Shows the cached bookmarks immediately, then replaces them with the
  /// server's copy. A failed fetch keeps the cache.
  Future<void> load({required String eventId, required int attendeeId}) async {
    if (_eventId != eventId || _attendeeId != attendeeId) {
      _eventId = eventId;
      _attendeeId = attendeeId;
      _byKey.clear();
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey(attendeeId, eventId));
      if (raw != null) {
        _byKey
          ..clear()
          ..addEntries((jsonDecode(raw) as List)
              .map((e) => AgendaBookmark.fromJson(Map<String, dynamic>.from(e)))
              .map((b) => MapEntry(b.key, b)));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[AgendaBookmarks] cache read failed: $e');
    }

    try {
      final res = await _client.init().get(
        '${BaseURL.Baseurl}/items/user_sessions',
        queryParameters: {
          'filter[attendee_id][_eq]': attendeeId,
          'filter[event_id][_eq]': eventId,
          'fields': 'id,session_key,session_title,start_time,event_date',
          'limit': -1,
        },
      );
      if (_eventId != eventId || _attendeeId != attendeeId) return;
      final rows = (res.data['data'] as List).cast<Map<String, dynamic>>();
      _byKey
        ..clear()
        ..addEntries(rows
            .map(AgendaBookmark.fromRow)
            .where((b) => b.key.isNotEmpty)
            .map((b) => MapEntry(b.key, b)));
      await _saveCache();
      notifyListeners();
    } catch (e) {
      debugPrint('[AgendaBookmarks] fetch failed, keeping cache: $e');
    }
  }

  Future<void> _saveCache() async {
    final eventId = _eventId, attendeeId = _attendeeId;
    if (eventId == null || attendeeId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey(attendeeId, eventId),
          jsonEncode(_byKey.values.map((b) => b.toJson()).toList()));
    } catch (e) {
      debugPrint('[AgendaBookmarks] cache write failed: $e');
    }
  }

  // ── Matching bookmarks to the current agenda ──────────────────────────────

  /// Matches every bookmark to a session in [days] and (re)schedules its
  /// reminder from the session's current time.
  ///
  /// A bookmark whose key no longer exists — the title was edited or the
  /// session moved — is re-matched on the same day by title, then by start
  /// time when exactly one session starts then, and re-keyed on the server.
  /// One that matches nothing stays stored (the session may come back) but
  /// loses its reminder.
  Future<void> reconcile(List<AgendaDay> days) async {
    final sessions = <String, (DateTime, Session)>{};
    for (final day in days) {
      final date = day.date as DateTime;
      for (final s in day.sessions) {
        sessions[keyFor(date, s)] = (date, s);
      }
    }

    var changed = false;
    for (final b in _byKey.values.toList()) {
      var match = sessions[b.key];
      if (match == null) {
        final sameDay = sessions.entries
            .where((e) => e.key.startsWith('${b.date}|'))
            .toList();
        final byTitle =
            sameDay.where((e) => e.key.endsWith('|${_norm(b.title)}')).toList();
        final byStart =
            sameDay.where((e) => e.key.contains('|${b.startTime}|')).toList();
        final found = byTitle.length == 1
            ? byTitle.first
            : (byStart.length == 1 ? byStart.first : null);
        if (found != null) {
          await _cancelReminder(b.key);
          _rekey(b, found.key, found.value.$2);
          changed = true;
          match = found.value;
        }
      }
      if (match == null) {
        await _cancelReminder(b.key);
      } else {
        await _scheduleReminder(b.key, match.$1, match.$2);
      }
    }
    if (changed) {
      await _saveCache();
      notifyListeners();
    }
  }

  void _rekey(AgendaBookmark b, String newKey, Session s) {
    _byKey.remove(b.key);
    b
      ..key = newKey
      ..title = (s.title ?? '').toString()
      ..startTime = hhmm(s.startTime);
    _byKey[newKey] = b;
    final rowId = b.rowId;
    if (rowId == null) return;
    _client
        .init()
        .patch('${BaseURL.Baseurl}/items/user_sessions/$rowId', data: {
      'session_key': b.key,
      'session_title': b.title,
      'start_time': b.startTime,
    }).catchError((e) {
      debugPrint('[AgendaBookmarks] re-key upload failed: $e');
      return e;
    });
  }

  // ── Toggling ──────────────────────────────────────────────────────────────

  /// Adds or removes [session] from My agenda. Optimistic: the UI flips at
  /// once and flips back if the server refuses. Returns the new state, or null
  /// when the change failed.
  Future<bool?> toggle({required DateTime day, required Session session}) async {
    final eventId = _eventId, attendeeId = _attendeeId;
    if (eventId == null || attendeeId == null) return null;
    final key = keyFor(day, session);
    if (_busy.contains(key)) return isBookmarked(key);

    _busy.add(key);
    final existing = _byKey[key];
    try {
      if (existing == null) {
        final b = AgendaBookmark(
          key: key,
          title: (session.title ?? '').toString(),
          date: dateKey(day),
          startTime: hhmm(session.startTime),
        );
        _byKey[key] = b;
        notifyListeners();
        try {
          final res = await _client
              .init()
              .post('${BaseURL.Baseurl}/items/user_sessions', data: {
            'attendee_id': attendeeId,
            'event_id': eventId,
            'event_date': b.date,
            'session_key': b.key,
            'session_title': b.title,
            'start_time': b.startTime,
          });
          b.rowId = res.data['data']['id'] as int?;
        } catch (e) {
          debugPrint('[AgendaBookmarks] add failed: $e');
          _byKey.remove(key);
          notifyListeners();
          return null;
        }
        await _saveCache();
        await _scheduleReminder(key, day, session);
        // Bookmark-then-unbookmark re-logs with the same target, which the
        // distinct rules ignore, so toggling can't farm points.
        ActivityLogger.instance.log(
          action: ActivityAction.agendaBookmarkAdded,
          eventId: eventId,
          userId: attendeeId,
          targetType: 'session',
          targetId: key,
          metadata: {'date': b.date},
        );
        return true;
      }

      _byKey.remove(key);
      notifyListeners();
      try {
        final rowId = existing.rowId;
        if (rowId != null) {
          await _client
              .init()
              .delete('${BaseURL.Baseurl}/items/user_sessions/$rowId');
        }
      } catch (e) {
        debugPrint('[AgendaBookmarks] remove failed: $e');
        _byKey[key] = existing;
        notifyListeners();
        return null;
      }
      await _saveCache();
      await _cancelReminder(key);
      return false;
    } finally {
      _busy.remove(key);
      notifyListeners();
    }
  }

  // ── Reminders ─────────────────────────────────────────────────────────────

  /// FNV-1a, 31-bit: a notification id that is stable across app launches
  /// (String.hashCode is not guaranteed to be) and namespaced away from the
  /// meeting reminders.
  int _notificationId(String key) {
    var h = 0x811c9dc5;
    for (final c in utf8.encode('session|$_eventId|$key')) {
      h = ((h ^ c) * 0x01000193) & 0xffffffff;
    }
    return h & 0x7fffffff;
  }

  /// Session times are the venue's local time; like the meeting reminders, this
  /// assumes the phone is set to the event's timezone.
  DateTime? _startOf(DateTime day, Session s) {
    final parts = hhmm(s.startTime).split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]), m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return DateTime(day.year, day.month, day.day, h, m);
  }

  Future<void> _scheduleReminder(String key, DateTime day, Session s) async {
    final FlutterLocalNotificationsPlugin? plugin =
        MeetingReminderService.instance.plugin;
    final start = _startOf(day, s);
    if (plugin == null || start == null) return;
    final remindAt = start.subtract(leadTime);
    if (!remindAt.isAfter(DateTime.now())) return;

    final stage = (s.stage ?? '').toString().trim();
    try {
      await plugin.zonedSchedule(
        _notificationId(key),
        'Starting in 10 minutes',
        '${s.title ?? 'Your session'}${stage.isEmpty ? '' : ' · $stage'}'
        '${AppSponsor.reminderCredit}',
        tz.TZDateTime.from(remindAt, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('[AgendaBookmarks] reminder not scheduled: $e');
    }
  }

  Future<void> _cancelReminder(String key) async {
    try {
      await MeetingReminderService.instance.plugin?.cancel(_notificationId(key));
    } catch (_) {}
  }
}
