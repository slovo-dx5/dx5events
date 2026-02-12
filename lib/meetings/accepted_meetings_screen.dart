import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:provider/provider.dart';

import '../../../providers.dart';
import '../constants.dart';
import '../widgets/accepted_meeting_widget.dart';
import '../widgets/accepted_meeting_widget_isSender.dart';


class AcceptedMeetingsScreen extends StatefulWidget {
  @override
  _AcceptedMeetingsScreenState createState() => _AcceptedMeetingsScreenState();
}

class _AcceptedMeetingsScreenState extends State<AcceptedMeetingsScreen> {
  @override
  void initState() {
    super.initState();
  }

  Widget _buildEmptyStateMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                var docList = snapshot.data!.docs;
                if (docList.isEmpty) {
                  return _buildEmptyStateMessage("Your confirmed meetings will appear here");
                }

                // Create a list to hold meetings that match our conditions
                List<Widget> meetingWidgets = [];
                DateTime now = DateTime.now();
                print("Current time: $now");

                for (int index = 0; index < docList.length; index++) {
                  DocumentSnapshot items = docList[index];
                  DateTime meetingDate = items["date_requested"].toDate();
                  // Check if meeting is still valid (not expired)
                  // Looking at your original code, I think the intention was to check
                  // if the meeting date + 24 hours is before the current time
                  DateTime meetingDateTime = items["date_requested"].toDate();
                  bool isMeetingExpired = meetingDateTime.add(Duration(hours: 24)).isBefore(now);

                  print("Meeting date: $meetingDateTime, Expired? $isMeetingExpired");

                  // Check if this meeting should be displayed based on conditions
                  if (items["isAccepted"] == true &&
                      items["isDeleted"] == false
                      && !isMeetingExpired
                  ) {

                    if (items["requested_by_id"] != profileProvider.userID.toString()) {
                      meetingWidgets.add(
                          AcceptedMeetingWidget(
                            startTime: items["startTime"],
                            cancelMeetingFunc: () async {
                              await items.reference.delete();
                              await usersRef.doc(items["requested_by_id"]).collection("meetings").doc(items["id"]).delete();
                              await usersRef.doc(items["wants_to_meet_with_id"]).collection("meetings").doc(items["id"]).delete();
                              Fluttertoast.showToast(msg: "Meeting Deleted");
                            },
                            message: items["message"],
                            requesterName: items["requested_by"],
                          )
                      );
                    } else if (items["requested_by_id"] == profileProvider.userID.toString()) {
                      meetingWidgets.add(
                          AcceptedMeetingIsSenderWidget(
                            startTime: items["startTime"],
                            cancelMeetingFunc: () async {
                              await items.reference.delete();
                              await usersRef.doc(items["requested_by_id"]).collection("meetings").doc(items["id"]).delete();
                              await usersRef.doc(items["wants_to_meet_with_id"]).collection("meetings").doc(items["id"]).delete();
                              Fluttertoast.showToast(msg: "Meeting Deleted");
                            },
                            message: items["message"],
                            requestedFromName: items["wants_to_meet_with"],
                          )
                      );
                    }
                  }
                }

                // If no meetings meet our conditions, show empty state
                if (meetingWidgets.isEmpty) {
                  return _buildEmptyStateMessage("Accepted meetings will appear here");
                }

                // Display the list of meetings
                return ListView.builder(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(10.0),
                  itemCount: meetingWidgets.length,
                  itemBuilder: (context, index) {
                    return Column(
                      children: [meetingWidgets[index]],
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