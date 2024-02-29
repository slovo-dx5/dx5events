import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../constants.dart';
import '../../dioServices/dioFetchService.dart';
import '../../models/sessionModel.dart';

import '../../widgets/sessionWidget.dart';

class UserSessionsScreen extends StatefulWidget {
  int userid;
   UserSessionsScreen({required this.userid,super.key});

  @override
  State<UserSessionsScreen> createState() => _UserSessionsScreenState();
}

class _UserSessionsScreenState extends State<UserSessionsScreen> {
 List<SessionModel>? sessions=[];
 bool isFetching=false;
 // List<SpeakersModel> events = [];
 // List<Speaker> speakers = [];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //fetchAllSpeakers();
    print("user id is ${widget.userid}");
    fetchSessions(userID: widget.userid);
  }
 // Future<List<SpeakersModel>> fetchAllSpeakers() async {
 //   final response = await DioFetchService().fetchEvent();
 //
 //
 //   if (response.statusCode == 200) {
 //     final List<dynamic> data = json.decode(json.encode(response.data));
 //     final List<SpeakersModel> speakersList = data.map((eventData) => SpeakersModel.fromJson(eventData)).toList();
 //     setState(() {
 //       events = speakersList;
 //       speakers = events.isNotEmpty ? events[0].acf.speakers : [];// Assuming 'events' is of type List<SpeakersModel>
 //
 //       isFetching=false;
 //     });
 //     return speakersList;
 //   } else {
 //     throw Exception('Failed to load events');
 //   }
 // }

  fetchSessions({required int userID})async{
    setState(() {
      isFetching=true;
    });
    final response= await DioFetchService().getUserSessions();

    if (response.statusCode == 200) {
      final List<dynamic> sessionListJson = response.data['data'];
      setState(() {

         sessions = sessionListJson
            .map((sessionJson) => SessionModel.fromJson(sessionJson))
            .where((session) => session.attendeeId == userID)
            .toList();
         print("sessions are ${sessionListJson.first}");

          isFetching=false;

      });

      return sessions;

    }else{
      setState(() {
        isFetching=false;
        sessions=[];
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title:const Text(
            "SAVED SESSIONS",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),

        ),
        body:


        (isFetching|| sessions==null)?const Center(child: SpinKitCircle(color: kCIOPink,),)

    : sessions!.isEmpty?const Center(child: Text("Your bookmarked sessions will appear here."),):
    ListView.builder(
        itemCount: sessions!.length,
        itemBuilder: (BuildContext context, int index){
          final pulledSession=sessions![index];
          return
          SessionWidget(sessionType: pulledSession.session.type,
            sessionId: pulledSession.id,
            sessionTitle: pulledSession.session.title,
            startTime: pulledSession.session.startTime,
            endTime: pulledSession.session.endTime,
            speakers: pulledSession.session.speakers,
            description: pulledSession.session.description,
            sessions: sessions!, date: pulledSession.session.date,  );
        })
    );
  }
}
