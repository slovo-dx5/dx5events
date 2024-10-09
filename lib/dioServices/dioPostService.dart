import 'package:flutter/material.dart';

import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../constants.dart';
import 'dioClient.dart';

class DioPostService extends DioClient {
  DioClient _client = new DioClient();
  final baseURL="https://subscriptions.cioafrica.co/items/";

  Future<Response> createSession({required Map<String, dynamic> sessionBody}) async {
    print("session bosy is $sessionBody");
    try {
      return await _client
          .init()
          .post("https://subscriptions.cioafrica.co/items/user_sessions",
        data: sessionBody,);
    }  on DioError catch (ex) {
      throw Exception("Session create error: ${ex.response!.data!}");
    }
  }

  Future<Response> createSponsorSubmission({required Map<String, dynamic> sessionBody}) async {
    try {
      return await _client
          .init()
          .post("https://subscriptions.cioafrica.co/items/sponsor_registrations",
        data: sessionBody,);
    }  on DioError catch (ex) {
      throw Exception("Session create error: ${ex.response!.data!}");
    }
  }


  Future<Response> createProposal({required Map<String, dynamic> proposalBody}) async {
    try {
      return await _client
          .init()
          .post("https://speakerapi.cioafrica.co/speakers/app",
        data: proposalBody,);
    }  on DioError catch (ex) {
      throw Exception("Proposal create error: ${ex.response!.data!}");
    }
  }

  Future<Response> uploadProfilePic(formData) async {
    try{
      return await _client
          .init()
          .post("https://subscriptions.cioafrica.co/files",
          data: formData,
          options: Options(headers: {
            'Content-Type': 'multipart/form-data',
          })

        // Set headers using the 'headers' parameter
      );
    }on DioError catch (ex) {
      throw Exception("Session create error: ${ex.response!.data!}");
    }
  }

  Future<Response> sendNotification(messageData) async {
    try{
      return await _client
          .init()
          .post("https://fcm.googleapis.com/fcm/send",
          data: messageData,
          options: Options(headers: {
            'Authorization': 'Bearer AAAAQrAxy0I:APA91bGrDqULJNq_hEZtUIgmv-gJfxXcgaDLCHCACiPqWablKBu-vy0qscT_raEr4C3dEtQQX2m1ocAYCjTm9po3mjaPMUeNN21ffeIXAz1afO_XE2k1chbSoe3iUv0Pd0Y3ry2SQDnd',
          })

        // Set headers using the 'headers' parameter
      );

    }on DioError catch (ex) {
      throw Exception("Notification create error: ${ex.response!.data!}");
    }
  }


  Future<Response> createFilteredCheckin(messageData) async {
    try{
      print("sending notif");
      return await _client
          .init()
          .post("https://subscriptions.cioafrica.co/items/filtered_chekins",
          data: messageData,
          options: Options(headers: {
            'Authorization': 'Bearer AAAAQrAxy0I:APA91bGrDqULJNq_hEZtUIgmv-gJfxXcgaDLCHCACiPqWablKBu-vy0qscT_raEr4C3dEtQQX2m1ocAYCjTm9po3mjaPMUeNN21ffeIXAz1afO_XE2k1chbSoe3iUv0Pd0Y3ry2SQDnd',
          })

        // Set headers using the 'headers' parameter
      );

    }on DioError catch (ex) {
      throw Exception("Notification create error: ${ex.response!.data!}");
    }
  }

  Future<Response> postSponsorData({required Map<String, dynamic> body,required BuildContext context}) async {
    try{
      return await _client
          .init()
          .post("https://subscriptions.cioafrica.co/items/sponsordata",
        data: body,


        // Set headers using the 'headers' parameter
      );
    }on DioError catch (ex) {
      Fluttertoast.showToast(backgroundColor:kLogoutRed,msg: "Error: Check your internet connection");
      Future.delayed(Duration(seconds: 2),(){Navigator.of(context).pop();});
      throw Exception("Sponsor data create error: ${ex.response!.data!}");
    }
  }

  Future<Response> postCheckinData({required Map<String, dynamic> body,required BuildContext context}) async {
    try{
      return await _client
          .init()
          .post("https://directcheckin.cioafrica.co/checkinPrintBadgeUsingApp",
        data: body,


        // Set headers using the 'headers' parameter
      );
    }on DioError catch (ex) {
      Fluttertoast.showToast(backgroundColor:kLogoutRed,msg: "Error: Check your internet connection");
      Future.delayed(const Duration(seconds: 2),(){Navigator.of(context).pop();});


      throw Exception("Checkin data create error: ${ex.response!.data!}");
    }
  }




  Future<Response> sendBroadcast({required Map<String, dynamic> body,required String accessToken,}) async {
    try{
      return await _client
          .init()
          .post("https://fcm.googleapis.com/v1/projects/dx5ve-events/messages:send",
        data: body,
          options: Options(headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + accessToken
          })



        // Set headers using the 'headers' parameter
      );
    }on DioError catch (ex) {
      Fluttertoast.showToast(backgroundColor:kLogoutRed,msg: "Error: Check your internet connection");


      throw Exception("Send broadcast error: ${ex.response!.data!}");
    }
  }

  ///This function is incharge of uploading attendee details for customer events from a CSV file
  Future<Response> postCustomerInfo({required Map<String, dynamic> body,required BuildContext context}) async {
    try{
      return await _client
          .init()
          .post("https://subscriptions.cioafrica.co/items/Customer_Event_Registrations",
        data: body,


        // Set headers using the 'headers' parameter
      );
    }on DioError catch (ex) {
      Fluttertoast.showToast(backgroundColor:kLogoutRed,msg: "Error: Check your internet connection");
      Future.delayed(const Duration(seconds: 2),(){Navigator.of(context).pop();});


      throw Exception("Checkin data create error: ${ex.response!.data!}");
    }
  }

  Future<Response> postSessionRating({required BuildContext context,

    required int attendeeID,
    required int speakerRating,
    required int sessionRating,
    required String sessionComment,
    required String speakerName,
    required String sessionTitle,
    required String speakerComment,

  }) async {
    try{
      return await _client
          .init()
          .post("https://subscriptions.cioafrica.co/items/Session_Rating",
        data: {
            "attendeeID":attendeeID,
            "sessionTitle":sessionTitle,
            "sessionComment":sessionComment,
            "sessionRating":sessionRating,
            "speakerRating":speakerRating,
            "speakerName":speakerName,
            "speakerComment":speakerComment,
        },


        // Set headers using the 'headers' parameter
      );

    }on DioError catch (ex) {
      Fluttertoast.showToast(backgroundColor:kLogoutRed,msg: "Error: Check your internet connection");
      Future.delayed(const Duration(seconds: 2),(){Navigator.of(context).pop();});


      throw Exception("Checkin data create error: ${ex.response!.data!}");
    }
  }

  Future<Response> postCustomerSpeakerInfo({required Map<String, dynamic> body,required BuildContext context}) async {
    try{
      return await _client
          .init()
          .post("https://subscriptions.cioafrica.co/items/speakers",
        data: body,


        // Set headers using the 'headers' parameter
      );
    }on DioError catch (ex) {
      Fluttertoast.showToast(backgroundColor:kLogoutRed,msg: "Error: Check your internet connection");
      Future.delayed(const Duration(seconds: 2),(){Navigator.of(context).pop();});


      throw Exception("Checkin data create error: ${ex.response!.data!}");
    }
  }
  Future<Response> postCheckinDataFiltered({required Map<String, dynamic> body,required BuildContext context,}) async {
    try{
      return await _client
          .init()
          .post("https://subscriptions.cioafrica.co/items/filtered_chekins",
        data: body,


        // Set headers using the 'headers' parameter
      );
    }on DioError catch (ex) {
      Fluttertoast.showToast(backgroundColor:kLogoutRed,msg: "Error: Check your internet connection");
      Future.delayed(const Duration(seconds: 2),(){Navigator.of(context).pop();});


      throw Exception("Checkin data create error: ${ex.response!.data!}");
    }
  }







  Future<Response> sendCheckInOTP({required Map<String, dynamic> body}) async {
    try{
      return await _client
          .init()
          .post("https://otpapi.cioafrica.co/create-otp-slovo",
        data: body,


        // Set headers using the 'headers' parameter
      );
    } catch (ex) {

      Fluttertoast.showToast(msg: "Error: Check your internet");
      throw Exception("Sponsor data create error: ${ex}");
    }

  }



  //
  // Future<void> logUserAction({
  //   required int userId,
  //   required int actionId,
  // }) async {
  //   final String userPointsUrl = '$baseURL/items/user_points';
  //   final String actionUrl = '$baseURL/items/point_actions/$actionId';
  //
  //   try {
  //     // Get action details
  //     final actionResponse = await http.get(
  //       Uri.parse(actionUrl),
  //       headers: {'Authorization': 'Bearer $apiToken', 'Content-Type': 'application/json'},
  //     );
  //     final actionData = jsonDecode(actionResponse.body)['data'];
  //
  //     // Get the user's action performance data
  //     final userPointsResponse = await http.get(
  //       Uri.parse('$userPointsUrl?filter[user_id][_eq]=$userId&filter[action_id][_eq]=$actionId'),
  //       headers: {'Authorization': 'Bearer $apiToken', 'Content-Type': 'application/json'},
  //     );
  //     final userPointsData = jsonDecode(userPointsResponse.body)['data'];
  //
  //     int occurrences = userPointsData.isNotEmpty ? userPointsData[0]['occurrences'] : 0;
  //
  //     // Increment occurrences since the user performed the action
  //     occurrences++;
  //
  //     // Check if occurrences meet or exceed the required occurrences
  //     if (occurrences >= actionData['required_occurrences']) {
  //       // Award points and update points_awarded flag
  //       await http.patch(
  //         Uri.parse('$userPointsUrl/${userPointsData[0]['id']}'),
  //         headers: {'Authorization': 'Bearer $apiToken', 'Content-Type': 'application/json'},
  //         body: jsonEncode({
  //           'occurrences': occurrences,
  //           'points_awarded': true,
  //           'last_performed_at': DateTime.now().toIso8601String(),
  //         }),
  //       );
  //       print('Points awarded!');
  //     } else {
  //       // Just increment occurrences
  //       await http.patch(
  //         Uri.parse('$userPointsUrl/${userPointsData[0]['id']}'),
  //         headers: {'Authorization': 'Bearer $apiToken', 'Content-Type': 'application/json'},
  //         body: jsonEncode({
  //           'occurrences': occurrences,
  //           'last_performed_at': DateTime.now().toIso8601String(),
  //         }),
  //       );
  //       print('Action logged but not enough occurrences for points.');
  //     }
  //   } catch (error) {
  //     print('Error logging user action: $error');
  //   }
  // }
}







