import 'dart:convert';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:dx5veevents/constants.dart';
import 'package:flutter/material.dart';

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

class EventAgendaScreen extends StatefulWidget {
  String eventID;
  int eventDay;
  int eventMonth;
  int eventYear;
  String eventLocation;

  EventAgendaScreen(
      {super.key,
      required this.eventID,
      required this.eventDay,
      required this.eventMonth,
        required this.eventLocation,
      required this.eventYear});

  @override
  State<EventAgendaScreen> createState() => _EventAgendaScreenState();
}

class _EventAgendaScreenState extends State<EventAgendaScreen> {
  // late AgendaModel eventData;
  Map<DateTime, AgendaDay> _dayToAgendaMap = {};
  bool isLoading = true;
  final CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime? _selectedDate;
  final RefreshController _refreshController = RefreshController();
  DioCacheManager dioCacheManager = DioCacheManager(CacheConfig());
  List<SpeakersModel> events = [];
  List<IndividualSpeaker> speakers = [];

  List<Session> _sessions = [];
  List<AgendaDay> agendaDays = [];
  bool isBookmarking = false;
  bool isFetching = true;

  @override
  void initState() {

  setState(() {
     _selectedDate = DateTime(widget.eventYear, widget.eventMonth, widget.eventDay);
  });
    _loadSessions();
    super.initState();
  }

  void printDayToAgendaMap() {
    _dayToAgendaMap.forEach((date, agendaDay) {
      print('Date: ${date.toString()}'); // Print the date
    });
  }

  Future<void> _loadSessions() async {
    setState(() {
      isFetching = true;
    });
    final sessions = await fetchSessions();
    setState(() {
      _sessions = sessions;
      isFetching = false;
      _dayToAgendaMap = { for (var item in agendaDays) (item).date : item };
      printDayToAgendaMap();
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
        isLoading = false;
      });
      return speakers;
    } else {
      throw Exception('Failed to load events');
    }
  }

  Future fetchDx5veAgendaHere() async {
    final response =
        await DioFetchService().fetchdx5veAgenda(eventID: widget.eventID);

    setState(() {
      //isFetching=false;
    });

    if (response.statusCode == 200) {
      final eventData = AgendaModel.fromJson(response.data);
      setState(() {
        _sessions = eventData.days.first.sessions;
        agendaDays = eventData.days;
        isLoading = false;
      });

      // return jsonData.map((userJson) => AttendeeModel.fromJson(userJson)).toList();
    } else {
      throw Exception('Failed to load data');
      isLoading = false;
    }
  }

  Future<List<Session>> fetchSessions() async {
    try {
      final response =
          await DioFetchService().fetchdx5veAgenda(eventID: widget.eventID);

      final agendaModel = AgendaModel.fromJson(response.data);
      print("agenda model dta is $agendaModel");
      setState(() {
        agendaDays = agendaModel.days;
        print("Agenda datys are ${agendaDays.first.date}");
      });
      return agendaModel.days.expand((day) => day.sessions).toList();
    } catch (e) {
      print("session fetch error os ${e}");
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
          preferredSize: Size.fromHeight(70.0), // Default AppBar height
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
                // DateTime.tuesday,
                // DateTime.friday,
                // DateTime.saturday
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
              focusedDay: _selectedDate!,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                // Using `isSameDay` is recommended to disregard

                return isSameDay(_selectedDate, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDate, selectedDay)) {
                  setState(() {
                    _selectedDate = DateTime(selectedDay.year, selectedDay.month, selectedDay.day); // Normalize the date
                    print("Selected Day: $_selectedDate");
                  });
                }
              },
            ),
            const Divider(
              thickness: 2.5,
              color: kIconDeepBlue,
            ),
            Visibility(
              visible: isFetching == false,
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
                    await fetchDx5veAgendaHere();

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
                  child: _dayToAgendaMap.containsKey(_selectedDate)
                      ? ListView.builder(
                          itemCount:
                              _dayToAgendaMap[_selectedDate]!.sessions.length,
                          itemBuilder: (context, index) {
                            final session = _dayToAgendaMap[_selectedDate]!
                                .sessions[index];

                            if (session.speakers!.isNotEmpty) {
                              // Fetch all speakers' details
                              final futures = session.speakers!
                                  .map((speaker) =>
                                      fetchSpeakerById(speaker.speaker.key))
                                  .toList();

                              return agendaItemWithSpeakers(
                                context: context,
                                title: session.title,
                                startTime: session.startTime,
                                futures: futures,
                                endTime: session.endTime!,
                                sessionType: session.sessionType!,
                                summary: session.summary,
                                userID: profileProvider.userID!,
                                breakoutSessions: session.breakoutSessions,
                                speakers: session.speakers!,
                                onPressedFunction: () async {
                                  setState(() {
                                    isBookmarking = true;
                                  });

                                  await createSession(
                                    currentUserId: profileProvider.userID!,
                                    startTime: session.startTime,
                                    endTime: session.endTime!,
                                    sessionTitle: session.title,
                                    sessionDescription: session.summary,
                                    speakers: [],
                                    sessionType: session.sessionType!,
                                    date: 20,
                                  );
                                  setState(() {
                                    isBookmarking = false;
                                  });
                                }, eventLocation: widget.eventLocation, eventYear: widget.eventYear,eventDay: widget.eventDay, eventMonth: widget.eventMonth
                              );
                            } else {
                              return agendaItemWithoutSpeakers(
                                context: context,
                                title: session.title,
                                startTime: session.startTime,
                                endTime: session.endTime!,
                                type: session.sessionType!,
                                summary: session.summary,
                                userID: profileProvider.userID!,
                                breakoutSessions: session.breakoutSessions,
                                speakers: session.speakers!,
                                onPressedFunction: () async {
                                  setState(() {
                                    isBookmarking = true;
                                  });

                                  await createSession(
                                    currentUserId: profileProvider.userID!,
                                    startTime: session.startTime,
                                    endTime: session.endTime!,
                                    sessionTitle: session.title,
                                    sessionDescription: session.summary,
                                    speakers: [],
                                    sessionType: session.sessionType!,
                                    date: 20,
                                  );

                                  setState(() {
                                    isBookmarking = false;
                                  });
                                }, eventLocation: widget.eventLocation, eventYear: widget.eventYear,eventMonth: widget.eventMonth,eventDay: widget.eventDay
                              );
                            }
                          },
                        ) // Closing parenthesis for ListView.builder

                      : Center(
                          child: Text('No sessions available for this day')),

                  // _selectedDate.day==2|| _selectedDate.day==02?ListView.builder(
                  //   itemCount: agendaDays[0].sessions!.length,
                  //   itemBuilder: (context, index) {
                  //     final firstDaySession = agendaDays[0].sessions![index];
                  //
                  //     // Check if there are speakers for the session
                  //     if (firstDaySession!.speakers!.isNotEmpty) {
                  //       // Fetch all speakers' details
                  //       final futures = firstDaySession.speakers!
                  //           .map((speaker) =>
                  //           fetchSpeakerById(speaker.speaker.key))
                  //           .toList();
                  //       return agendaItemWithSpeakers(context: context,
                  //         title: firstDaySession.title,
                  //         startTime: firstDaySession.startTime,
                  //         futures: futures, endTime: firstDaySession.endTime!, sessionType: firstDaySession.sessionType!,
                  //         summary: firstDaySession.summary, userID: profileProvider.userID!,
                  //         breakoutSessions:firstDaySession.breakoutSessions, speakers: firstDaySession.speakers!, onPressedFunction: () async{
                  //           setState(() {
                  //             isBookmarking = true;
                  //           });
                  //
                  //           await createSession(
                  //           currentUserId: profileProvider.userID!,
                  //           startTime: firstDaySession.startTime,
                  //           endTime: firstDaySession.endTime!,
                  //           sessionTitle: firstDaySession.title,
                  //           sessionDescription:firstDaySession.summary,
                  //           speakers:[],
                  //           sessionType: firstDaySession.sessionType!,
                  //           date: 20,
                  //           );
                  //           setState(() {
                  //             isBookmarking = false;
                  //           });
                  //         } ,);
                  //
                  //
                  //     } else {
                  //       // If there are no speakers for the session
                  //       return agendaItemWithoutSpeakers(context: context,
                  //         title: firstDaySession.title,
                  //         startTime: firstDaySession.startTime,
                  //          endTime: firstDaySession.endTime!, type: firstDaySession.sessionType!,
                  //         summary: firstDaySession.summary, userID: profileProvider.userID!,
                  //         breakoutSessions:firstDaySession.breakoutSessions, speakers: firstDaySession.speakers!, onPressedFunction: () async{
                  //           setState(() {
                  //             isBookmarking = true;
                  //           });
                  //
                  //           await createSession(
                  //             currentUserId: profileProvider.userID!,
                  //             startTime: firstDaySession.startTime,
                  //             endTime: firstDaySession.endTime!,
                  //             sessionTitle: firstDaySession.title,
                  //             sessionDescription:firstDaySession.summary,
                  //             speakers:[],
                  //             sessionType: firstDaySession.sessionType!,
                  //             date: 20,
                  //           );
                  //           setState(() {
                  //             isBookmarking = false;
                  //           });
                  //         } ,);
                  //
                  //     }
                  //   },
                  // ):
                  //
                  //
                  // ///Day 2
                  // _selectedDate.day==21?ListView.builder(
                  //   itemCount: agendaDays[1].sessions.length,
                  //   itemBuilder: (context, index) {
                  //     final secondDaySession = agendaDays[1].sessions[index];
                  //
                  //     // Check if there are speakers for the session
                  //     if (secondDaySession.speakers!.isNotEmpty) {
                  //       // Fetch all speakers' details
                  //       final futures = secondDaySession.speakers!
                  //           .map((speaker) =>
                  //           fetchSpeakerById(speaker.speaker.key))
                  //           .toList();
                  //
                  //       return  agendaItemWithSpeakers(context: context,
                  //         title: secondDaySession.title,
                  //         startTime: secondDaySession.startTime,
                  //         futures: futures, endTime: secondDaySession.endTime!, sessionType: secondDaySession.sessionType!,
                  //         summary: secondDaySession.summary, userID: profileProvider.userID!,
                  //         breakoutSessions:secondDaySession.breakoutSessions, speakers: secondDaySession.speakers!, onPressedFunction: () async{
                  //           setState(() {
                  //             isBookmarking = true;
                  //           });
                  //
                  //           await createSession(
                  //             currentUserId: profileProvider.userID!,
                  //             startTime: secondDaySession.startTime,
                  //             endTime: secondDaySession.endTime!,
                  //             sessionTitle: secondDaySession.title,
                  //             sessionDescription:secondDaySession.summary,
                  //             speakers:[],
                  //             sessionType: secondDaySession.sessionType!,
                  //             date: 20,
                  //           );
                  //           setState(() {
                  //             isBookmarking = false;
                  //           });
                  //         } ,);
                  //     } else {
                  //       // If there are no speakers for the session
                  //       return agendaItemWithoutSpeakers(context: context,
                  //         title: secondDaySession.title,
                  //         startTime: secondDaySession.startTime,
                  //         endTime: secondDaySession.endTime!, type: secondDaySession.sessionType!,
                  //         summary: secondDaySession.summary, userID: profileProvider.userID!,
                  //         breakoutSessions:secondDaySession.breakoutSessions, speakers: secondDaySession.speakers!, onPressedFunction: () async{
                  //           setState(() {
                  //             isBookmarking = true;
                  //           });
                  //
                  //           await createSession(
                  //             currentUserId: profileProvider.userID!,
                  //             startTime: secondDaySession.startTime,
                  //             endTime: secondDaySession.endTime!,
                  //             sessionTitle: secondDaySession.title,
                  //             sessionDescription:secondDaySession.summary,
                  //             speakers:[],
                  //             sessionType: secondDaySession.sessionType!,
                  //             date: 20,
                  //           );
                  //           setState(() {
                  //             isBookmarking = false;
                  //           });
                  //         } ,);
                  //     }
                  //   },
                  // ):null,
                ),
              ),
            )
          ],
        ));
  }
}
