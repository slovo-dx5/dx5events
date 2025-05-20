import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:intl/intl.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
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
                onTap: ()async {
                  String phoneNumber = phone;
                  final uri = Uri.parse("tel:$phoneNumber");

                  await launchUrl(uri);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Calling $phone')),
                  );
                },
              ),
              GestureDetector(onTap: ()async{
                await openWhatsapp(contactNumber: phone, context: context);
              },
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        height: 35,
                        width: 35,
                        child:
                        Image.asset("assets/icons/whatsapp.png"),
                      ),
                    ), horizontalSpace(width: 20),Text("Whatsapp",style: TextStyle(fontSize: 15,fontWeight: FontWeight.w700),)
                  ],
                ),
              ),

            ],
          ),
        );
      },
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
                .collectionGroup("meetings")
                // .orderBy('timeStamp', descending: true)
                //.orderBy('timeStamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                var docList = snapshot.data!.docs;
                Set<String> seenIds = {};
                List<DocumentSnapshot> uniqueMeetings = [];

                for (var doc in docList) {
                  final meetingId = doc['id']; // adjust this if your ID field is named differently
                  if (!seenIds.contains(meetingId)) {
                    seenIds.add(meetingId);
                    uniqueMeetings.add(doc);
                  }
                }
                print("items lenght is ${uniqueMeetings.length}");
                if (uniqueMeetings.isEmpty) {
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
                              "Pending meeting requests will appear here",
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
                List<DocumentSnapshot> pendingMeetings = uniqueMeetings.where((items) {
                  DateTime now = DateTime.now();
                  DateTime meetingDateTime = items["date_requested"].toDate();
                  bool isMeetingExpired = meetingDateTime
                      .add(const Duration(hours: 24))
                      .isBefore(now);
                  return items["isAccepted"] == false;
                  //&& !isMeetingExpired;
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
                    final formatter = DateFormat('MMM d, yyyy - h:mm a');
                    DateTime dateReq = items["date_requested"].toDate();
                    final formattedTime = formatter.format(dateReq);
                    print("items are ${items.data()}");
                    print("meeting with by ${items["wants_to_meet_with_phone"]}");

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      elevation: 2,
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
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.calendar_today,
                                              size: 16,
                                              color: kConnectedBlue,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              formattedTime,
                                              style: const TextStyle(
                                                color: kConnectedBlue,
                                              ),
                                            ),
                                            // if (isPastMeeting) ...[
                                            // const SizedBox(width: 4),
                                            // const Text(
                                            // '(Past)',
                                            // style: TextStyle(
                                            // color: Colors.red,
                                            // fontStyle: FontStyle.italic,
                                            // ),
                                            // ),
                                            // ],
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
                                      Text(items["requested_by"]),
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
                                      Text(items["wants_to_meet_with"]),
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
                                    onPressed: () => _contactPerson(
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
                                    onPressed: () => _contactPerson(
                                      context,
                                      items["wants_to_meet_with"],
                                      items["wants_to_meet_with_phone"],
                                    ),
                                  ),
                                ],
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
