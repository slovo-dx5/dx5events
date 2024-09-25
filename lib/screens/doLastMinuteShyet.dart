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
    ConferenceRoom conferenceRoom = ConferenceRoom.fromJson(response.data);

      for (var roomData in conferenceRoom.data) {
        // Use the extracted attendee ID in your API call
        int attendeeId = roomData.attendeeId;


          // Fetch attendee details
          var response = await DioFetchService().fetchSingleAttendeeForEvent(id: attendeeId, eventID: 10);
          var data = response.data["data"];

          // Ensure the data list is not empty
          if (data != null && data.isNotEmpty) {
            var attendeeDetails = data[0];
            // Post check-in data
            await DioPostService().postCheckinDataFiltered(body: {
              "email": attendeeDetails["work_email"] ?? "email not present",
              "First_Name": attendeeDetails["first_name"] ?? "missing value",
              "Last_Name": attendeeDetails["last_name"] ?? "missing value",
              "Phone": attendeeDetails["phone"] ?? "missing value",
              "Company": attendeeDetails["company"],
              "Role": attendeeDetails["role"],
              "Event_ID": 8,
              "Attendee_ID": attendeeId,
              "Session_Name": roomData.roomName
            }, context: context);
            print("post successful");
          } else {
            // Handle the case where no attendee details are found
            print('No attendee details found for attendee ID: $attendeeId');
            print("response is ${response.data}");
          }



      }


  }
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
