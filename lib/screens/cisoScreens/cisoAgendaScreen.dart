import 'dart:convert';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:dx5veevents/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../dioServices/dioFetchService.dart';
import '../../helpers/helper_functions.dart';
import '../../models/agendaModel.dart';
import '../../models/speakersModel.dart';
import '../../widgets/agendaWidget.dart';
import '../../widgets/appbarWidget.dart';

class CISOAgendaScreen extends StatefulWidget {
  const CISOAgendaScreen({super.key});

  @override
  State<CISOAgendaScreen> createState() => _CISOAgendaScreenState();
}

class _CISOAgendaScreenState extends State<CISOAgendaScreen> {
  // late AgendaModel eventData;
  List<Session> sessions = [];
  bool isLoading = true;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _selectedDate = DateTime(2024, 03, 20);
  RefreshController _refreshController = RefreshController();
  DioCacheManager dioCacheManager = DioCacheManager(CacheConfig());
  List<SpeakersModel> events = [];
  List<IndividualSpeaker> speakers = [];

  List<Session> _sessions = [];

  @override
  void initState() {
    // fetchCisoAgendaHere();
    _loadSessions();
    super.initState();
  }

  Future<void> _loadSessions() async {
    final sessions = await fetchSessions();
    setState(() {
      _sessions = sessions;
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
        sessions = eventData.days.first.sessions;
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
      print("speaker dtaa is $speakerssModel");

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
                if (selectedDay.day == 22 ||
                    selectedDay.day == 23 ||
                    selectedDay.day == 24) {
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
            Expanded(
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
                child: ListView.builder(
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) {
                    final session = _sessions[index];

                    // Check if there are speakers for the session
                    if (session.speakers!.isNotEmpty) {
                      // Fetch all speakers' details
                      final futures = session.speakers!
                          .map((speaker) =>
                              fetchSpeakerById(speaker.speaker.key))
                          .toList();

                      return Column(
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
                                          Text(convertToAmPm(session.startTime),
                                              style: kGreyTextStyle(fontsiZe: 12)),
                                          verticalSpace(height: 10),
                                          Text(convertToAmPm(session.endTime),
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
                                            "${session.title}",
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
                                                return Text(
                                                    'Loading speakers...');
                                              } else {
                                                return Text(
                                                    'Speakers details not available');
                                              }
                                            },
                                          ),

                                        ],
                                      ),
                                    ),

                                    const Padding(
                                      padding:  EdgeInsets.fromLTRB(10,70,5,70),
                                      child: Icon(Icons.calendar_month,color: kIconDeepBlue,),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                          verticalSpace(height: 10)
                        ],
                      );
                    } else {
                      // If there are no speakers for the session
                      return Column(
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
                                          Text(convertToAmPm(session.startTime),
                                              style: kGreyTextStyle(fontsiZe: 12)),
                                          verticalSpace(height: 10),
                                          Text(convertToAmPm(session.endTime),
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
                                            "${session.title}",
                                            style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700),
                                          ),
                                          verticalSpace(height: 10),


                                        ],
                                      ),
                                    ),

                                    const Padding(
                                      padding:  EdgeInsets.fromLTRB(10,30,5,30),
                                      child: Icon(Icons.calendar_month,color: kIconDeepBlue,),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                          verticalSpace(height: 10)
                        ],
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ));
  }
}
