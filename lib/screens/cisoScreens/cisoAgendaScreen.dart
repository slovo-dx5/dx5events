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
       // backgroundColor: kScaffoldColor,
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
                      return agendaItemWithSpeakers(context: context,
                        title: firstDaySession.title,
                        startTime: firstDaySession.startTime,
                        futures: futures, endTime: firstDaySession.endTime, sessionType: firstDaySession.sessionType,
                        summary: firstDaySession.summary, userID: profileProvider.userID!,
                        breakoutSessions:firstDaySession.breakoutSessions, speakers: firstDaySession.speakers!, onPressedFunction: () async{
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
                        } ,);
                     

                    } else {
                      // If there are no speakers for the session
                      return agendaItemWithoutSpeakers(context: context,
                        title: firstDaySession.title,
                        startTime: firstDaySession.startTime,
                         endTime: firstDaySession.endTime, sessionType: firstDaySession.sessionType,
                        summary: firstDaySession.summary, userID: profileProvider.userID!,
                        breakoutSessions:firstDaySession.breakoutSessions, speakers: firstDaySession.speakers!, onPressedFunction: () async{
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
                        } ,);

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

                      return  agendaItemWithSpeakers(context: context,
                        title: secondDaySession.title,
                        startTime: secondDaySession.startTime,
                        futures: futures, endTime: secondDaySession.endTime, sessionType: secondDaySession.sessionType,
                        summary: secondDaySession.summary, userID: profileProvider.userID!,
                        breakoutSessions:secondDaySession.breakoutSessions, speakers: secondDaySession.speakers!, onPressedFunction: () async{
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
                        } ,);
                    } else {
                      // If there are no speakers for the session
                      return agendaItemWithoutSpeakers(context: context,
                        title: secondDaySession.title,
                        startTime: secondDaySession.startTime,
                        endTime: secondDaySession.endTime, sessionType: secondDaySession.sessionType,
                        summary: secondDaySession.summary, userID: profileProvider.userID!,
                        breakoutSessions:secondDaySession.breakoutSessions, speakers: secondDaySession.speakers!, onPressedFunction: () async{
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
                        } ,);
                    }
                  },
                ):null,
              ),
            ),)
          ],
        ));
  }
}
