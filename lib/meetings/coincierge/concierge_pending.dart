import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../providers.dart';
import '../../constants.dart';
import '../../helpers/helper_functions.dart';
import '../../widgets/meeting_widget.dart';
import '../../widgets/outgoing_meeting_widget.dart';

class ConciergePendingMeetings extends StatefulWidget {
  @override
  _ConciergePendingMeetingsState createState() =>
      _ConciergePendingMeetingsState();
}

class _ConciergePendingMeetingsState extends State<ConciergePendingMeetings> {
  // Track done status for multiple items
  Map<String, bool> doneStatusMap = {};

  @override
  void initState() {
    super.initState();
  }

  void _contactPerson(BuildContext context, String name, String phone) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Contact $name',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.phone),
                title: Text(phone),
                onTap: () async {
                  String phoneNumber = phone;
                  final uri = Uri.parse("tel:$phoneNumber");
                  await launchUrl(uri);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Calling $phone')),
                  );
                },
              ),
              GestureDetector(
                onTap: () async {
                  await openWhatsapp(contactNumber: phone, context: context);
                },
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        height: 35,
                        width: 35,
                        child: Image.asset("assets/icons/whatsapp.png"),
                      ),
                    ),
                    horizontalSpace(width: 20),
                    Text(
                      "Whatsapp",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadDoneStatus(String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'done_$itemId';
    final status = prefs.getBool(key) ?? false;
    setState(() {
      doneStatusMap[itemId] = status;
    });
  }

  Future<void> _saveDoneStatus(String itemId, bool status) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'done_$itemId';
    await prefs.setBool(key, status);
    setState(() {
      doneStatusMap[itemId] = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);

    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collectionGroup("meetings")
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                var docList = snapshot.data!.docs;
                Set<String> seenIds = {};
                List<DocumentSnapshot> uniqueMeetings = [];

                for (var doc in docList) {
                  final meetingId = doc['id'];
                  if (!seenIds.contains(meetingId)) {
                    seenIds.add(meetingId);
                    uniqueMeetings.add(doc);
                  }
                }

                print("items length is ${uniqueMeetings.length}");

                if (uniqueMeetings.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 35, horizontal: 25),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              "Pending meeting requests will appear here",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // Filter pending meetings that are not expired
                List<DocumentSnapshot> pendingMeetings = uniqueMeetings.where((items) {
                  DateTime now = DateTime.now();
                  DateTime meetingDateTime = items["date_requested"].toDate();

                  // Get date only (without time) for comparison
                  DateTime nowDateOnly = DateTime(now.year, now.month, now.day);
                  DateTime meetingDateOnly = DateTime(meetingDateTime.year, meetingDateTime.month, meetingDateTime.day);

                  // Meeting is expired only if it's from a previous day
                  bool isMeetingExpired = meetingDateOnly.isBefore(nowDateOnly);

                  // Only show meetings that are not accepted AND not expired
                  return items["isAccepted"] == false && !isMeetingExpired;
                }).toList();

                if (pendingMeetings.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 25),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "No pending meetings at the moment",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(10.0),
                  itemCount: pendingMeetings.length,
                  itemBuilder: (context, index) {
                    final items = pendingMeetings[index];
                    final itemId = items['id']; // Use the meeting ID as unique identifier
                    final formatter = DateFormat('MMM d, yyyy - h:mm a');
                    DateTime dateReq = items["date_requested"].toDate();
                    final formattedTime = formatter.format(dateReq);

                    // Load done status for this item if not loaded yet
                    if (!doneStatusMap.containsKey(itemId)) {
                      _loadDoneStatus(itemId);
                    }

                    final isDone = doneStatusMap[itemId] ?? false;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      elevation: 2,
                      color: isDone ? Colors.grey[100] : null,
                      child: InkWell(
                        onTap: () {},
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          items["message"],
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            decoration: isDone
                                                ? TextDecoration.lineThrough
                                                : null,
                                            color: isDone ? Colors.grey : null,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              size: 16,
                                              color: isDone
                                                  ? Colors.grey
                                                  : kConnectedBlue,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              formattedTime,
                                              style: TextStyle(
                                                color: isDone
                                                    ? Colors.grey
                                                    : kConnectedBlue,
                                              ),
                                            ),
                                            if (isDone) ...[
                                              const SizedBox(width: 8),
                                              const Icon(
                                                Icons.check_circle,
                                                size: 16,
                                                color: Colors.green,
                                              ),
                                              const SizedBox(width: 4),
                                              const Text(
                                                'Done',
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'From:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        items["requested_by"],
                                        style: TextStyle(
                                          color: isDone ? Colors.grey : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'To:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        items["wants_to_meet_with"],
                                        style: TextStyle(
                                          color: isDone ? Colors.grey : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(Icons.person_outline,
                                        size: 16),
                                    label: const Text('Contact Sender'),
                                    onPressed: isDone
                                        ? null
                                        : () => _contactPerson(
                                      context,
                                      items["requested_by"],
                                      items["requested_by_phone"],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    icon: const Icon(
                                      Icons.person,
                                      size: 16,
                                      color: kConnectedBlue,
                                    ),
                                    label: const Text(
                                      'Contact Recipient',
                                      style: TextStyle(color: kConnectedBlue),
                                    ),
                                    onPressed: isDone
                                        ? null
                                        : () => _contactPerson(
                                      context,
                                      items["wants_to_meet_with"],
                                      items["wants_to_meet_with_phone"],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: Icon(
                                    isDone ? Icons.undo : Icons.check,
                                    size: 16,
                                  ),
                                  label: Text(isDone
                                      ? 'Mark as Pending'
                                      : 'Mark as Done'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    isDone ? Colors.orange : Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () {
                                    _saveDoneStatus(itemId, !isDone);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
              return const Center(
                child: SpinKitCircle(
                  color: kConnectedBlue,
                ),
              );
            }),
      ),
    );
  }
}