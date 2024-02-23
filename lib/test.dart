// import 'package:flutter/material.dart';
//
// class TestPage extends StatefulWidget {
//   const TestPage({super.key});
//
//   @override
//   State<TestPage> createState() => _TestPageState();
// }
//
// class _TestPageState extends State<TestPage> {
//   @override
//   Widget build(BuildContext context) {
//
//     return Scaffold(
//       appBar: const PreferredSize(
//         preferredSize: Size.fromHeight(100.0), // Default AppBar height
//         child: AppBarWithGradient(title: 'AGENDA', gradientBegin: kCIOPurple, gradientEnd: kCIOPink,),
//       ),
//       body:  Column(
//             children: [
//               TableCalendar(weekendDays:[DateTime.sunday,DateTime.monday,DateTime.tuesday,DateTime.saturday],
//                 daysOfWeekStyle:
//                 const DaysOfWeekStyle(weekdayStyle: TextStyle(color: kCIOPink)),
//                 calendarStyle: CalendarStyle(
//                     selectedDecoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: kCIOPink.withOpacity(0.5),
//                     )),
//                 headerStyle: const HeaderStyle(
//                     headerPadding: EdgeInsets.all(15),
//                     leftChevronVisible: false,
//                     rightChevronVisible: false,
//                     formatButtonVisible: false,
//                     titleTextStyle: TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w600,
//                     )),
//                 firstDay: kCISOFirstDay,
//                 lastDay: kCISOLastDay,
//                 focusedDay: _selectedDate,
//                 calendarFormat: _calendarFormat,
//                 selectedDayPredicate: (day) {
//                   // Using `isSameDay` is recommended to disregard
//
//                   return isSameDay(_selectedDate, day);
//                 },
//                 onDaySelected: (selectedDay, focusedDay) {
//                   if (selectedDay.day == 22 ||
//                       selectedDay.day == 23 ||
//                       selectedDay.day == 24) {
//                     setState(() {
//                       _selectedDate = selectedDay;
//                       // DateTime dateTime = DateTime.parse(_selectedDate);
//                     });
//                   }
//                 },
//               ),verticalSpace(height: 20),
//               const Divider(),
//               isLoading
//                   ? const Center(child: CircularProgressIndicator())
//                   :
//               Expanded(
//                 child: SmartRefresher(controller: _refreshController,
//                   enablePullDown: true,
//                   header: const WaterDropHeader(waterDropColor: kCIOPink,),
//                   onRefresh: ()async{
//                     await dioCacheManager.clearAll();
//                     await fetchCisoAgendaHere();
//
//                     setState(() {
//                       _refreshController.refreshCompleted();
//                     });
//                   },
//                   onLoading: ()async{
//                     await Future.delayed(Duration(milliseconds: 1000));
//                     setState(() {
//                       _refreshController.loadComplete();
//                     });
//
//                   },
//                   child: ListView.builder(
//         itemCount: sessions.length,
//         itemBuilder: (context, index) {
//           for(final speakeritems in sessions[index].speakers! )
//             IndividualSpeaker speaker = await fetchSpeaker(speakerAssignment.speaker.key);
//             return FutureBuilder(future: fetchAllSpeakers(filterIds: sessions[index].), builder: (context, snapshot){
//
//           });
//
//
//                     // AgendaWidget(startTime:sessions[index].startTime,
//                     //   endTime: sessions[index].endTime,
//                     //   sessionTitle: sessions[index].title, speakers: speakers, sessionType:sessions[index].sessionType,);
//                   //   ListTile(
//                   //   title: Text(sessions[index].title),
//                   // );
//         },
//       ),
//                 ),
//               ),
//             ],
//           ),
//     );
//   }
// }
