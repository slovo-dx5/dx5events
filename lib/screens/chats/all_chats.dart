
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:intl/intl.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../../helpers/helper_functions.dart';
import '../../providers.dart';
import 'chat_screen.dart';

class AllChatsScreen extends StatefulWidget {
  @override
  _AllChatsScreenState createState() => _AllChatsScreenState();
}

class _AllChatsScreenState extends State<AllChatsScreen> {
  @override
  void initState() {
    super.initState();
    // DioPostService().sendNotification({"to": "e8NhL6HyQNmDDX9YAclCJ2:APA91bFhQsz3JKLz0TaKqxylewxrdYNNXjD4uHCkXR8rZtPSxPEXckblmfjrLpkMicm-y8hIlYVeTk6N4InWaXvWHyY8ZfL-Xta7dNxKq3cn4A3DAdybDrNeVDaVA-m6reFSGDA6Bt9Y",
    //   "notification":{
    //     "title": "Sample title",
    //     "body": "Sample body"
    //   }
    // });
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);

    return SafeArea(
      child: Scaffold(

        body: Container(
          height: MediaQuery.of(context).size.height,
          child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(profileProvider.userID.toString())
                  .collection("contacts")
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
                                "Your Chats will appear here",
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
                  return Container(
                    height: MediaQuery.of(context).size.height,
                    child: ListView.builder(
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(10.0),
                      itemCount: docList.length,
                      itemBuilder: (context, index) {
                        DocumentSnapshot items = snapshot.data!.docs[index];

                        myChatTitle() {
                          String getInitials(String name) {
                            List<String> nameSplit = name.split(" ");
                            String firstNameInitial = nameSplit[0][0];
                            return firstNameInitial;
                          }

                          if (profileProvider.userID.toString() ==
                              items["contact_id"]) {


                            return Row(
                              children: [
                                chatInitials(name: items["Sent_From"]),

                                horizontalSpace(width: 15),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      items["Sent_From"],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    ),
                                    verticalSpace(height: 10),
                                    StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('messages')
                                            .doc(items["chatID"])
                                            .collection(items["chatID"])
                                            // .where('idTo',
                                            //  isEqualTo: items["contact_id"])
                                            //.where('isread', isEqualTo: false)
                                            .snapshots(),
                                        builder:
                                            (context, notReadMSGSnapshot) {
                                          return Container(width: MediaQuery.of(context).size.width*0.5,
                                            child: Text(
                                                notReadMSGSnapshot
                                                    .data!.docs.last['content'],
                                                overflow:
                                                    TextOverflow.ellipsis,
                                            maxLines: 1,
                                            ),
                                          );
                                        }),
                                  ],
                                ),
                                Spacer(),
                                Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(0, 8, 4, 4),
                                    child: StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('notifications')
                                            .doc(
                                                profileProvider.userID.toString())
                                            .collection(
                                                profileProvider.userID.toString())
                                            .where('isread', isEqualTo: false)
                                            .snapshots(),
                                        builder: (context, notReadCounter) {
                                          return Column(children: <Widget>[
                                            StreamBuilder<QuerySnapshot>(
                                                stream: FirebaseFirestore.instance
                                                    .collection('messages')
                                                    .doc(items["chatID"])
                                                    .collection(items["chatID"])
                                                    .snapshots(),
                                                builder: (context, timeSnapshot) {
                                                  DateTime myDateTime =
                                                      (timeSnapshot.data!.docs
                                                              .last['timestamp'])
                                                          .toDate();
                                                  var messageTime = DateFormat()
                                                      .add_E().add_jm()
                                                      .format(myDateTime);
                                                  return Text(
                                                    messageTime,
                                                    style: const TextStyle(
                                                        fontSize: 12),
                                                  );
                                                }),
                                            Padding(
                                              padding: const EdgeInsets.fromLTRB(
                                                  0, 15, 0, 0),
                                              child: notReadCounter
                                                      .data!.docs.isNotEmpty
                                                  ? Text(
                                                      " ${notReadCounter.data!.docs.length}",
                                                      style: const TextStyle(
                                                          fontSize: 10,
                                                          color: Colors.red),
                                                    )
                                                  : const Text(""),
                                            )
                                          ]);
                                        })),
                              ],
                            );
                          } else if (profileProvider.userID.toString() !=
                              items["sender_id"]) {
                            return Row(
                              children: [
                                Container(
                                  //margin: EdgeInsets.only(16),
                                  height: 60,
                                  width: 60,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(100),
                                      color: Color(0xff272c35)),
                                  child: Stack(children: <Widget>[
                                    Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        getInitials(items["Sent_To"]),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xff0077d7),
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                  ]),
                                ),
                                horizontalSpace(width: 15),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      items["Sent_To"],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    ),
                                    verticalSpace(height: 10),
                                    StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('messages')
                                            .doc(items["chatID"])
                                            .collection(items["chatID"])
                                        // .where('idTo',
                                        //  isEqualTo: items["contact_id"])
                                        //.where('isread', isEqualTo: false)
                                            .snapshots(),
                                        builder:
                                            (context, notReadMSGSnapshot) {
                                          return Text(
                                              notReadMSGSnapshot
                                                  .data!.docs.last['content'],
                                              overflow:
                                              TextOverflow.ellipsis);
                                        }),
                                  ],
                                ),
                                Spacer(),
                                Padding(
                                    padding:
                                    const EdgeInsets.fromLTRB(0, 8, 4, 4),
                                    child: StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('notifications')
                                            .doc(
                                            profileProvider.userID.toString())
                                            .collection(
                                            profileProvider.userID.toString())
                                            .where('isread', isEqualTo: false)
                                            .snapshots(),
                                        builder: (context, notReadCounter) {
                                          return Column(children: <Widget>[
                                            StreamBuilder<QuerySnapshot>(
                                                stream: FirebaseFirestore.instance
                                                    .collection('messages')
                                                    .doc(items["chatID"])
                                                    .collection(items["chatID"])
                                                    .snapshots(),
                                                builder: (context, timeSnapshot) {
                                                  DateTime myDateTime =
                                                  (timeSnapshot.data!.docs
                                                      .last['timestamp'])
                                                      .toDate();
                                                  var messageTime = DateFormat()
                                                      .add_jm()
                                                      .format(myDateTime);
                                                  return Text(
                                                    messageTime,
                                                    style: const TextStyle(
                                                        fontSize: 12),
                                                  );
                                                }),
                                            Padding(
                                              padding: const EdgeInsets.fromLTRB(
                                                  0, 15, 0, 0),
                                              child: notReadCounter
                                                  .data!.docs.isNotEmpty
                                                  ? Text(
                                                " ${notReadCounter.data!.docs.length}",
                                                style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.red),
                                              )
                                                  : const Text(""),
                                            )
                                          ]);
                                        })),
                              ],
                            );
                          }
                        }

                        return GestureDetector(
                          onTap: () async {
                            CollectionReference ref = FirebaseFirestore.instance
                                .collection('notifications')
                                .doc(profileProvider.userID.toString())
                                .collection(profileProvider.userID.toString());

                            QuerySnapshot eventsQuery =
                                await ref.where('isread', isEqualTo: false).get();

                            eventsQuery.docs.forEach((msgDoc) {
                              msgDoc.reference.update({'isread': true});
                            });
                            if (mounted) {
                              PersistentNavBarNavigator.pushNewScreen(
                                context,
                                screen: CioChatScreen(
                                  chattingWithName: items["Sent_From"],
                                  chattingWithID: int.parse(items["sender_id"]),
                                  currentUserID: profileProvider.userID!,
                                  currentUserName: profileProvider.firstName,
                                ),
                                withNavBar: false,
                                pageTransitionAnimation:
                                    PageTransitionAnimation.slideRight,
                              );
                            }
                          },
                          child: Column(
                            children: [
                              myChatTitle()!,
                              const Divider(
                                color: Color(0xff0077d7),
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  );
                }
                return const Center(
                  child: SpinKitCircle(
                    color: kCIOPink,
                  ),
                );
              }),
        ),
      ),
    );
  }
}
