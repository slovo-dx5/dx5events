import 'package:flutter/material.dart';

import '../dioServices/dioFetchService.dart';
import '../dioServices/dioPostService.dart';
import '../models/eventAttendeesModel.dart';
class CookFigures extends StatefulWidget {
  const CookFigures({super.key});

  @override
  State<CookFigures> createState() => _CookFiguresState();
}

class _CookFiguresState extends State<CookFigures> {

  List<EventAttendeeModel>? attendees;

  Future fetchAllAttendees() async {
    final response = await DioFetchService().fetchCIOAttendees(eventID: "60");

    if (response.statusCode == 200) {
      List<dynamic> filteredData = response.data['data'].toList();
      List<EventAttendeeModel> userList = List<EventAttendeeModel>.from(
          filteredData.map((user) => EventAttendeeModel.fromJson(user)));

      setState(() {
        attendees = userList;
      });

      if (attendees != null && attendees!.isNotEmpty) {
        // Process the first 40 attendees for Day 1
        await _processAttendees(attendees!.take(55).toList(),
            "DAY 1: Modern Identity & Access Management");

        // Process the next 30 attendees for Day 2
        await _processAttendees(attendees!.skip(40).take(36).toList(),
            "DAY 1:DEVSECOPS: EMBEDDING SECURITY...");
        await _processAttendees(attendees!.skip(70).take(24).toList(),
            "DAY 2: INSIDER THREATS...");
        await _processAttendees(attendees!.skip(120).take(52).toList(),
            "DAY 2: REGULATORY COMPLIANCE");
        await _processAttendees(attendees!.skip(170).take(13).toList(),
            "DAY 2: SUPPLY CHAIN SECURITY");

      }
    }
  }

  Future<void> _processAttendees(
      List<EventAttendeeModel> attendeeBatch, String sessionName) async {
    for (var attendee in attendeeBatch) {
      int attendeeId = attendee.attendeeId;

      var response =
      await DioFetchService().fetchSingleAttendeeForEvent(id: attendeeId, eventID: 60);
      var data = response.data["data"];

      if (data != null && data.isNotEmpty) {
        var attendeeDetails = data[0];

        await DioPostService().postCheckinDataFiltered(body: {
          "email": attendeeDetails["work_email"] ?? "email not present",
          "First_Name": attendeeDetails["first_name"] ?? "missing value",
          "Last_Name": attendeeDetails["last_name"] ?? "missing value",
          "Phone": attendeeDetails["phone"] ?? "missing value",
          "Company": attendeeDetails["company"],
          "Role": attendeeDetails["role"],
          "Event_ID": 60,
          "Attendee_ID": attendeeId,
          "Session_Name": sessionName
        }, context: context);

        print("Post successful for attendee ID: $attendeeId, Session: $sessionName");
      } else {
        print('No attendee details found for attendee ID: $attendeeId');
        print("Response is ${response.data}");
      }
    }
  }


@override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchAllAttendees();
  }
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
