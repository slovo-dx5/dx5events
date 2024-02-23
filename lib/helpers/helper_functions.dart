import 'dart:convert';
import 'dart:developer';


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../constants.dart';
import '../dioServices/dioFetchService.dart';
import '../models/image_model.dart';


greetingFunc({required String firstName}) {
  final currentHour = DateTime.now().hour;
  if (currentHour >= 0 && currentHour < 12) {
    return Text("Good morning\n$firstName",
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500));
  } else if (currentHour >= 12 && currentHour < 17) {
    return Text(
      "Good afternoon\n$firstName",
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
    );
  } else {
    return Text("Good evening\n$firstName",
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500));
  }
}

visitSponsor({required String url}) async {
  Uri workWithUsURL = Uri.parse(url);

  await launchUrl(workWithUsURL);
}

workWithUs() async {
  // Replace 'com.example.your_app' with your app's package name
  //Uri workWithUsURL = Uri.parse(sponsorshipURL);

//  await launchUrl(workWithUsURL);
}

openLinkedin({required String linkedinURL}) async {
  Uri parsedURL = Uri.parse(linkedinURL);

  await launch(linkedinURL);
}

linkedinButton({required BuildContext context,required String linkedinURL}) {
  return ElevatedButton(
      onPressed: () {openLinkedin(linkedinURL: linkedinURL);},
      child: Container(padding: EdgeInsets.all(8),
        width: MediaQuery.of(context).size.width * 0.6,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(15),border:
        Border.all(width: 0.5,color:kCIOPink )),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          SizedBox(height:25,width:25,child: Image.asset("assets/images/linkedin.png")),
          horizontalSpace(width: 10),
          Text("Linkedin",style: TextStyle(fontSize: 20),)
        ],),
      ));
}

getSpeakerImage({required String id}) async {
  final response = await DioFetchService().fetchImage(id: id);
  if (response.statusCode == 200) {
    final Map<String, dynamic> imageData =
    json.decode(json.encode(response.data));

    return ImageModel.fromJson(imageData).sourceUrl;
  } else {
    throw Exception('Failed to load events');
  }
}

// createSession(
//     {required int currentUserId,
//     required String startTime,
//     required String endTime,
//     required String sessionTitle,
//     required String sessionType,
//     required int date,
//     required String sessionDescription,
//     required var speakers}) async {
//   Map<String, dynamic> sessionBodyData = {
//     "attendee_id": currentUserId,
//     "sessions": {
//       "user_id": currentUserId,
//       "start_time": startTime,
//       "end_time": endTime,
//       "title": sessionTitle,
//       "description": sessionDescription,
//       "type": sessionType,
//       "date": date,
//       "speakers": speakers
//     }
//   };
//   final response =
//       await DioPostService().createSession(sessionBody: sessionBodyData);
//   if (response.statusCode == 200) {
//     log("Session Success:${response.data.toString()}");
//     Fluttertoast.showToast(msg: "Session bookmarked successfully");
//     return true;
//   } else {
//     log("Session Error:${response.data.toString()}");
//     Fluttertoast.showToast(msg: "Error:Check your internet");
//     return false;
//   }
// }

// deleteSession({required int sessionID}) async {
//   try {
//     final response =
//         await DioDeleteService().deleteUserSession(sessionID: sessionID);
//     if (response.statusCode == 200 || response.statusCode == 204) {
//       Fluttertoast.showToast(
//           msg: "Session deleted successfully :)",
//           backgroundColor: kSuccessGreen);
//     } else {
//
//       Fluttertoast.showToast(msg: "Failed :)", backgroundColor: kLogoutRed);
//     }
//   } catch (e) {
//   }
// }
//
// getSpeakerImage({required String id}) async {
//   final response = await DioFetchService().fetchImage(id: id);
//   if (response.statusCode == 200) {
//     final Map<String, dynamic> imageData =
//         json.decode(json.encode(response.data));
//
//     return ImageModel.fromJson(imageData).sourceUrl;
//   } else {
//     throw Exception('Failed to load events');
//   }
// }

workInProgress() {
  return Center(
    child: Text("Page coming soon"),
  );
}

// logOut(BuildContext context) async {
//   await clearAllPrefs();
//   Navigator.of(context).pushReplacement(
//     MaterialPageRoute(
//       builder: (context) => InitialScreen(),
//     ),
//   );
// }

String getInitials(String name) {
  List<String> nameSplit = name.split(" ");
  String firstNameInitial = nameSplit[0][0];
  return firstNameInitial;
}

chatInitials({required String name}) {
  return Container(
    //margin: EdgeInsets.only(16),
    height: 60,
    width: 60,
    decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100), color: Color(0xff272c35)),
    child: Stack(children: <Widget>[
      Align(
        alignment: Alignment.center,
        child: Text(
          getInitials(name),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xff0077d7),
            fontSize: 20,
          ),
        ),
      ),
    ]),
  );
}

requestMeeting(
    {required int currentUserID,
    required int otherUserID,
    required String requestedBy,
    required String meetingWith,
    required String message,
    required String startTime,

    required String requestedByID,
    required String meetingWithI,
    required String company}) {
  String meetingID = const Uuid().v4();

  ///Create meeting in senders collection
  usersRef.doc(currentUserID.toString()).collection("meetings").doc(meetingID).set({
    "id": meetingID,

    "requested_by": requestedBy, ///The person requesting the meeting
    "requested_by_id": requestedByID, ///The person requesting the meeting
    "wants_to_meet_with": meetingWith, ///The person they want to meet with
    "wants_to_meet_with_id": meetingWithI,
    "isAccepted": false,
    "isCancelled": false,
    "isDeclined": false,
    "isDefault": false,
    "date_requested": Timestamp.now(),
    "message": message,
    "startTime": startTime,


    "company": company,

  });

  ///Create meeting in other persons collection
  usersRef
      .doc(otherUserID.toString())
      .collection("meetings")
      .doc(meetingID)
      .set({
    "id": meetingID,

    "requested_by": requestedBy,

    ///The person requesting the meeting
    "requested_by_id": requestedByID,

    ///The person requesting the meeting
    "wants_to_meet_with": meetingWith,

    ///The person they want to meet with
    "wants_to_meet_with_id": meetingWithI,

    ///The person they want to meet with
    "isAccepted": false,
    "isCancelled": false,
    "isDeclined": false,
    "isDeleted": false,
    "date_requested": Timestamp.now(),
    "message": message,
    "startTime": startTime,


    "company": company,
  });
}


String addThirtyMinutes({required String time}) {
  // Parse the input string into a DateTime object
  final format = DateFormat("h:mm a");
  DateTime dateTime = format.parse(time);

  // Add 30 minutes
  dateTime = dateTime.add(const Duration(minutes: 30));

  // Convert the DateTime back to a string in the original format
  return format.format(dateTime);
}