// import 'dart:convert';
//
// import 'package:table_calendar/table_calendar.dart';
//
//
//
// class EventAgendaScreen extends StatefulWidget {
//   String eventID;
//
//   EventAgendaScreen({super.key, required this.eventID});
//
//   @override
//   State<EventAgendaScreen> createState() => _EventAgendaScreenState();
// }
//
// class _EventAgendaScreenState extends State<EventAgendaScreen> {
//   // late AgendaModel eventData;
//
//   bool isLoading = true;
//   final CalendarFormat _calendarFormat = CalendarFormat.week;
//   DateTime _selectedDate = DateTime(2024, 05, 02);
//
//   List<SpeakersModel> events = [];
//   List<IndividualSpeaker> speakers = [];
//
//   List<Session> _sessions = [];
//   List<AgendaDay> agendaDays = [];
//   bool isBookmarking = false;
//   bool isFetching=true;
//
//
//
//   @override
//   void initState() {
//     // fetchCisoAgendaHere();
//     _loadSessions();
//     super.initState();
//   }
//
//   Future<void> _loadSessions() async {
//     setState(() {
//       print("fetching events");
//       isFetching=true;
//     });
//     final sessions = await fetchSessions();
//     setState(() {
//       _sessions = sessions;
//       isFetching=false;
//
//     });
//   }
//
//
//   Future<List<Session>> fetchSessions() async {
//     try {
//       final response = await DioFetchService().fetchdx5veAgenda(eventID: widget.eventID);
//
//       log("response is ${response.data}");
//
//       final agendaModel = AgendaModel.fromJson(response.data);
//       print("agenda model dta is $agendaModel");
//       setState(() {
//         agendaDays=agendaModel.days;
//       });
//       return agendaModel.days.expand((day) => day.sessions).toList();
//     } catch (e) {
//       print("session fetch error os ${e}");
//       return [];
//     }
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//
//     return Scaffold(
//         appBar: const PreferredSize(
//           preferredSize: Size.fromHeight(75.0), // Default AppBar height
//           child: AppBarWithGradient(
//             title: 'AGENDA',
//             gradientBegin: kCIOPurple,
//             gradientEnd: kCIOPink,
//           ),
//         ),
//         // backgroundColor: kScaffoldColor,
//         body: Column(
//           children: [
//             TableCalendar(
//               weekendDays: const [
//                 DateTime.sunday,
//                 DateTime.monday,
//                 DateTime.tuesday,
//                 DateTime.friday,
//                 DateTime.saturday
//               ],
//               daysOfWeekStyle: const DaysOfWeekStyle(
//                   weekdayStyle: TextStyle(color: kCIOPink)),
//               calendarStyle: CalendarStyle(
//                   selectedDecoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: kCIOPink.withOpacity(0.5),
//                   )),
//               headerStyle: const HeaderStyle(
//                   headerPadding: EdgeInsets.all(15),
//                   leftChevronVisible: false,
//                   rightChevronVisible: false,
//                   formatButtonVisible: false,
//                   titleTextStyle: TextStyle(
//                     fontSize: 15,
//                     fontWeight: FontWeight.w600,
//                   )),
//               firstDay: kCISOFirstDay,
//               lastDay: kCISOLastDay,
//               focusedDay: _selectedDate,
//               calendarFormat: _calendarFormat,
//               selectedDayPredicate: (day) {
//                 // Using `isSameDay` is recommended to disregard
//
//                 return isSameDay(_selectedDate, day);
//               },
//               onDaySelected: (selectedDay, focusedDay) {
//                 if (selectedDay.day == 20 ||
//                     selectedDay.day == 21
//                 ) {
//                   setState(() {
//                     _selectedDate = selectedDay;
//                     // DateTime dateTime = DateTime.parse(_selectedDate);
//                   });
//                 }
//               },
//             ),
//             const Divider(
//               thickness: 2.5,
//               color: kIconDeepBlue,
//             ),
//             Visibility(
//               visible: isFetching==false,
//               replacement: const CircularProgressIndicator(),
//               child: Expanded(
//                 child: SmartRefresher(
//
//
//                   ///Day 1
//                   child: _selectedDate.day==2|| _selectedDate.day==02?ListView.builder(
//                     itemCount: agendaDays[0].sessions!.length,
//                     itemBuilder: (context, index) {
//                       final firstDaySession = agendaDays[0].sessions![index];
//
//                       // Check if there are speakers for the session
//
//
//
//                     },
//                   ):
//
//
//                   ///Day 2
//                   _selectedDate.day==21?ListView.builder(
//                     itemCount: agendaDays[1].sessions.length,
//                     itemBuilder: (context, index) {
//                       final secondDaySession = agendaDays[1].sessions[index];
//
//                       // Check if there are speakers for the session
//                       if (secondDaySession.speakers!.isNotEmpty) {
//                         // Fetch all speakers' details
//                         final futures = secondDaySession.speakers!
//                             .map((speaker) =>
//                             fetchSpeakerById(speaker.speaker.key))
//                             .toList();
//
//                         return  agendaItemWithSpeakers(context: context,
//                           title: secondDaySession.title,
//                           startTime: secondDaySession.startTime,
//                           futures: futures, endTime: secondDaySession.endTime!, sessionType: secondDaySession.sessionType!,
//                           summary: secondDaySession.summary, userID: profileProvider.userID!,
//                           breakoutSessions:secondDaySession.breakoutSessions, speakers: secondDaySession.speakers!, onPressedFunction: () async{
//                             setState(() {
//                               isBookmarking = true;
//                             });
//
//                             setState(() {
//                               isBookmarking = false;
//                             });
//                           } ,);
//                       } else {
//                         // If there are no speakers for the session
//
//                       }
//                     },
//                   ):null,
//                 ),
//               ),)
//           ],
//         ));
//   }
// }
