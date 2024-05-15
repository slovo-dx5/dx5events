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
import '../dioServices/dioPostService.dart';
import '../dioServices/dio_delete_service.dart';
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

openTicketURL({required String slug}) async {
  // Uri parsedURL = Uri.parse("https://tickets.cioafrica.co/");

  await launch("https://tickets.cioafrica.co/$slug");
}

linkedinButton({required BuildContext context,required String linkedinURL}) {
  return GestureDetector(onTap: (){openLinkedin(linkedinURL: linkedinURL);},
    child: Container(padding: EdgeInsets.all(8),
      width: MediaQuery.of(context).size.width * 0.6,
      decoration: BoxDecoration(color:kPrimaryBlueColor,borderRadius: BorderRadius.circular(30),border:
      Border.all(width: 0.5,color:kPrimaryBlueColor )),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
        SizedBox(height:25,width:25,child: Image.asset("assets/images/linkedin.png")),
        horizontalSpace(width: 10),
        const Text("LinkedIn",style: TextStyle(fontSize: 20,color: kWhiteColor,fontWeight: FontWeight.w500),)
      ],),
    ),
  );
}linkedinCircularButton({required String linkedinURL}) {
  return GestureDetector(onTap: (){openLinkedin(linkedinURL: linkedinURL);},
    child: CircleAvatar(
  backgroundImage:AssetImage("assets/images/linkedin.png") ,
    ),
  );
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

createSession(
    {required int currentUserId,

    required int sessionID,
    required DateTime date,
    }) async {


  Map<String, dynamic> sessionBodyData = {
    "attendee_id": currentUserId,
   "event_date": date.toString(),
    "session_id": sessionID,

  };



  print("attendee id is $currentUserId");
  print("date id is ${date.toString()}");
  print("session id is $sessionID");
  final response =
      await DioPostService().createSession(sessionBody: sessionBodyData);
  if (response.statusCode == 200) {
    log("Session Success:${response.data.toString()}");
    Fluttertoast.showToast(msg: "Session bookmarked successfully");
    return true;
  } else {
    log("Session Error:${response.data.toString()}");
    Fluttertoast.showToast(msg: "Error:Check your internet");
    return false;
  }
}

submitProposalToSPeak(
    {
    required String firstName,
    required String lastName,
    required String workEmail,
    required String workPhone,
    required String company,
    required String role,
    required String bio,
    required String imageID,
    required String linkedinProfileLink,
    required String eventId,
    required String reasonsForProposal,
    required List proposedTopics,



    }) async {
  Map<String, dynamic> _proposalBodyData = {
    "firstName": firstName,
    "lastName": lastName,
    "workEmail": workEmail,
    //"personalEmail": "johndoe@example.com",
    "workPhone": workPhone,
    //"personalPhone": "+0987654321",
    "company": company,
    "role": role,
    "bio": bio,
    "profilePhotoUrl": "https://subscriptions.cioafrica.co/assets/$imageID",
    "linkedinProfileLink": linkedinProfileLink,
    //"websiteLink": "https://johndoe-professional.com",
    "eventId": eventId,
    "proposedTopics": proposedTopics,
    "reasonsForProposal": reasonsForProposal,
    //"allowedContactMethods": ["Email", "Phone"]
    };

  final response =
      await DioPostService().createProposal(proposalBody:_proposalBodyData);
  if (response.statusCode == 200) {
    log("proposal Success:${response.data.toString()}");
    Fluttertoast.showToast(msg: "Proposal submitted successfully");
    return true;
  } else {
    log("Session Error:${response.data.toString()}");
    Fluttertoast.showToast(msg: "Error:Check your internet");
    return false;
  }
}

submitSponsorProposal(
    {
    required String firstName,
    required String eventID,
    required String lastName,
    required String workEmail,
    required String workPhone,
    required String company,
    required String role,
    required String reason_of_interest,




    }) async {
  Map<String, dynamic> _proposalBodyData = {
    "event_id":eventID,
    "first_name": firstName,
    "last_name": lastName,
      "work_email": workEmail,
      "phone": workPhone,
      "company": company,
      "role": role,
      "reason_for_sponsorship_interest": reason_of_interest,

    };

  final response =
      await DioPostService().createSponsorSubmission(sessionBody: _proposalBodyData);
  if (response.statusCode == 200) {
    log("proposal Success:${response.data.toString()}");
    Fluttertoast.showToast(msg: "Proposal submitted successfully");
    return true;
  } else {
    log("Session Error:${response.data.toString()}");
    Fluttertoast.showToast(msg: "Error:Check your internet");
    return false;
  }
}

deleteSession({required int sessionID}) async {
  try {
    final response =
        await DioDeleteService().deleteUserSession(sessionID: sessionID);
    if (response.statusCode == 200 || response.statusCode == 204) {
      Fluttertoast.showToast(
          msg: "Session deleted successfully :)",
          backgroundColor: kSuccessGreen);
    } else {

      Fluttertoast.showToast(msg: "Failed :)", backgroundColor: kLogoutRed);
    }
  } catch (e) {
  }
}

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

String formatDate(DateTime date) {
  final DateFormat formatter = DateFormat('yyyy-MM-dd');
  return formatter.format(date);
}