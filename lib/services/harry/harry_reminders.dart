import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Schedules local reminder notifications for Harry (e.g. "remind me about the
/// keynote at 9am"). This is the first use of scheduled (as opposed to
/// immediate) local notifications in the app — the channel and `tz` database
/// are initialised in `main()`.
class HarryReminders {
  HarryReminders(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const String channelId = 'harry_reminders';
  static const String channelName = 'Harry Reminders';

  /// Schedules a one-off reminder. Returns a user-facing confirmation string.
  /// Throws if [when] is not in the future.
  Future<String> schedule({required String title, required DateTime when}) async {
    final now = DateTime.now();
    if (!when.isAfter(now)) {
      throw ArgumentError('Reminder time must be in the future.');
    }

    final scheduled = tz.TZDateTime.from(when, tz.local);
    final id = when.millisecondsSinceEpoch.remainder(1 << 31);

    await _plugin.zonedSchedule(
      id,
      'Reminder from Harry',
      title,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Reminders you asked Harry to set',
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

    return 'Reminder set for ${_pretty(when)}: "$title".';
  }

  String _pretty(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = t.hour < 12 ? 'AM' : 'PM';
    return '${t.day}/${t.month} $h:$m $ampm';
  }
}
