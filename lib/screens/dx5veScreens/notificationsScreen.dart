import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dx5veevents/constants.dart';
import 'package:dx5veevents/meetings/meeting_tabs.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NotificationItem {
  final String id;
  final String title;
  final String subtitle;
  final DateTime time;
  final IconData icon;
  final Color iconColor;
  final bool isMeeting;
  final bool isRead;

  const _NotificationItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.isMeeting,
    this.isRead = false,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String? userID;
  List<_NotificationItem> _broadcastItems = [];
  Set<String> _readIds = {};
  Set<String> _deletedMeetingIds = {};

  @override
  void initState() {
    super.initState();
    _loadUserAndBroadcasts();
  }

  Future<void> _loadUserAndBroadcasts() async {
    final id = await getIntPref(kUserID);
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('notifications') ?? [];
    final readList = prefs.getStringList('notification_read_ids') ?? [];
    final deletedList = prefs.getStringList('deleted_meeting_notification_ids') ?? [];

    final readIds = readList.toSet();

    final broadcasts = stored
        .map((entry) {
          final colonIdx = entry.lastIndexOf(':');
          if (colonIdx == -1) return null;
          final tsStr = entry.substring(colonIdx + 1).trim();
          final ts = DateTime.tryParse(tsStr);
          if (ts == null) return null;
          final rest = entry.substring(0, colonIdx);
          final sepIdx = rest.indexOf(':');
          if (sepIdx == -1) return null;
          final title = rest.substring(0, sepIdx);
          final subtitle = rest.substring(sepIdx + 1);
          final notifId = 'broadcast_$entry';
          return _NotificationItem(
            id: notifId,
            title: title,
            subtitle: subtitle,
            time: ts,
            icon: Icons.campaign,
            iconColor: Colors.deepPurple,
            isMeeting: false,
            isRead: readIds.contains(notifId),
          );
        })
        .whereType<_NotificationItem>()
        .toList();

    if (mounted) {
      setState(() {
        userID = id.toString();
        _broadcastItems = broadcasts;
        _readIds = readIds;
        _deletedMeetingIds = deletedList.toSet();
      });
    }
  }

  Future<void> _markAsRead(String id) async {
    if (_readIds.contains(id)) return;
    final prefs = await SharedPreferences.getInstance();
    setState(() => _readIds.add(id));
    await prefs.setStringList('notification_read_ids', _readIds.toList());
  }

  Future<void> _markAllAsRead(List<_NotificationItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (final item in items) {
        _readIds.add(item.id);
      }
    });
    await prefs.setStringList('notification_read_ids', _readIds.toList());
  }

  Future<void> _deleteBroadcastNotification(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('notifications') ?? [];
    // id is 'broadcast_<raw_entry>' — strip prefix to recover the raw entry
    final rawEntry = id.substring('broadcast_'.length);
    final updated = stored.where((e) => e != rawEntry).toList();
    await prefs.setStringList('notifications', updated);
    _readIds.remove(id);
    await prefs.setStringList('notification_read_ids', _readIds.toList());
    await _loadUserAndBroadcasts();
  }

  Future<void> _deleteMeetingNotification(String id) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _deletedMeetingIds.add(id));
    await prefs.setStringList(
        'deleted_meeting_notification_ids', _deletedMeetingIds.toList());
    _readIds.remove(id);
    await prefs.setStringList('notification_read_ids', _readIds.toList());
  }

  void _showDeleteDialog(BuildContext context, _NotificationItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete notification"),
        content: const Text("Remove this notification?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (item.isMeeting) {
                _deleteMeetingNotification(item.id);
              } else {
                _deleteBroadcastNotification(item.id);
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _goToMeetings(BuildContext context) {
    PersistentNavBarNavigator.pushNewScreen(
      context,
      screen: MeetingTabs(),
      withNavBar: false,
      pageTransitionAnimation: PageTransitionAnimation.slideRight,
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    String day = dateTime.day.toString();
    String suffix = "th";
    if (day.endsWith("1") && day != "11") suffix = "st";
    if (day.endsWith("2") && day != "12") suffix = "nd";
    if (day.endsWith("3") && day != "13") suffix = "rd";

    const List<String> months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    final month = months[dateTime.month - 1];
    final hour = dateTime.hour > 12
        ? (dateTime.hour - 12).toString()
        : dateTime.hour.toString();
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? "pm" : "am";

    return "$day$suffix $month\n$hour:$minute$period";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          if (userID != null)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userID)
                  .collection('meetings')
                  .snapshots(),
              builder: (context, snapshot) {
                final allItems = _buildAllItems(snapshot);
                final hasUnread = allItems.any((item) => !item.isRead);
                if (!hasUnread) return const SizedBox.shrink();
                return TextButton(
                  onPressed: () => _markAllAsRead(allItems),
                  child: const Text(
                    "Mark all read",
                    style: TextStyle(color: kConnectedBlue, fontSize: 13),
                  ),
                );
              },
            ),
        ],
      ),
      body: userID == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userID)
                  .collection('meetings')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Something went wrong"));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allItems = _buildAllItems(snapshot);

                if (allItems.isEmpty) {
                  return const Center(
                    child: Text(
                      "No notifications yet",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: allItems.length,
                  itemBuilder: (context, index) {
                    final item = allItems[index];
                    return GestureDetector(
                      onLongPress: () => _showDeleteDialog(context, item),
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 4),
                        color: item.isRead
                            ? Colors.grey[100]
                            : Colors.white,
                        elevation: item.isRead ? 0.5 : 2,
                        child: ListTile(
                          leading: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    item.iconColor.withOpacity(0.15),
                                child:
                                    Icon(item.icon, color: item.iconColor),
                              ),
                              if (!item.isRead)
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: kConnectedBlue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: item.isRead
                                  ? FontWeight.w400
                                  : FontWeight.w700,
                              fontSize: 13.5,
                              color: item.isRead
                                  ? Colors.grey[600]
                                  : Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            item.subtitle,
                            style: TextStyle(
                              color: item.isRead
                                  ? Colors.grey[500]
                                  : Colors.black87,
                            ),
                          ),
                          trailing: Text(
                            _formatTimestamp(item.time),
                            style: TextStyle(
                              fontSize: 11,
                              color: item.isRead
                                  ? Colors.grey[400]
                                  : Colors.grey[700],
                            ),
                            textAlign: TextAlign.right,
                          ),
                          onTap: () {
                            _markAsRead(item.id);
                            if (item.isMeeting) _goToMeetings(context);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  List<_NotificationItem> _buildAllItems(
      AsyncSnapshot<QuerySnapshot> snapshot) {
    final now = DateTime.now();

    List<_NotificationItem> meetingItems = [];
    if (snapshot.hasData) {
      meetingItems = snapshot.data!.docs
          .where((doc) {
            final notifId = 'meeting_${doc.id}';
            if (_deletedMeetingIds.contains(notifId)) return false;
            final requestedById = doc['requested_by_id'] as String?;
            final isAccepted = doc['isAccepted'] as bool? ?? false;
            final isDeleted = doc['isDeleted'] as bool? ?? false;
            final isCancelled = doc['isCancelled'] as bool? ?? false;
            final isDeclined = doc['isDeclined'] as bool? ?? false;
            final dateRequested =
                (doc['date_requested'] as Timestamp).toDate();
            final isExpired = dateRequested
                .add(const Duration(hours: 24))
                .isBefore(now);

            if (isDeleted || isCancelled) return false;
            final isIncoming = requestedById != userID;
            if (isIncoming && !isAccepted && !isDeclined && !isExpired) {
              return true;
            }
            if (!isIncoming && isAccepted) return true;
            return false;
          })
          .map((doc) {
            final notifId = 'meeting_${doc.id}';
            final requestedById = doc['requested_by_id'] as String?;
            final isIncoming = requestedById != userID;
            final isAccepted = doc['isAccepted'] as bool? ?? false;
            final dateRequested =
                (doc['date_requested'] as Timestamp).toDate();

            if (isIncoming && !isAccepted) {
              return _NotificationItem(
                id: notifId,
                title: "Meeting Request",
                subtitle: "${doc['requested_by']} wants to meet with you",
                time: dateRequested,
                icon: Icons.person_add,
                iconColor: Colors.green,
                isMeeting: true,
                isRead: _readIds.contains(notifId),
              );
            } else {
              return _NotificationItem(
                id: notifId,
                title: "Meeting Accepted",
                subtitle:
                    "${doc['wants_to_meet_with']} accepted your meeting request",
                time: dateRequested,
                icon: Icons.check_circle,
                iconColor: Colors.blue,
                isMeeting: true,
                isRead: _readIds.contains(notifId),
              );
            }
          })
          .toList();
    }

    final broadcastsWithReadState = _broadcastItems
        .map((item) => _NotificationItem(
              id: item.id,
              title: item.title,
              subtitle: item.subtitle,
              time: item.time,
              icon: item.icon,
              iconColor: item.iconColor,
              isMeeting: item.isMeeting,
              isRead: _readIds.contains(item.id),
            ))
        .toList();

    return [...meetingItems, ...broadcastsWithReadState]
      ..sort((a, b) => b.time.compareTo(a.time));
  }
}
