import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Schedules "your meeting starts in 15 minutes" local notifications for
/// accepted meetings.
///
/// Local notifications are per-device, so each participant's own device
/// schedules its own reminder: the accepter schedules on accept, and every
/// device that observes an accepted upcoming meeting (via the Reminders tab)
/// (re)schedules it too — that's how both parties end up reminded. Scheduling
/// is keyed by a stable id derived from the meeting id, so re-scheduling the
/// same meeting simply replaces the pending notification rather than stacking.
///
/// The plugin, notification channel, and timezone database are all initialised
/// once in `main()`; [init] hands this singleton the shared plugin instance.
class MeetingReminderService {
  MeetingReminderService._();

  static final MeetingReminderService instance = MeetingReminderService._();

  static const String channelId = 'meeting_reminders';
  static const String channelName = 'Meeting Reminders';
  static const String channelDescription =
      'Reminds you 15 minutes before an accepted meeting';

  /// How long before the meeting the reminder fires.
  static const Duration leadTime = Duration(minutes: 15);

  FlutterLocalNotificationsPlugin? _plugin;

  void init(FlutterLocalNotificationsPlugin plugin) => _plugin = plugin;

  /// Stable, positive 31-bit notification id for a meeting, so scheduling is
  /// idempotent and [cancel] can target it without bookkeeping.
  int _idFor(String meetingId) => meetingId.hashCode & 0x7fffffff;

  /// Schedules (or reschedules) the 15-minute reminder for one accepted
  /// meeting. No-op when the plugin isn't ready, there's no meeting time, or
  /// the reminder moment is already in the past.
  Future<void> scheduleForMeeting({
    required String meetingId,
    required String withName,
    required DateTime meetingTime,
  }) async {
    final plugin = _plugin;
    if (plugin == null) {
      debugPrint('[MeetingReminders] plugin not initialised — skipping');
      return;
    }

    final remindAt = meetingTime.subtract(leadTime);
    if (!remindAt.isAfter(DateTime.now())) {
      // Meeting is within the lead window (or past) — nothing to schedule.
      debugPrint('[MeetingReminders] $meetingId reminder time $remindAt '
          'is not in the future — skipping');
      return;
    }

    // TZDateTime.from preserves the absolute instant, so the reminder fires at
    // the correct wall-clock time even though tz.local defaults to UTC.
    final scheduled = tz.TZDateTime.from(remindAt, tz.local);

    await plugin.zonedSchedule(
      _idFor(meetingId),
      'Upcoming meeting',
      'Your meeting with $withName starts in 15 minutes.',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
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
    debugPrint('[MeetingReminders] scheduled $meetingId for $scheduled '
        '(meeting at $meetingTime)');
  }

  /// Cancels a pending reminder — call when a meeting is cancelled/declined.
  Future<void> cancel(String meetingId) async {
    await _plugin?.cancel(_idFor(meetingId));
    debugPrint('[MeetingReminders] cancelled reminder for $meetingId');
  }
}
