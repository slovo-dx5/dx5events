import 'dart:convert';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:dx5veevents/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../dioServices/dioFetchService.dart';
import '../../helpers/helper_functions.dart';
import '../../models/agendaModel.dart';
import '../../models/speakersModel.dart';
import '../../providers.dart';
import '../../widgets/agendaWidget.dart';
import '../../widgets/appbarWidget.dart';
import 'cisoFullAgenda.dart';

class CISOAgendaScreen extends StatefulWidget {
  const CISOAgendaScreen({super.key});

  @override
  State<CISOAgendaScreen> createState() => _CISOAgendaScreenState();
}

class _CISOAgendaScreenState extends State<CISOAgendaScreen> {
  // late AgendaModel eventData;

  bool isLoading = true;
  final CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _selectedDate = DateTime(2024, 03, 20);
  final RefreshController _refreshController = RefreshController();
  DioCacheManager dioCacheManager = DioCacheManager(CacheConfig());
  List<SpeakersModel> events = [];
  List<IndividualSpeaker> speakers = [];

  List<Session> _sessions = [];
  List<AgendaDay> agendaDays = [];
  bool isBookmarking = false;
  bool isFetching=true;



  @override
  void initState() {
    // fetchCisoAgendaHere();
    _loadSessions();
    super.initState();
  }

  Future<void> _loadSessions() async {
    setState(() {
      isFetching=true;
    });
    final sessions = await fetchSessions();
    setState(() {
      _sessions = sessions;
      isFetching=false;

    });
  }

  Future<List<IndividualSpeaker>> fetchAllSpeakers(
      {required List<int> filterIds}) async {
    final response = await DioFetchService().fetchCISOSpeakers();

    if (response.statusCode == 200) {
      final speakerData = SpeakersModel.fromJson(response.data);
      final filteredIndividuals = speakerData.data
          .where((individual) => filterIds.contains(individual.id))
          .toList();
      setState(() {
        speakers =
            filteredIndividuals; // Assuming 'events' is of type List<SpeakersModel>
        log("speakers are ${speakers.first.id}");
        isLoading = false;
      });
      return speakers;
    } else {
      throw Exception('Failed to load events');
    }
  }




  Future fetchCisoAgendaHere() async {
    final response = await DioFetchService().fetchCISOAgenda();

    setState(() {
      //isFetching=false;
    });

    if (response.statusCode == 200) {
      final eventData = AgendaModel.fromJson(response.data);
      print("event data is $eventData");
      setState(() {
        _sessions = eventData.days.first.sessions;
        agendaDays = eventData.days;
        print("Attendee list length is ${eventData.days.first.date}");
        isLoading = false;
      });

      // return jsonData.map((userJson) => AttendeeModel.fromJson(userJson)).toList();
    } else {
      log(response.data);
      throw Exception('Failed to load data');
      isLoading = false;
    }
  }

  Future<List<Session>> fetchSessions() async {
    try {
      final response = await DioFetchService().fetchCISOAgenda();
      final agendaModel = AgendaModel.fromJson(response.data);
      setState(() {
        agendaDays=agendaModel.days;
      });
      return agendaModel.days.expand((day) => day.sessions).toList();
    } catch (e) {
      print(e);
      return [];
    }
  }

  Future<IndividualSpeaker?> fetchSpeakerById(int key) async {
    try {
      final response = await DioFetchService().fetchCISOSpeakers();
      final speakerssModel = SpeakersModel.fromJson(response.data);

      // Manually find the speaker to allow returning null.
      for (var speaker in speakerssModel.data) {
        if (speaker.id == key) {
          return speaker;
        }
      }
      return null; // Explicitly return null if no speaker matches the key.
    } catch (e) {
      print(e);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);

    return Scaffold(
        appBar: const PreferredSize(
          preferredSize: Size.fromHeight(75.0), // Default AppBar height
          child: AppBarWithGradient(
            title: 'AGENDA',
            gradientBegin: kCIOPurple,
            gradientEnd: kCIOPink,
          ),
        ),
        backgroundColor: kScaffoldColor,
        body: Column(
          children: [
            TableCalendar(
              weekendDays: const [
                DateTime.sunday,
                DateTime.monday,
                DateTime.tuesday,
                DateTime.friday,
                DateTime.saturday
              ],
              daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(color: kCIOPink)),
              calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kCIOPink.withOpacity(0.5),
              )),
              headerStyle: const HeaderStyle(
                  headerPadding: EdgeInsets.all(15),
                  leftChevronVisible: false,
                  rightChevronVisible: false,
                  formatButtonVisible: false,
                  titleTextStyle: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  )),
              firstDay: kCISOFirstDay,
              lastDay: kCISOLastDay,
              focusedDay: _selectedDate,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                // Using `isSameDay` is recommended to disregard

                return isSameDay(_selectedDate, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                if (selectedDay.day == 20 ||
                    selectedDay.day == 21
                    ) {
                  setState(() {
                    _selectedDate = selectedDay;
                    // DateTime dateTime = DateTime.parse(_selectedDate);
                  });
                }
              },
            ),
            const Divider(
              thickness: 2.5,
              color: kIconDeepBlue,
            ),
            Visibility(
              visible: isFetching==false,
              replacement: const CircularProgressIndicator(),
              child: Expanded(
              child: SmartRefresher(
                controller: _refreshController,
                enablePullDown: true,
                header: const WaterDropHeader(
                  waterDropColor: kCIOPink,
                ),
                onRefresh: () async {
                  await dioCacheManager.clearAll();
                  await fetchCisoAgendaHere();

                  setState(() {
                    _refreshController.refreshCompleted();
                  });
                },
                onLoading: () async {
                  await Future.delayed(Duration(milliseconds: 1000));
                  setState(() {
                    _refreshController.loadComplete();
                  });
                },

                ///Day 1
                child: _selectedDate.day==20?ListView.builder(
                  itemCount: agendaDays[0].sessions.length,
                  itemBuilder: (context, index) {
                    final firstDaySession = agendaDays[0].sessions[index];

                    // Check if there are speakers for the session
                    if (firstDaySession.speakers!.isNotEmpty) {
                      // Fetch all speakers' details
                      final futures = firstDaySession.speakers!
                          .map((speaker) =>
                          fetchSpeakerById(speaker.speaker.key))
                          .toList();

                      return Column(
                        children: [
                          GestureDetector( onTap:(){
                            PersistentNavBarNavigator.pushNewScreen(
                              context,
                              screen: FullAgendaScreen(
                                  title: firstDaySession.title,
                                  day: 20,
                                  startTime: firstDaySession.startTime,
                                  endTime: firstDaySession.endTime,
                                  isFromSession: false,
                                  type:firstDaySession.sessionType,
                                  userID: profileProvider.userID!,
                                  //   sigs:widget.sigs,
                                  description: firstDaySession.summary,
                                  //  speakersCollection: widget.speakersCollection,
                                  speakers: futures,
                                  breakOuts: firstDaySession.breakoutSessions
                              ),
                              withNavBar: false,
                              pageTransitionAnimation: PageTransitionAnimation.slideRight,
                            );
                          },
                            child: Container(padding: EdgeInsets.only(top: 20,bottom: 20),
                              height: firstDaySession.speakers!.length>=2?250:160,
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
                                        //height: 180,
                                        color: kRightBubble,
                                        child: Column(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            Text(convertToAmPm(firstDaySession.startTime),
                                                style: kGreyTextStyle(fontsiZe: 12)),
                                            verticalSpace(height: 10),
                                            Text(convertToAmPm(firstDaySession.endTime),
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
                                              "${firstDaySession.title}",
                                              style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700),
                                            ),
                                            verticalSpace(height: 10),
                                            FutureBuilder<
                                                List<IndividualSpeaker?>>(
                                              future: Future.wait(futures),
                                              builder: (context, snapshot) {
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
                                                          "https://subscriptions.cioafrica.co/assets/${speaker!.photo!}",
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
                                                                '${speaker!.firstName} ${speaker.lastName}',style:kGreyTextStyle(fontsiZe: 12) ,),
                                                              Text(
                                                                '${speaker!.role} at ${speaker.company}',style: kNameTextStyle( fontsiZe: 10),overflow: TextOverflow.ellipsis,maxLines: 2,),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ))
                                                      .toList();
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

                                      GestureDetector(
                                          onTap:()async{

                                            setState(() {
                                              isBookmarking = true;
                                            });

                                            await createSession(
                                              currentUserId: profileProvider.userID!,
                                              startTime: firstDaySession.startTime,
                                              endTime: firstDaySession.endTime,
                                              sessionTitle: firstDaySession.title,
                                              sessionDescription:firstDaySession.summary,
                                              speakers:[],
                                              sessionType: firstDaySession.sessionType,
                                              date: 20,
                                            );
                                            setState(() {
                                              isBookmarking = false;
                                            });
                                          },
                                          child: const Icon(Icons.calendar_month,color: kIconDeepBlue,))
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          verticalSpace(height: 10)
                        ],
                      );
                    } else {
                      // If there are no speakers for the session
                      return Column(
                        children: [
                          GestureDetector( onTap:(){
                            PersistentNavBarNavigator.pushNewScreen(
                              context,
                              screen: FullAgendaScreen(
                                  title: firstDaySession.title,
                                  day: 20,
                                  startTime: firstDaySession.startTime,
                                  endTime: firstDaySession.endTime,
                                  isFromSession: false,
                                  type:firstDaySession.sessionType,
                                  userID: profileProvider.userID!,
                                  //   sigs:widget.sigs,
                                  description: firstDaySession.summary,
                                  //  speakersCollection: widget.speakersCollection,
                                  speakers: false,
                                  breakOuts: firstDaySession.breakoutSessions
                              ),
                              withNavBar: false,
                              pageTransitionAnimation: PageTransitionAnimation.slideRight,
                            );
                          },
                            child: Container(
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
                                            Text(convertToAmPm(firstDaySession.startTime),
                                                style: kGreyTextStyle(fontsiZe: 12)),
                                            verticalSpace(height: 10),
                                            Text(convertToAmPm(firstDaySession.endTime),
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
                                              "${firstDaySession.title}",
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
                                            isBookmarking = true;
                                          });

                                          await createSession(
                                            currentUserId: profileProvider.userID!,
                                            startTime: firstDaySession.startTime,
                                            endTime: firstDaySession.endTime,
                                            sessionTitle: firstDaySession.title,
                                            sessionDescription:firstDaySession.summary,
                                            speakers:[],
                                            sessionType: firstDaySession.sessionType,
                                            date: 20,
                                          );
                                          setState(() {
                                            isBookmarking = false;
                                          });
                                        } ,child: Icon(Icons.calendar_month,color: kIconDeepBlue,)),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          verticalSpace(height: 10)
                        ],
                      );
                    }
                  },
                ):
                ///Day 2
                _selectedDate.day==21?ListView.builder(
                  itemCount: agendaDays[1].sessions.length,
                  itemBuilder: (context, index) {
                    final secondDaySession = agendaDays[1].sessions[index];

                    // Check if there are speakers for the session
                    if (secondDaySession.speakers!.isNotEmpty) {
                      // Fetch all speakers' details
                      final futures = secondDaySession.speakers!
                          .map((speaker) =>
                          fetchSpeakerById(speaker.speaker.key))
                          .toList();

                      return Column(
                        children: [
                          GestureDetector( onTap:(){
                            PersistentNavBarNavigator.pushNewScreen(
                              context,
                              screen: FullAgendaScreen(
                                title: secondDaySession.title,
                                day: 21,
                                startTime: secondDaySession.startTime,
                                endTime: secondDaySession.endTime,
                                isFromSession: false,
                                type:secondDaySession.sessionType,
                                userID: profileProvider.userID!,
                                //   sigs:widget.sigs,
                                description: secondDaySession.summary,
                                //  speakersCollection: widget.speakersCollection,
                                speakers: futures,
                                breakOuts: secondDaySession.breakoutSessions,
                              ),
                              withNavBar: false,
                              pageTransitionAnimation: PageTransitionAnimation.slideRight,
                            );
                          },
                            child: Container(padding: EdgeInsets.only(top: 20,bottom: 20),
                              height: secondDaySession.speakers!.length>=2?250:165,
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
                                        //  height: 180,
                                        color: kRightBubble,
                                        child: Column(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            Text(convertToAmPm(secondDaySession.startTime),
                                                style: kGreyTextStyle(fontsiZe: 12)),
                                            verticalSpace(height: 10),
                                            Text(convertToAmPm(secondDaySession.endTime),
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
                                              "${secondDaySession.title}",
                                              style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700),
                                            ),
                                            verticalSpace(height: 10),
                                            FutureBuilder<
                                                List<IndividualSpeaker?>>(
                                              future: Future.wait(futures),
                                              builder: (context, snapshot) {
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
                                                          "https://subscriptions.cioafrica.co/assets/${speaker!.photo!}",
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
                                                                '${speaker!.firstName} ${speaker.lastName}',style:kGreyTextStyle(fontsiZe: 12) ,),
                                                              Text(
                                                                '${speaker!.role} at ${speaker.company}',style: kNameTextStyle( fontsiZe: 10),overflow: TextOverflow.ellipsis,maxLines: 2,),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ))
                                                      .toList();
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

                                      GestureDetector(
                                          onTap:()async{

                                            setState(() {
                                              isBookmarking = true;
                                            });

                                            await createSession(
                                              currentUserId: profileProvider.userID!,
                                              startTime: secondDaySession.startTime,
                                              endTime: secondDaySession.endTime,
                                              sessionTitle: secondDaySession.title,
                                              sessionDescription:secondDaySession.summary,
                                              speakers:[],
                                              sessionType: secondDaySession.sessionType,
                                              date: 20,
                                            );
                                            setState(() {
                                              isBookmarking = false;
                                            });
                                          },
                                          child: const Icon(Icons.calendar_month,color: kIconDeepBlue,))
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          verticalSpace(height: 10)
                        ],
                      );
                    } else {
                      // If there are no speakers for the session
                      return Column(
                        children: [
                          GestureDetector( onTap:(){
                            PersistentNavBarNavigator.pushNewScreen(
                              context,
                              screen: FullAgendaScreen(
                                title: secondDaySession.title,
                                day: 21,
                                startTime: secondDaySession.startTime,
                                endTime: secondDaySession.endTime,
                                isFromSession: false,
                                type:secondDaySession.sessionType,
                                userID: profileProvider.userID!,
                                //   sigs:widget.sigs,
                                description: secondDaySession.summary,
                                //  speakersCollection: widget.speakersCollection,
                                speakers: false,
                                breakOuts: secondDaySession.breakoutSessions,

                              ),
                              withNavBar: false,
                              pageTransitionAnimation: PageTransitionAnimation.slideRight,
                            );
                          },
                            child: Container(
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
                                            Text(convertToAmPm(secondDaySession.startTime),
                                                style: kGreyTextStyle(fontsiZe: 12)),
                                            verticalSpace(height: 10),
                                            Text(convertToAmPm(secondDaySession.endTime),
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
                                              "${secondDaySession.title}",
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
                                            isBookmarking = true;
                                          });

                                          await createSession(
                                            currentUserId: profileProvider.userID!,
                                            startTime: secondDaySession.startTime,
                                            endTime: secondDaySession.endTime,
                                            sessionTitle: secondDaySession.title,
                                            sessionDescription:secondDaySession.summary,
                                            speakers:[],
                                            sessionType: secondDaySession.sessionType,
                                            date: 20,
                                          );
                                          setState(() {
                                            isBookmarking = false;
                                          });
                                        } ,child: Icon(Icons.calendar_month,color: kIconDeepBlue,)),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          verticalSpace(height: 10)
                        ],
                      );
                    }
                  },
                ):null,
              ),
            ),)
          ],
        ));
  }
}
