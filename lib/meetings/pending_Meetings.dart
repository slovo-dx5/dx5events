import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:intl/intl.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:provider/provider.dart';

import '../../../providers.dart';
import '../../widgets/meeting_widget.dart';
import '../../widgets/outgoing_meeting_widget.dart';
import '../constants.dart';
import '../dioServices/dioPostService.dart';
import '../helpers/analytics_helper.dart';
import '../services/activity_logger.dart';
import '../services/meeting_reminders.dart';

class PendingMeetingsScreen extends StatefulWidget {
  @override
  _PendingMeetingsScreenState createState() => _PendingMeetingsScreenState();
}

class _PendingMeetingsScreenState extends State<PendingMeetingsScreen> {
  bool isAccepting = false;
  @override
  void initState() {
    super.initState();
  }
  //
  // updateMeetings() async {
  //   try {
  //     await hiringsnapshots.forEach(
  //             (hiringsnapshot) async {
  //           List<DocumentSnapshot>
  //           hiringdocuments =
  //               hiringsnapshot.docs;
  //
  //           for (var hiringdocument
  //           in hiringdocuments) {
  //             await hiringdocument.reference
  //                 .update(<String, dynamic>{
  //               'isPro': false,
  //             });
  //           }
  //         });
  //   } catch (e) {
  //
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);

    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(profileProvider.userID.toString())
                .collection("meetings")
                //.orderBy('timeStamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                var docList = snapshot.data!.docs;
                if (docList.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Container(
                        //color: UniversalVariables.separatorColor,
                        padding: const EdgeInsets.symmetric(
                            vertical: 35, horizontal: 25),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              "Your meeting requests will appear here",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                // fontSize: 30,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                // Filter pending (and non-expired) meetings
                List<DocumentSnapshot> pendingMeetings = docList.where((items) {
                  DateTime now = DateTime.now();
                  DateTime meetingDateTime = items["date_requested"].toDate();
                  bool isMeetingExpired = meetingDateTime
                      .add(const Duration(hours: 24))
                      .isBefore(now);
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
                    DateTime now = DateTime.now();
                    DateTime meetingDateTime = items["date_requested"].toDate();
                    bool isMeetingExpired = meetingDateTime
                        .add(const Duration(hours: 24))
                        .isBefore(now);

                    return Column(
                      children: [
                        if (items["requested_by_id"] !=
                            profileProvider.userID.toString())
                          IncomingMeetingWidget(
                            // your props here
                            startTime: items["startTime"],
                            acceptMeetingFunc: () async {
                              await Dx5veAnalytics().logdx5veEvent(eventName: "meetingAccepted");
                              ActivityLogger.instance.log(
                                action: ActivityAction.meetingAccepted,
                                userId: profileProvider.userID,
                                targetType: 'meeting',
                                targetId: items["id"]?.toString(),
                                metadata: {
                                  'requested_by_id': items["requested_by_id"],
                                },
                              );

                              DateFormat format = DateFormat("h:mm a");
                              DateTime parsedStart = format.parse(items["startTime"]);

                              // Add 30 minutes to get end time
                              DateTime endTime = parsedStart.add(Duration(minutes: 30));
                              String formattedEndTime = format.format(endTime);

                              // Structured meeting moment (may be absent on
                              // legacy requests made before day-selection).
                              final itemData =
                                  items.data() as Map<String, dynamic>?;
                              final Timestamp? meetingTs = itemData != null &&
                                      itemData.containsKey('meeting_time')
                                  ? itemData['meeting_time'] as Timestamp?
                                  : null;

                              setState(() {
                                isAccepting = true;
                              });
                              await items.reference.update(<String, dynamic>{
                                'isAccepted': true,
                              });

                              // Schedule this device's (the accepter's) 15-min
                              // reminder. The requester's device schedules its
                              // own from the Reminders tab.
                              if (meetingTs != null) {
                                await MeetingReminderService.instance
                                    .scheduleForMeeting(
                                  meetingId: items["id"].toString(),
                                  withName: items["requested_by"].toString(),
                                  meetingTime: meetingTs.toDate(),
                                );
                              }

                              print("other id is ${items["requested_by_id"]}");
                              await usersRef
                                  .doc(items["requested_by_id"])
                                  .collection("meetings")
                                  .doc(items["id"])
                                  .set({
                                "id": items["id"],

                                "requested_by": items["requested_by"],

                                ///The person requesting the meeting
                                "requested_by_id": items["requested_by_id"],

                                ///The person requesting the meeting
                                "wants_to_meet_with":
                                    items["wants_to_meet_with"],
                                "wants_to_meet_with_id":
                                    items["wants_to_meet_with_id"],
                                "isAccepted": true,
                                "isDeleted": false,
                                "isCancelled": false,
                                "isDeclined": false,
                                "isDefault": false,
                                "date_requested": Timestamp.now(),
                                "message": items["message"],
                                "startTime": items["startTime"],
                                // Preserve the meeting moment so the requester's
                                // device can schedule its own reminder.
                                "meeting_time": meetingTs,

                                "company": items["company"],
                              });
                              setState(() {
                                isAccepting = false;
                              });

                              ///Send email to requester
                              await DioPostService().sendMeetingEmail(body: {
                                "emailAddress": items["requested_by_email"],
                                "subject":
                                    "Meeting Accepted",
                                "body": """
  <div style="max-width: 100%;">
    <img src="https://admin.connected.go.ke/assets/a14f7470-d026-4d56-848e-4e0d5e0ebc18?email_banner.jpg" alt="Meeting Banner" style="width: 100%; max-width: 600px; height: auto; margin-bottom: 20px;">
  </div>
  
  <p>"
      Hello ${items["requested_by"]}<br>
      ${items["wants_to_meet_with"]} accepted your meeting
      request.<br>
      Our meetings concierge service team will reach out to show you the meeting venue.
      
  
  "</p>
  <p><strong>Meeting time:</strong><br>
  Start time: ${items["startTime"]}<br>
  End time: $formattedEndTime</p>

 
""",
                              });
                            },

                            declineMeetingFunc: () async {
                              await Dx5veAnalytics().logdx5veEvent(eventName: "meetingDeclined");
                              ActivityLogger.instance.log(
                                action: ActivityAction.meetingDeclined,
                                userId: profileProvider.userID,
                                targetType: 'meeting',
                                targetId: items["id"]?.toString(),
                                metadata: {
                                  'requested_by_id': items["requested_by_id"],
                                },
                              );

                              await items.reference.delete();
                            await usersRef
                                .doc(items["requested_by_id"])
                                .collection("meetings")
                                .doc(items["id"])
                                .delete();
                            await usersRef
                                .doc(items["wants_to_meet_with_id"])
                                .collection("meetings")
                                .doc(items["id"])
                                .delete();
                            await MeetingReminderService.instance
                                .cancel(items["id"].toString());
                            Fluttertoast.showToast(msg: "Meeting Declined");},
                            message: items["message"],
                            requesterName: items["requested_by"],
                            isAccepting: isAccepting,
                          ),
                        if (items["requested_by_id"] ==
                            profileProvider.userID.toString())
                          OutgoingMeetingWidget(
                            // your props here
                            startTime: items["startTime"],

                            cancelMeetingFunc: () async {
                              ActivityLogger.instance.log(
                                action: ActivityAction.meetingCancelled,
                                userId: profileProvider.userID,
                                targetType: 'meeting',
                                targetId: items["id"]?.toString(),
                                metadata: {
                                  'wants_to_meet_with_id': items["wants_to_meet_with_id"],
                                },
                              );
                              await items.reference.delete();
                              await usersRef
                                  .doc(items["requested_by_id"])
                                  .collection("meetings")
                                  .doc(items["id"])
                                  .delete();
                              await usersRef
                                  .doc(items["wants_to_meet_with_id"])
                                  .collection("meetings")
                                  .doc(items["id"])
                                  .delete();
                              await MeetingReminderService.instance
                                  .cancel(items["id"].toString());
                              Fluttertoast.showToast(msg: "Meeting Declined");
                            },
                            message: items["message"],
                            wantsToMeetWithName: items["wants_to_meet_with"],
                            isAccepting: isAccepting,
                          ),
                      ],
                    );
                  },
                );
              }
              return const Center(
                child: SpinKitCircle(
                  color: kCIOPink,
                ),
              );
            }),
      ),
    );
  }
}
