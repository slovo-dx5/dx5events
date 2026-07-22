import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../providers.dart';
import '../constants.dart';
import '../services/meeting_reminders.dart';

/// Upcoming accepted meetings, each of which reminds the user 15 minutes
/// before it starts.
///
/// This screen doubles as the scheduling driver for the *current* device:
/// walking the accepted, still-upcoming meetings and (re)scheduling a local
/// reminder for each. Because both participants land here on their own device,
/// this is how both parties end up reminded — not just whoever tapped Accept.
/// Scheduling is idempotent (keyed by meeting id), and an in-memory guard keeps
/// stream rebuilds from re-issuing the same schedule call.
class MeetingRemindersScreen extends StatefulWidget {
  const MeetingRemindersScreen({super.key});

  @override
  State<MeetingRemindersScreen> createState() => _MeetingRemindersScreenState();
}

class _MeetingRemindersScreenState extends State<MeetingRemindersScreen> {
  final Set<String> _scheduled = {};

  Widget _empty(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_active_outlined,
                size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final currentUserId = profileProvider.userID.toString();

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .collection('meetings')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: SpinKitCircle(color: kCIOPink));
          }

          final now = DateTime.now();
          final upcoming = <_Reminder>[];

          for (final doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) continue;
            if (data['isAccepted'] != true) continue;
            if (data['isDeleted'] == true || data['isCancelled'] == true) {
              continue;
            }
            final ts = data['meeting_time'];
            if (ts is! Timestamp) continue; // legacy meeting, no structured time
            final meetingTime = ts.toDate();
            if (!meetingTime.isAfter(now)) continue; // already started/past

            final withName = data['requested_by_id'].toString() == currentUserId
                ? (data['wants_to_meet_with']?.toString() ?? 'your contact')
                : (data['requested_by']?.toString() ?? 'your contact');

            upcoming.add(_Reminder(
              id: doc.id,
              withName: withName,
              time: meetingTime,
            ));
          }

          upcoming.sort((a, b) => a.time.compareTo(b.time));
          _ensureScheduled(upcoming);

          if (upcoming.isEmpty) {
            return _empty(
                "No upcoming meetings to remind you about yet.\nAccepted meetings appear here.");
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: upcoming.length,
            itemBuilder: (context, i) => _reminderCard(upcoming[i]),
          );
        },
      ),
    );
  }

  /// Schedules any newly-seen reminders after the current frame, so we never
  /// kick off async plugin work during build.
  void _ensureScheduled(List<_Reminder> reminders) {
    final fresh = reminders.where((r) => !_scheduled.contains(r.id)).toList();
    if (fresh.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      for (final r in fresh) {
        if (_scheduled.contains(r.id)) continue;
        _scheduled.add(r.id);
        await MeetingReminderService.instance.scheduleForMeeting(
          meetingId: r.id,
          withName: r.withName,
          meetingTime: r.time,
        );
      }
    });
  }

  Widget _reminderCard(_Reminder r) {
    final when = DateFormat('EEE, MMM d • h:mm a').format(r.time);
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: kConnectedBlue.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.event_available, color: kConnectedBlue),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Meeting with ${r.withName}",
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 15, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(when,
                          style: const TextStyle(color: Color(0xFF666666))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "We'll remind you 15 minutes before it starts.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Reminder {
  const _Reminder({
    required this.id,
    required this.withName,
    required this.time,
  });

  final String id;
  final String withName;
  final DateTime time;
}
