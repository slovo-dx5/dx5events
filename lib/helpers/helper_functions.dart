import 'dart:convert';
import 'dart:developer';
import 'dart:io';


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../constants.dart';
import '../dioServices/base_url.dart';
import '../dioServices/dioFetchService.dart';
import '../dioServices/dioPostService.dart';
import '../dioServices/dio_delete_service.dart';
import '../models/image_model.dart';
import '../services/activity_logger.dart';


greetingFunc({required String firstName}) {
  final currentHour = DateTime.now().hour;
  if (currentHour >= 0 && currentHour < 12) {
    return Text("Good morning\n$firstName",
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500,color: kTextColorBlack));
  } else if (currentHour >= 12 && currentHour < 17) {
    return Text(
      "Good afternoon\n$firstName",
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500,color: kTextColorBlack),
    );
  } else {
    return Text("Good evening\n$firstName",
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500,color: kTextColorBlack));
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

Future<void> openLinkedin({required String linkedinURL}) async {
  // Ensure the URL has the correct scheme
  if (!linkedinURL.startsWith('http://') && !linkedinURL.startsWith('https://')) {
    linkedinURL = 'https://$linkedinURL';
  }

  final Uri parsedURL = Uri.parse(linkedinURL);

  if (await canLaunchUrl(parsedURL)) {
    await launchUrl(parsedURL, mode: LaunchMode.externalApplication);
  } else {
    throw 'Could not launch $linkedinURL';
  }
}
openTicketURL({required String slug}) async {
  // Uri parsedURL = Uri.parse("https://tickets.cioafrica.co/");

  await launch("https://tickets.cioafrica.co/$slug");
}

openBannerURL() async {
  // Uri parsedURL = Uri.parse("https://tickets.cioafrica.co/");

  await launch("https://tickets.cioafrica.co/events/cio100-symposium-and-awards?rf=REFTB7RUK8R");
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
    "profilePhotoUrl": "${BaseURL.Baseurl}/assets/$imageID",
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
openWhatsapp({required String contactNumber, required BuildContext context}) async {
  // Replace starting 0 with 254
  String contact = contactNumber.startsWith('0')
      ? '254${contactNumber.substring(1)}'
      : contactNumber;

  var message = "Hello, this is the CIO Africa Concierge service. I'm messaging you regarding a pending meeting.";
  var androidUrl = "whatsapp://send?phone=$contact&text=$message";
  var iosUrl = "https://wa.me/$contact?text=${Uri.encodeComponent(message)}";

  try {
    if (Platform.isIOS) {
      await launchUrl(Uri.parse(iosUrl));
    } else {
      await launchUrl(Uri.parse(androidUrl));
    }
  } on Exception {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('WhatsApp not installed')),
    );
  }
}


requestMeeting(
    {required int currentUserID,
    required int otherUserID,
    required String requestedBy,
    required String requestedByEmail,
    required String meetingWithEmail,
    required String requestedByPhone,
    required String meetingWithPhone,
    required String meetingWith,
    required String message,
    required String startTime,
    required String tableSlot,
    DateTime? meetingDateTime,

    required String requestedByID,
    required String meetingWithI,
    required String company}) async{
  String meetingID = const Uuid().v4();

  // Absolute meeting moment (chosen day + start time). Stored structurally so
  // reminders can be scheduled 15 minutes before it. Null for legacy/no-date
  // requests, in which case no reminder can be scheduled.
  final Timestamp? meetingTime =
      meetingDateTime != null ? Timestamp.fromDate(meetingDateTime) : null;

 //Create meeting in senders collection
  await usersRef.doc(currentUserID.toString()).collection("meetings").doc(meetingID).set({
    "id": meetingID,

    "requested_by": requestedBy, ///The person requesting the meeting
    "requested_by_email": requestedByEmail,
    "wants_to_meet_with_email": meetingWithEmail,
    "requested_by_phone": requestedByPhone,
    "wants_to_meet_with_phone": meetingWithPhone,
    "requested_by_id": requestedByID, ///The person requesting the meeting
    "wants_to_meet_with": meetingWith, ///The person they want to meet with
    ///The person they want to meet with
    ///The person they want to meet with
    "wants_to_meet_with_id": otherUserID,
    "isAccepted": false,
    "isCancelled": false,
    "isDeclined": false,
    "isDefault": false,
    "date_requested": Timestamp.now(),
    "message": message,
    "tableSlot": tableSlot,
    "startTime": startTime,
    "meeting_time": meetingTime,


    "company": company,

  });

  ///Create meeting in other persons collection
  await usersRef
      .doc(otherUserID.toString())
      .collection("meetings")
      .doc(meetingID)
      .set({
    "id": meetingID,

    "requested_by": requestedBy,
    "requested_by_phone": requestedByPhone,
    "wants_to_meet_with_phone": meetingWithPhone,

    ///The person requesting the meeting
    "requested_by_id": requestedByID,

    ///The person requesting the meeting
    "wants_to_meet_with": meetingWith,
    "requested_by_email": requestedByEmail,
    "wants_to_meet_with_email": meetingWithEmail,

    ///The person they want to meet with
    "wants_to_meet_with_id": otherUserID,

    ///The person they want to meet with
    "isAccepted": false,
    "isCancelled": false,
    "isDeclined": false,
    "isDeleted": false,
    "date_requested": Timestamp.now(),
    "message": message,
    "startTime": startTime,
    "meeting_time": meetingTime,


    "company": company,
  });

  ActivityLogger.instance.log(
    action: ActivityAction.meetingRequestSent,
    userId: currentUserID,
    targetType: 'meeting',
    targetId: meetingID,
    metadata: {
      'meeting_with_id': otherUserID,
    },
  );

  print("Other persons ID is ${meetingWithI}");
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

launchMailClient(
    {required String emailAddress,
      required String subject,
      required String body}) async {
  Uri emailUri = Uri.parse(
      "mailto:$emailAddress?subject=${Uri.encodeFull(subject)}&body=${Uri.encodeFull(body)}");
  if (await canLaunchUrl(emailUri)) {
    await launchUrl(emailUri);
  } else {
    throw 'Could not launch $emailUri';
  }
}

Future<void> launchPhoneCall({required String phoneNumber}) async {
  final Uri phoneUri = Uri.parse('tel:$phoneNumber');
  if (await canLaunchUrl(phoneUri)) {
    await launchUrl(phoneUri);
  } else {
    throw 'Could not launch $phoneUri';
  }
}




class UserPointsService {


  // Method to create or update user_points
  Future<void> createOrUpdateUserPoints({required int userId, required int actionId}) async {
    try {
      // Step 1: Fetch action details to check required occurrences
      final actionResponse = await DioFetchService().getActionDetails(actionId: actionId);

      if (actionResponse.statusCode != 200) {
        throw Exception('Failed to fetch action details.');
      } else {
        print("Got action details");
      }

      final actionData = actionResponse.data['data'];
      final requiredOccurrences = actionData['required_occurrence'];
      final actionPoints = actionData['action_points'];  // Points for the action
      print("Required occurrences: $requiredOccurrences");

      // Step 2: Check if user_points entry exists
      final userPointsResponse = await DioFetchService().checkUserPoints(actionId: actionId, userId: userId);
      if (userPointsResponse.statusCode != 200) {
        throw Exception('Failed to fetch user points.');
      } else {
        print("Got user points");
      }

      final userPointsData = userPointsResponse.data['data'];

      if (userPointsData.isNotEmpty) {
        // Step 3: Update existing user_points record
        final userPointsId = userPointsData[0]['id'];
        final currentOccurrences = userPointsData[0]['occurences'];
        print("current occurences are $currentOccurrences");

        if (currentOccurrences < requiredOccurrences) {
          // Increment occurrences only if they haven't reached the required limit
          final updatedOccurrences = currentOccurrences + 1;

          // Update occurrences in the user_points entry
          await DioPostService().updateUserPoints(body: {
            'occurences': updatedOccurrences,
          }, userPointsId: userPointsId);

          // Award points only if the updated occurrences match the required occurrences
          if (updatedOccurrences == requiredOccurrences) {
            await DioPostService().updateUserPoints(body: {
              'points_awarded': actionPoints,  // Award the points once
            }, userPointsId: userPointsId);
            print("Points awarded for reaching required occurrences!");
          } else {
            print("Occurrences updated, but points not yet awarded.");
          }

        } else {
          print('Action already completed. Max occurrences reached.');
        }
      } else {
        // Step 4: Create new user_points entry
        print("Creating new user_points entry");
        await DioPostService().createUserPointsEntry(body: {
          'user_id': userId,
          'action_id': actionId,
          'occurences': 1,
          'points_awarded': (requiredOccurrences == 1) ? actionPoints : 0,  // Award points immediately if requiredOccurrences is 1
        });

        // If the action can be done only once, award points immediately
        if (requiredOccurrences == 1) {
          print("Points awarded for one-time action.");
        } else {
          print("Occurrences set to 1, points will be awarded after required occurrences.");
        }
      }
    } catch (error) {
      print('Error creating or updating user points: $error');
    }
  }

}

