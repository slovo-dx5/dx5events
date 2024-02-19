
import 'dart:convert';
import 'dart:developer';

import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:dx5veevents/constants.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../dioServices/dioFetchService.dart';
import '../../models/agendaModel.dart';
import '../../models/speakersModel.dart';
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
  RefreshController _refreshController=RefreshController();
  DioCacheManager dioCacheManager = DioCacheManager(CacheConfig());
  List<SpeakersModel> events = [];
  List<IndividualSpeaker> speakers = [];






  @override
  void initState() {
    fetchAllSpeakers(filterIds: [23,45]);
    fetchCisoAgendaHere();    super.initState();
  }

  Future<List<IndividualSpeaker>> fetchAllSpeakers({required List<int> filterIds}) async {
    final response = await DioFetchService().fetchCISOSpeakers();


    if (response.statusCode == 200) {
      final speakerData = SpeakersModel.fromJson(response.data);
      final filteredIndividuals = speakerData.data
          .where((individual) => filterIds.contains(individual.id))
          .toList();
      setState(() {
        speakers = filteredIndividuals;// Assuming 'events' is of type List<SpeakersModel>
        log("speakers are ${speakers.first.id}");
        isLoading=false;
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
      setState(() {
        sessions = eventData.day.first.sessions;
        print("Attendee list length is ${eventData.day.first.date}");
        isLoading = false;
      });


      // return jsonData.map((userJson) => AttendeeModel.fromJson(userJson)).toList();
    } else {
      log(response.data);
      throw Exception('Failed to load data');
      isLoading = false;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(100.0), // Default AppBar height
        child: AppBarWithGradient(title: 'AGENDA', gradientBegin: kCIOPurple, gradientEnd: kCIOPink,),
      ),
      body:  Column(
            children: [
              TableCalendar(weekendDays:[DateTime.sunday,DateTime.monday,DateTime.tuesday,DateTime.saturday],
                daysOfWeekStyle:
                const DaysOfWeekStyle(weekdayStyle: TextStyle(color: kCIOPink)),
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
              ),verticalSpace(height: 20),
              const Divider(),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  :
              Expanded(
                child: SmartRefresher(controller: _refreshController,
                  enablePullDown: true,
                  header: const WaterDropHeader(waterDropColor: kCIOPink,),
                  onRefresh: ()async{
                    await dioCacheManager.clearAll();
                    await fetchCisoAgendaHere();

                    setState(() {
                      _refreshController.refreshCompleted();
                    });
                  },
                  onLoading: ()async{
                    await Future.delayed(Duration(milliseconds: 1000));
                    setState(() {
                      _refreshController.loadComplete();
                    });

                  },
                  child: ListView.builder(
        itemCount: sessions.length,
        itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(sessions[index].title),
                  );
        },
      ),
                ),
              ),
            ],
          ),
    );
  }
}
