
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
                              "Your confirmed meetings will appear here",
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
                return ListView.builder(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(10.0),
                  itemCount: docList.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot items = snapshot.data!.docs[index];



                    return GestureDetector(
                      onTap: () async {
                        // CollectionReference ref = FirebaseFirestore.instance
                        //     .collection('notifications')
                        //     .doc(profileProvider.userID.toString())
                        //     .collection(profileProvider.userID.toString());
                        //
                        // QuerySnapshot eventsQuery =
                        // await ref.where('isread', isEqualTo: false).get();
                        //
                        // eventsQuery.docs.forEach((msgDoc) {
                        //   msgDoc.reference.update({'isread': true});
                        // });
                        // if (mounted) {
                        //   PersistentNavBarNavigator.pushNewScreen(
                        //     context,
                        //     screen: CioChatScreen(
                        //       chattingWithName: items["Sent_From"],
                        //       chattingWithID: int.parse(items["sender_id"]),
                        //       currentUserID: profileProvider.userID!,
                        //       currentUserName: profileProvider.firstName,
                        //     ),
                        //     withNavBar: false,
                        //     pageTransitionAnimation:
                        //     PageTransitionAnimation.slideRight,
                        //   );
                        // }
                      },
                      child: Column(
                        children: [
                          if ( items["isAccepted"] ==
                              true && items["isDeleted"] ==
                              false && items["requested_by_id"] !=
                              profileProvider.userID.toString() )
                            AcceptedMeetingWidget(startTime: items["startTime"],
                            cancelMeetingFunc: () async{
                              await items.reference
                                  .delete();
                              await usersRef.doc(items["requested_by_id"]).collection("meetings").doc(items["id"]).delete();
                              await usersRef.doc(items["wants_to_meet_with_id"]).collection("meetings").doc(items["id"]).delete();
                              Fluttertoast.showToast(msg: "Meeting Deleted");
                            },
                            message: items["message"],
                            requesterName: items["requested_by"],),

                          if ( items["isAccepted"] ==
                              true && items["isDeleted"] ==
                              false && items["requested_by_id"] ==
                              profileProvider.userID.toString())
                            AcceptedMeetingIsSenderWidget(startTime: items["startTime"],
                            cancelMeetingFunc: () async{
                              await items.reference
                                  .delete();
                              await usersRef.doc(items["requested_by_id"]).collection("meetings").doc(items["id"]).delete();
                              await usersRef.doc(items["wants_to_meet_with_id"]).collection("meetings").doc(items["id"]).delete();
                              Fluttertoast.showToast(msg: "Meeting Deleted");
                            },
                            message: items["message"],
                            requestedFromName: items["wants_to_meet_with"],),

                        ],
                      ),
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
