import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../helpers/helper_functions.dart';

import '../models/agendaModel.dart';
import '../models/sessionModel.dart';
import '../models/speakersModel.dart';
import '../providers.dart';
import '../providers/themeProvider.dart';
import '../screens/dx5veScreens/eventFullAgenda.dart';
class SessionWidget extends StatefulWidget {
  String sessionTitle;
  String startTime;
  String endTime;
  String description;
  String sessionType;
  String eventDate;
  String eventLocation;
  int sessionId;
  int date;
  var futures;
  var speakers;int eventDay;
  int eventMonth;
  int eventYear;
  // List <Speaker>speakersCollection;
   List <SessionModel>sessions;



  SessionWidget({super.key, required this.speakers,

  //  required this.speakersCollection,
    required this.sessionType,required this.sessions, required this.eventDay,required this.eventDate,
    required this.eventMonth,
    required this.eventYear,required this.date,required this.eventLocation,this.futures,required this.sessionId,required this.sessionTitle,
    required this.startTime, required this.endTime, required this.description});

  @override
  State<SessionWidget> createState() => _SessionWidgetState();
}

class _SessionWidgetState extends State<SessionWidget> {



  Random random = Random();


  @override
  void initState() {
    // TODO: implement initState
    super.initState();

  }
  bool isDeleting=false;
  bool isDeleted=false;
  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);

    return  Padding(
      padding: const EdgeInsets.only(left: 8.0,right: 8.0,top: 4,bottom: 4),
      child: GestureDetector(onTap: (){
        // PersistentNavBarNavigator.pushNewScreen(
        //   context,
        //   screen: FullAgendaScreen(
        //     title: widget.sessionTitle,
        //     day: 20,
        //     startTime: widget.startTime,
        //     endTime: widget.endTime,
        //     isFromSession: false,
        //     type:widget.sessionType,
        //     userID: profileProvider.userID!,
        //     description: "Cybersecurity threats are constantly changing – think of new viruses, more advanced hacking techniques, and unexpected targets. There is a need for individuals and organisations to stay informed about these shifts in the threat landscape.The goal is to continuously adapt security strategies to maintain protection in this ever-evolving digital world.",
        //     speakers: false, eventLocation: widget.eventLocation, eventDay: widget.eventDay, eventMonth: widget.eventMonth, eventYear: widget.eventYear, futures: widget.futures, date: widget.eventDate,
        //   ),
        //   withNavBar: false,
        //   pageTransitionAnimation: PageTransitionAnimation.slideRight,
        // );
      },
        child: Visibility(visible: !isDeleted,
          child:widget.speakers!=[]?

          Column(
            children: [
              Container(
                height: 180,
                color: kRightBubble.withOpacity(0.5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          height: 180,
                          color: kRightBubble,
                          child: Column(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Text(convertToAmPm(widget.startTime),
                                  style: kGreyTextStyle(fontsiZe: 12)),
                              verticalSpace(height: 10),
                              Text(convertToAmPm(widget.endTime),
                                  style: kGreyTextStyle(fontsiZe: 12)),
                            ],
                          ),
                        ),
                        horizontalSpace(width: 15),
                        Expanded(
                          child: Column(
                            mainAxisAlignment:
                            MainAxisAlignment.start,
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              verticalSpace(height: 10),
                              Text(
                                "${widget.sessionTitle}",
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700),
                              ),
                              verticalSpace(height: 10),


                            ],
                          ),
                        ),

                        Padding(
                          padding:  EdgeInsets.fromLTRB(10,70,5,70),
                          child: GestureDetector(
                              onTap:()async{


                                setState(() {
                                  isDeleting = true;
                                });

                                await  deleteSession(sessionID: widget.sessionId);
                                widget.sessions.removeWhere((event) => event.id == widget.sessionId);
                                setState(() {
                                  isDeleted=true;

                                  isDeleting = false;
                                });
                              },
                              child: const Icon(Icons.delete,color: kIconDeepBlue,)),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              verticalSpace(height: 10)
            ],
          ):
          Column(
            children: [
              Container(
                height: 100,
                color: kRightBubble.withOpacity(0.5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          height: 100,
                          color: kRightBubble,
                          child: Column(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Text(convertToAmPm(widget.startTime),
                                  style: kGreyTextStyle(fontsiZe: 12)),
                              verticalSpace(height: 10),
                              Text(convertToAmPm(widget.endTime),
                                  style: kGreyTextStyle(fontsiZe: 12)),
                            ],
                          ),
                        ),
                        horizontalSpace(width: 15),
                        Expanded(
                          child: Column(
                            mainAxisAlignment:
                            MainAxisAlignment.start,
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              verticalSpace(height: 10),
                              Text(
                                "${widget.sessionTitle}",
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700),
                              ),
                              verticalSpace(height: 10),


                            ],
                          ),
                        ),

                        Padding(
                          padding:  EdgeInsets.fromLTRB(10,30,5,30),
                          child: GestureDetector(onTap:()async{

                            setState(() {
                              isDeleted=true;

                              isDeleting = true;
                            });

                            await  deleteSession(sessionID: widget.sessionId);
                            widget.sessions.removeWhere((event) => event.id == widget.sessionId);
                            setState(() {
                              isDeleting = false;
                            });
                          } ,child: const Icon(Icons.delete,color: kIconDeepBlue,)),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              verticalSpace(height: 10)
            ],
          ),







        ),
      ),
    );
  }
}


class SessionItemWithSpeakers extends StatefulWidget {

  String eventLocation;
      int eventYear;
  int eventMonth;
      int eventDay;
  String title;
      String eventDayOfWeek;
  String startTime;
      DateTime sessionDate;
  int sessionID;
  var futures;
      String endTime;
  String sessionType;
      String summary;
  List <BreakoutSession>?breakoutSessions;List speakers;
      VoidCallback onPressedFunction;
  int userID;


   SessionItemWithSpeakers({super.key, required this.speakers,

    //  required this.speakersCollection,
    required this.eventLocation, required this.eventDayOfWeek, required this.eventYear, required this.eventMonth, required this.eventDay, required this.title
   , required this.startTime, required this.sessionID, required this.sessionDate, required this.futures, required this.summary, this.breakoutSessions, required this.onPressedFunction,
     required this.userID, required this.endTime, required this.sessionType});

  @override
  State<SessionItemWithSpeakers> createState() => _SessionItemWithSpeakersState();
}

class _SessionItemWithSpeakersState extends State<SessionItemWithSpeakers> {
  bool isDeleting=false;
  bool isDeleted=false;

  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context); 
    return Column(
      children: [
        GestureDetector( onTap:(){
          PersistentNavBarNavigator.pushNewScreen(
            context,
            screen: FullAgendaScreen(
              title: widget.title,
              day: widget.eventDay,
              startTime: widget.startTime,
              endTime: widget.endTime,
              isFromSession: true,
              type:widget.sessionType,
              userID: widget.userID,
              description: widget.summary,
              speakers: widget.speakers,
              breakOuts: widget.breakoutSessions, eventLocation: widget.eventLocation,
              eventDay: widget.eventDay, eventMonth: widget.eventMonth, eventYear: widget.eventYear, futures: widget.futures,
              date: widget.eventDayOfWeek, sessionId: widget.sessionID, sessionDate: widget.sessionDate,
            ),
            withNavBar: false,
            pageTransitionAnimation: PageTransitionAnimation.slideRight,
          );
        },
          child: Visibility(visible: !isDeleted,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(padding: const EdgeInsets.only(top: 20,bottom: 20),
                height: widget.speakers.length>=2?280:190,decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),color: themeProvider.themeMode==ThemeModeOptions.dark?kGreyAgenda:kGradientLighterBlue.withOpacity(0.4),),

                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(convertToAmPm(widget.startTime),
                          ),horizontalSpace(width: 5),const Text("-"),
                          horizontalSpace(width: 5),
                          Text(convertToAmPm(widget.endTime),
                          ),

                          const Spacer(),


                          // Padding(
                          //   padding:  const EdgeInsets.only(right:10,),
                          //   child: GestureDetector(
                          //
                          //       onTap:()async{
                          //
                          //
                          //         setState(() {
                          //           isDeleting = true;
                          //         });
                          //
                          //         await  deleteSession(sessionID: widget.sessionID);
                          //         //widget.sessionID.removeWhere((event) => event.id == widget.sessionId);
                          //         setState(() {
                          //           isDeleted=true;
                          //
                          //           isDeleting = false;
                          //         });
                          //       }
                          //       ,child: const Icon(Icons.delete,color: kIconDeepBlue,)),
                          // )
                        ],
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment:
                          MainAxisAlignment.start,
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            verticalSpace(height: 10),
                            Text(
                              widget.title,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700),
                            ),
                            verticalSpace(height: 10),
                            FutureBuilder<
                                List<IndividualSpeaker?>>(
                              future: Future.wait(widget.futures),
                              builder: (context, snapshot) {
                                // print("snapshot is ${snapshot.data!.first!.firstName!}");
                                if (snapshot.connectionState ==
                                    ConnectionState.done &&
                                    snapshot.data != null) {
                                  // Join the first names of all speakers
                                  final speakerWidgets =
                                  snapshot.data!
                                      .where((speaker) =>
                                  speaker != null)
                                      .map((speaker) => Padding(
                                    padding: const EdgeInsets.only(top:8.0,bottom: 8.0),
                                    child: Row(
                                      children: [
                                        CachedNetworkImage(
                                          fit:
                                          BoxFit.cover,
                                          imageUrl:
                                          "https://subscriptions.cioafrica.co/assets/${speaker!.photo}",
                                          // placeholder: (context, url) => CircularProgressIndicator(), // Optional
                                          // errorWidget: (context, url, error) =>  ProfileInitials(),
                                          progressIndicatorBuilder: (context, url, downloadProgress) => SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(value: downloadProgress.progress)), // Optional
                                          imageBuilder: (context, imageProvider) =>
                                              CircleAvatar(
                                                radius: 15,
                                                backgroundImage: imageProvider,
                                              ),
                                        ),horizontalSpace(width: 10),

                                        Expanded(
                                          child: Column(mainAxisAlignment: MainAxisAlignment.start,crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${speaker.firstName} ${speaker.lastName}',style:kGreyTextStyle(fontsiZe: 12) ,),
                                              Text(
                                                '${speaker.role} at ${speaker.company}',style: kNameTextStyle( fontsiZe: 10),overflow: TextOverflow.ellipsis,maxLines: 2,),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )

                                  )
                                      .toList();
                                  print("speker widgets are ${speakerWidgets.length}");
                                  return Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      ...speakerWidgets,
                                    ],
                                  );
                                } else if (snapshot
                                    .connectionState ==
                                    ConnectionState.waiting) {
                                  return const Text(
                                      'Loading speakers...');
                                } else {
                                  return const Text(
                                      'Speakers details not available');
                                }
                              },
                            ),

                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        verticalSpace(height: 10)
      ],
    );
  }
}


class SessionItemWithoutSpeakers extends StatefulWidget {
  String eventLocation;
  int eventYear;
  int eventMonth;
  int eventDay;
  String title;
  String eventDayOfWeek;
  String startTime;
  DateTime sessionDate;
  int sessionID;

  String endTime;
  String sessionType;
  String summary;
  List <BreakoutSession>?breakoutSessions;
  VoidCallback onPressedFunction;
  int userID;


  SessionItemWithoutSpeakers({super.key,

    //  required this.speakersCollection,
    required this.eventLocation, required this.eventDayOfWeek, required this.eventYear, required this.eventMonth, required this.eventDay, required this.title
    , required this.startTime, required this.sessionID, required this.sessionDate,  required this.summary, this.breakoutSessions, required this.onPressedFunction,
    required this.userID, required this.endTime, required this.sessionType});

  @override
  State<SessionItemWithoutSpeakers> createState() => _SessionItemWithoutSpeakersState();
}

class _SessionItemWithoutSpeakersState extends State<SessionItemWithoutSpeakers> {
  bool isDeleting=false;
  bool isDeleted=false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Column(
      children: [
        GestureDetector( onTap:(){
          PersistentNavBarNavigator.pushNewScreen(
            context,
            screen: FullAgendaScreen(
              title: widget.title,
              day: widget.eventDay,
              startTime: widget.startTime,
              endTime: widget.endTime,
              isFromSession: true,
              type:widget.sessionType,
              userID: widget.userID,
              description: widget.summary,
              speakers:false,
              breakOuts: widget.breakoutSessions, eventLocation: widget.eventLocation,
              eventDay: widget.eventDay, eventMonth: widget.eventMonth, eventYear: widget.eventYear, futures: null,
              date: widget.eventDayOfWeek, sessionId: widget.sessionID, sessionDate: widget.sessionDate,
            ),
            withNavBar: false,
            pageTransitionAnimation: PageTransitionAnimation.slideRight,
          );
        },
          child: Visibility(visible: !isDeleted,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(padding: const EdgeInsets.only(top: 20,bottom: 20),
                height:100,decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),color: themeProvider.themeMode==ThemeModeOptions.dark?kGreyAgenda:kGradientLighterBlue.withOpacity(0.4),),

                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(convertToAmPm(widget.startTime),
                          ),horizontalSpace(width: 5),const Text("-"),
                          horizontalSpace(width: 5),
                          Text(convertToAmPm(widget.endTime),
                          ),

                          const Spacer(),


                          // Padding(
                          //   padding:  const EdgeInsets.only(right:10,),
                          //   child: GestureDetector(
                          //
                          //       onTap:()async{
                          //
                          //
                          //         setState(() {
                          //           isDeleting = true;
                          //         });
                          //
                          //         await  deleteSession(sessionID: widget.sessionID);
                          //         //widget.sessionID.removeWhere((event) => event.id == widget.sessionId);
                          //         setState(() {
                          //           isDeleted=true;
                          //
                          //           isDeleting = false;
                          //         });
                          //       }
                          //       ,child: const Icon(Icons.delete,color: kIconDeepBlue,)),
                          // )
                        ],
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment:
                          MainAxisAlignment.start,
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            verticalSpace(height: 10),
                            Text(
                              widget.title,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700),
                            ),
                            verticalSpace(height: 10),


                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        verticalSpace(height: 10)
      ],
    );
  }
}











