import 'dart:convert';
import 'dart:developer';

import 'package:dx5veevents/dioServices/dioPostService.dart';
import 'package:flutter/material.dart';

import '../dioServices/dioFetchService.dart';
import '../models/lastMinuteCheckinsModel.dart';
class StructureLAstMinute extends StatefulWidget {
  const StructureLAstMinute({super.key});

  @override
  State<StructureLAstMinute> createState() => _StructureLAstMinuteState();
}

class _StructureLAstMinuteState extends State<StructureLAstMinute> {


  @override
  void initState() {
    // TODO: implement initState
    fetchCheckins();

    super.initState();
  }


  fetchCheckins()async{
    final response = await DioFetchService().fetchLastMinuteCheckins();
    final filteredData = response.data['data'][1]["attendeeId"];
    ConferenceRoom conferenceRoom = ConferenceRoom.fromJson(response.data);
    print("data lenght is ${response.data["data"].length}");
    for (var roomData in conferenceRoom.data) {
      // Use the extracted attendee ID in your API call
      int attendeeId = roomData.attendeeId;
     ///Fetch attendee details
      DioFetchService().fetchSingleAttendee(id: attendeeId).then((value) async{
        await DioPostService().postCheckinDataFiltered(body: {
          "email": value.data["data"][0]["work_email"],
          "First_Name": value.data["data"][0]["first_name"],
          "Last_Name": value.data["data"][0]["last_name"],
          "Phone": value.data["data"][0]["phone"],
          "Company": value.data["data"][0]["company"],
          "Role": value.data["data"][0]["role"],
          "Event_ID": 3,
          "Attendee_ID":attendeeId,
          "Session_Name": roomData.roomName

        }, context: context);
      });
      ///Post data with fetched Details
      // try {
      //   var response = await dio.get('https://yourapi.com/endpoint?attendeeId=$attendeeId');
      //   print(response.data); // Process the response as needed
      // } catch (e) {
      //   print(e); // Handle errors or exceptions
      // }
    }
  }
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
