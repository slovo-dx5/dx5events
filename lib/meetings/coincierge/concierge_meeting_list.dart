import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dx5veevents/backendOps/sendBroadcast.dart';
import 'package:dx5veevents/constants.dart';
import 'package:dx5veevents/dioServices/dioPostService.dart';
import 'package:dx5veevents/helpers/helper_functions.dart';
import 'package:dx5veevents/services/activity_logger.dart';

/// Concierge desk list of delegate meetings, shared by both the "Confirmed" and
/// "Pending" tabs — [confirmed] selects which.
///
/// Replaces the near-identical `concierge_accepted.dart` /
/// `concierge_pending.dart`. Improvements over those:
///  * "handled" status is shared across every admin device via the
///    `meeting_concierge_status` collection (was per-device SharedPreferences);
///  * a search box and soonest-first sort by the real `meeting_time`;
///  * a contact/remind sheet that can push a reminder to the attendee's device
///    (reusing the FCM v1 pipeline) as well as prefilled WhatsApp/SMS.
class ConciergeMeetingList extends StatefulWidget {
  const ConciergeMeetingList({
    super.key,
    required this.confirmed,
    required this.adminName,
  });

  /// true → accepted meetings ("Confirmed" tab); false → pending requests.
  final bool confirmed;

  /// Who is working the desk, recorded on the shared status doc + audit log.
  final String adminName;

  @override
  State<ConciergeMeetingList> createState() => _ConciergeMeetingListState();
}

class _ConciergeMeetingListState extends State<ConciergeMeetingList> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  static const String _statusCollection = 'meeting_concierge_status';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// The moment the meeting actually happens. Prefer the structured
  /// `meeting_time`; fall back to `date_requested` on legacy docs that predate
  /// it.
  DateTime _meetingTime(Map<String, dynamic> data) {
    final mt = data['meeting_time'];
    if (mt is Timestamp) return mt.toDate();
    return (data['date_requested'] as Timestamp).toDate();
  }

  bool _matchesQuery(Map<String, dynamic> data) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    bool has(String key) =>
        (data[key]?.toString().toLowerCase() ?? '').contains(q);
    return has('requested_by') ||
        has('wants_to_meet_with') ||
        has('message') ||
        has('company');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search by delegate, company or topic',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            // Outer stream: the shared handled-status collection. Inner stream:
            // every meeting (collection group). Merging them here is what lets
            // all concierge admins see the same Done/Pending state live.
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(_statusCollection)
                  .snapshots(),
              builder: (context, statusSnap) {
                final handled = <String, bool>{};
                final handledBy = <String, String>{};
                if (statusSnap.hasData) {
                  for (final doc in statusSnap.data!.docs) {
                    final d = doc.data() as Map<String, dynamic>?;
                    if (d == null) continue;
                    handled[doc.id] = d['handled'] == true;
                    handledBy[doc.id] = d['handledBy']?.toString() ?? '';
                  }
                }
                return _buildMeetingStream(handled, handledBy);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingStream(
    Map<String, bool> handled,
    Map<String, String> handledBy,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collectionGroup('meetings').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: SpinKitCircle(color: kCIOPink));
        }

        final now = DateTime.now();
        final nowDateOnly = DateTime(now.year, now.month, now.day);
        final seen = <String>{};
        final meetings = <_Meeting>[];

        for (final doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) continue;
          final id = data['id']?.toString();
          if (id == null || seen.contains(id)) continue;
          seen.add(id);

          // Right tab?
          if ((data['isAccepted'] == true) != widget.confirmed) continue;

          // Drop meetings from a previous day.
          final requested = (data['date_requested'] as Timestamp).toDate();
          final reqDateOnly =
              DateTime(requested.year, requested.month, requested.day);
          if (reqDateOnly.isBefore(nowDateOnly)) continue;

          if (!_matchesQuery(data)) continue;

          meetings.add(_Meeting(
            id: id,
            data: data,
            time: _meetingTime(data),
          ));
        }

        meetings.sort((a, b) => a.time.compareTo(b.time));

        if (meetings.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Text(
                _query.isNotEmpty
                    ? 'No meetings match "$_query".'
                    : widget.confirmed
                        ? 'Accepted meetings will appear here'
                        : 'Pending meeting requests will appear here',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: meetings.length,
          itemBuilder: (context, i) {
            final m = meetings[i];
            return _meetingCard(
              m,
              handled[m.id] ?? false,
              handledBy[m.id] ?? '',
            );
          },
        );
      },
    );
  }

  Widget _meetingCard(_Meeting m, bool isDone, String doneBy) {
    final data = m.data;
    final when = DateFormat('MMM d, yyyy - h:mm a').format(m.time);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      elevation: 2,
      color: isDone ? Colors.grey[100] : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['message']?.toString() ?? 'Meeting',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                decoration: isDone ? TextDecoration.lineThrough : null,
                color: isDone ? Colors.grey : null,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 16, color: isDone ? Colors.grey : kConnectedBlue),
                const SizedBox(width: 4),
                Text(when,
                    style: TextStyle(
                        color: isDone ? Colors.grey : kConnectedBlue)),
                if (isDone) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      doneBy.isEmpty ? 'Done' : 'Done · $doneBy',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _party('From:', data['requested_by']?.toString() ?? '', isDone),
                _party('To:', data['wants_to_meet_with']?.toString() ?? '',
                    isDone),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.person_outline, size: 16),
                  label: const Text('Contact Sender'),
                  onPressed: () => _openContactSheet(
                    name: data['requested_by']?.toString() ?? 'Sender',
                    phone: data['requested_by_phone']?.toString() ?? '',
                    partyId: data['requested_by_id']?.toString() ?? '',
                    meetingId: m.id,
                    meetingTime: m.time,
                    topic: data['message']?.toString() ?? '',
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.person, size: 16, color: kConnectedBlue),
                  label: const Text('Contact Recipient',
                      style: TextStyle(color: kConnectedBlue)),
                  onPressed: () => _openContactSheet(
                    name: data['wants_to_meet_with']?.toString() ?? 'Recipient',
                    phone: data['wants_to_meet_with_phone']?.toString() ?? '',
                    partyId: data['wants_to_meet_with_id']?.toString() ?? '',
                    meetingId: m.id,
                    meetingTime: m.time,
                    topic: data['message']?.toString() ?? '',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(isDone ? Icons.undo : Icons.check, size: 16),
                label: Text(isDone ? 'Mark as Pending' : 'Mark as Done'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDone ? Colors.orange : Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _setHandled(m.id, !isDone),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _party(String label, String value, bool isDone) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: TextStyle(color: isDone ? Colors.grey : null)),
      ],
    );
  }

  /// Writes the shared handled state so every admin device sees it.
  Future<void> _setHandled(String meetingId, bool handled) async {
    try {
      await FirebaseFirestore.instance
          .collection(_statusCollection)
          .doc(meetingId)
          .set({
        'handled': handled,
        'handledBy': widget.adminName,
        'handledAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      ActivityLogger.instance.log(
        action: ActivityAction.conciergeMeetingHandled,
        targetType: 'meeting',
        targetId: meetingId,
        metadata: {'handled': handled, 'by': widget.adminName},
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Could not update status');
    }
  }

  void _openContactSheet({
    required String name,
    required String phone,
    required String partyId,
    required String meetingId,
    required DateTime meetingTime,
    required String topic,
  }) {
    final when = DateFormat('EEE MMM d, h:mm a').format(meetingTime);
    final reminder = topic.isEmpty
        ? "Hi $name, a reminder about your CIO Africa meeting on $when."
        : "Hi $name, a reminder about your CIO Africa meeting \"$topic\" on $when.";

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Contact $name',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(when, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.phone, color: kConnectedGreen),
                  title: const Text('Call'),
                  subtitle: Text(phone.isEmpty ? 'No number on file' : phone),
                  enabled: phone.isNotEmpty,
                  onTap: phone.isEmpty
                      ? null
                      : () async {
                          Navigator.pop(sheetContext);
                          await _launch(Uri.parse('tel:$phone'));
                        },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: SizedBox(
                    height: 26,
                    width: 26,
                    child: Image.asset('assets/icons/whatsapp.png'),
                  ),
                  title: const Text('WhatsApp (prefilled)'),
                  enabled: phone.isNotEmpty,
                  onTap: phone.isEmpty
                      ? null
                      : () async {
                          Navigator.pop(sheetContext);
                          await openWhatsapp(
                            contactNumber: phone,
                            context: context,
                            message: reminder,
                          );
                        },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.sms_outlined, color: kConnectedBlue),
                  title: const Text('SMS (prefilled)'),
                  enabled: phone.isNotEmpty,
                  onTap: phone.isEmpty
                      ? null
                      : () async {
                          Navigator.pop(sheetContext);
                          await _launch(Uri.parse(
                              'sms:$phone?body=${Uri.encodeComponent(reminder)}'));
                        },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.notifications_active,
                      color: kConnectedRed),
                  title: const Text('Send push reminder'),
                  subtitle: const Text('Notifies them in the app'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _sendPushReminder(
                      partyId: partyId,
                      name: name,
                      body: reminder,
                      meetingId: meetingId,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _launch(Uri uri) async {
    try {
      if (!await launchUrl(uri)) {
        Fluttertoast.showToast(msg: 'Could not open ${uri.scheme}');
      }
    } catch (_) {
      Fluttertoast.showToast(msg: 'Could not open ${uri.scheme}');
    }
  }

  /// Pushes a reminder to the attendee's device, reusing the broadcast FCM v1
  /// pipeline — the only difference from a broadcast is targeting a single
  /// device token instead of a topic.
  Future<void> _sendPushReminder({
    required String partyId,
    required String name,
    required String body,
    required String meetingId,
  }) async {
    if (partyId.isEmpty) {
      Fluttertoast.showToast(msg: 'No account linked to $name');
      return;
    }
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(partyId)
          .get();
      final token = userDoc.data()?['messaging_token']?.toString() ?? '';
      if (token.isEmpty) {
        Fluttertoast.showToast(msg: '$name has no device registered for push');
        return;
      }

      final accessToken = await getAccessToken();
      await DioPostService().sendBroadcast(
        accessToken: accessToken,
        body: {
          'message': {
            'token': token,
            'notification': {
              'title': 'Meeting reminder',
              'body': body,
            },
            'data': {
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'targetPage': 'meetings',
            },
          },
        },
      );
      Fluttertoast.showToast(msg: 'Reminder sent to $name');
      ActivityLogger.instance.log(
        action: ActivityAction.conciergeReminderSent,
        targetType: 'meeting',
        targetId: meetingId,
        metadata: {'to': name, 'channel': 'push', 'by': widget.adminName},
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Could not send reminder');
    }
  }
}

class _Meeting {
  const _Meeting({required this.id, required this.data, required this.time});

  final String id;
  final Map<String, dynamic> data;
  final DateTime time;
}
