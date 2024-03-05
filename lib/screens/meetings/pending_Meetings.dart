
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:intl/intl.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'package:provider/provider.dart';

import '../../../providers.dart';
import '../../constants.dart';
import '../../widgets/meeting_widget.dart';
import '../../widgets/outgoing_meeting_widget.dart';
import '../chats/chat_screen.dart';

class PendingMeetingsScreen extends StatefulWidget {
  @override
  _PendingMeetingsScreenState createState() => _PendingMeetingsScreenState();
}

class _PendingMeetingsScreenState extends State<PendingMeetingsScreen> {
  bool isAccepting=false;
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
                              false && items["requested_by_id"] !=
                              profileProvider.userID.toString())

                            IncomingMeetingWidget(startTime: items["startTime"],
                            acceptMeetingFunc: () async{
                                setState(() {
                                  isAccepting=true;
                                });
                              await items.reference
                                  .update(<String, dynamic>{
                                'isAccepted': true,
                              });
                                print("other id is ${items["requested_by_id"]}" );
                              await usersRef.doc(items["requested_by_id"]).collection("meetings").doc(items["id"]).set({
                                "id": items["id"],

                                "requested_by": items["requested_by"], ///The person requesting the meeting
                                "requested_by_id": items["requested_by_id"], ///The person requesting the meeting
                                "wants_to_meet_with": items["wants_to_meet_with"],
                                "wants_to_meet_with_id": items["wants_to_meet_with_id"],
                                "isAccepted": true,
                                "isDeleted": false,
                                "isCancelled": false,
                                "isDeclined": false,
                                "isDefault": false,
                                "date_requested": Timestamp.now(),
                                "message": items["message"],
                                "startTime":  items["startTime"],


                                "company": items["company"],

                              });
                                setState(() {
                                  isAccepting=false;
                                });
                            },
                            declineMeetingFunc: ()async {
                              await items.reference
                                  .delete();
                              await usersRef.doc(items["requested_by_id"]).collection("meetings").doc(items["id"]).delete();
                              await usersRef.doc(items["wants_to_meet_with_id"]).collection("meetings").doc(items["id"]).delete();
                              Fluttertoast.showToast(msg: "Meeting Declined");

                                },  message: items["message"],
                            requesterName: items["requested_by"], isAccepting: isAccepting,),
                          if ( items["isAccepted"] ==
                              false && items["requested_by_id"] ==
                              profileProvider.userID.toString())

                            OutgoingMeetingWidget(startTime: items["startTime"],
                              acceptMeetingFunc: () async{
                                setState(() {
                                  isAccepting=true;
                                });
                                await items.reference
                                    .update(<String, dynamic>{
                                  'isAccepted': true,
                                });
                                print("other id is ${items["requested_by_id"]}" );
                                await usersRef.doc(items["requested_by_id"]).collection("meetings").doc(items["id"]).set({
                                  "id": items["id"],

                                  "requested_by": items["requested_by"], ///The person requesting the meeting
                                  "requested_by_id": items["requested_by_id"], ///The person requesting the meeting
                                  "wants_to_meet_with": items["wants_to_meet_with"],
                                  "wants_to_meet_with_id": items["wants_to_meet_with_id"],
                                  "isAccepted": true,
                                  "isDeleted": false,
                                  "isCancelled": false,
                                  "isDeclined": false,
                                  "isDefault": false,
                                  "date_requested": Timestamp.now(),
                                  "message": items["message"],
                                  "startTime":  items["startTime"],


                                  "company": items["company"],

                                });
                                setState(() {
                                  isAccepting=false;
                                });
                              },
                              declineMeetingFunc: ()async {
                                await items.reference
                                    .delete();
                                await usersRef.doc(items["requested_by_id"]).collection("meetings").doc(items["id"]).delete();
                                await usersRef.doc(items["wants_to_meet_with_id"]).collection("meetings").doc(items["id"]).delete();
                                Fluttertoast.showToast(msg: "Meeting Declined");

                              },  message: items["message"],
                              wantsToMeetWithName: items["wants_to_meet_with"], isAccepting: isAccepting,),


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
