import 'package:dio/dio.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:dx5veevents/dioServices/base_url.dart';

import 'dioClient.dart';
import 'endpoints/endpoint.dart';

class DioFetchService extends DioClient {
  DioClient _client = new DioClient();

  Future<Response> fetchCIOAttendees({required String eventID}) async {
    try {
      return await _client
          .init()
          .get("${BaseURL.Baseurl}/items/event_registrations?filter[eventId][_eq]=$eventID&filter[status][_eq]=approved&limit=2500",
     //   options: buildCacheOptions(const Duration(minutes: 30)),
           );
    } on DioError catch (ex) {
      throw Exception(ex);
    }
  }

  Future<Response> fetchCustomerEventsAttendees({required String eventID}) async {
    try {
      return await _client
          .init()
          .get("${BaseURL.Baseurl}/items/Customer_Event_Registrations?filter[eventID][_eq]=$eventID&filter[status][_eq]=approved&limit=800",
     //   options: buildCacheOptions(const Duration(minutes: 30)),
           );
    } on DioError catch (ex) {
      throw Exception(ex);
    }
  }

  Future<Response> fetchSingleAttendeeForEvent({required int id, required int eventID}) async {
    try {
      return await _client
          .init()
          .get("${BaseURL.Baseurl}/items/event_registrations?filter[attendeeId][_eq]=$id&filter[eventId][_eq]=$eventID",
        //   options: buildCacheOptions(const Duration(minutes: 30)),
      );
    } on DioError catch (ex) {
      throw Exception(ex);
    }
  }
 Future<Response> fetchSingleAttendeeFromAttendees({required int id,}) async {
    try {
      return await _client
          .init()
          .get("${BaseURL.Baseurl}/items/attendees?filter[id][_eq]=$id",
        //   options: buildCacheOptions(const Duration(minutes: 30)),
      );
    } on DioError catch (ex) {
      throw Exception(ex);
    }
  }


  Future<Response> fetchdx5veAgenda({required String eventID}) async {

    try {
      return await _client
          .init()
         // .get("${BaseURL.Baseurl}/items/agenda?filter[event_id][_eq]=$eventID",
          .get("${BaseURL.Baseurl}/items/agenda?filter[event_id][_eq]=$eventID",
        //options: buildCacheOptions(const Duration(minutes: 30)),
           );
    } on DioError catch (ex) {
      throw Exception(ex);
    }
  }

  Future<Response> fetchIndividualSessions({required String attendeeID}) async {

    try {
      return await _client
          .init()
         // .get("${BaseURL.Baseurl}/items/agenda?filter[event_id][_eq]=$eventID",
          .get("${BaseURL.Baseurl}/items/user_sessions?filter[attendee_id][_eq]=$attendeeID",
        //options: buildCacheOptions(const Duration(minutes: 30)),
           );
    } on DioError catch (ex) {
      throw Exception(ex);
    }
  }
  Future<Response> fetchEventSponsors() async {
    try {
      return await _client
          .init()
          .get("${BaseURL.Baseurl}/items/sponsors",
        options: buildCacheOptions(const Duration(minutes: 30)),
           );
    } on DioError catch (ex) {
      throw Exception(ex);
    }
  }
  Future<Response> fetchPresentationPDF({required String presentationURL}) async {
    try {
      return await _client
          .init()
          .get(presentationURL,
        options: buildCacheOptions(const Duration(minutes: 30)),
           );
    } on DioError catch (ex) {
      throw Exception(ex);
    }
  }

  Future<Response> fetchEventPartners() async {
    try {
      return await _client
          .init()
          .get("${BaseURL.Baseurl}/items/partners",
        options: buildCacheOptions(const Duration(minutes: 30)),
           );
    } on DioError catch (ex) {
      throw Exception(ex);
    }
  }


  Future<Response> fetchEvents({required String eventID}) async {
    try {
      return await _client
          .init()
          .get("${BaseURL.Baseurl}/items/events/$eventID",
        //options: buildCacheOptions(const Duration(minutes: 30)),
           );
    } on DioError catch (ex) {
      throw Exception(ex);
    }
  } Future<Response> fetchPresentation({required int eventID}) async {
    try {
      return await _client
          .init()
          .get("${BaseURL.Baseurl}/items/presentations?filter[event_id][_eq]=$eventID",
        //options: buildCacheOptions(const Duration(minutes: 30)),
           );
    } on DioError catch (ex) {
      throw Exception(ex);
    }
  }


  Future<Response> fetchLastMinuteCheckins({required int eventID}) async {
    try {
      return await _client
          .init()
          .get("${BaseURL.Baseurl}/items/last_minute_checkins?limit=500&filter[event_id][_eq]=$eventID",
        options: buildCacheOptions(const Duration(minutes: 2)),
           );
    } on DioError catch (ex) {
      throw Exception(ex);
    }
  }

  Future<Response> fetchSinglePost({required int postId}) async {
    try {
      return await _client
          .init()
          .get("${BaseURL.Baseurl}/items/Social/$postId",

           );
    } on DioError catch (ex) {
      throw Exception(ex);
    }
  }
  Future<Response> fetchCISOPartners() async {
    try {
      return await _client
          .init()
          .get("${BaseURL.Baseurl}/items/partners",
        options: buildCacheOptions(const Duration(minutes: 30)),
           );
    } on DioError catch (ex) {
      throw Exception(ex);
    }
  }

  Future<Response> fetchEventSpeakers() async {
    try {
      return await _client
          .init()
          .get("${BaseURL.Baseurl}/items/speakers",
        options: buildCacheOptions(const Duration(minutes: 30)),
           );
    } on DioError catch (ex) {
      throw Exception(ex);
    }
  }

  Future<Response> fetchEventSpeakerByKey({required int speakerKey}) async {
    try {
      return await _client
          .init()
          .get("${BaseURL.Baseurl}/items/speakers?filter[id][_eq]=$speakerKey",
      //  options: buildCacheOptions(const Duration(minutes: 30)),
           );
    } on DioError catch (ex) {
      throw Exception(ex);
    }
  }

  Future<Response> fetchCISOTopics() async {
    try {
      return await _client
          .init()
          .get("${BaseURL.Baseurl}/items/event_speaker_topics",
        options: buildCacheOptions(const Duration(minutes: 30)),
           );
    } on DioError catch (ex) {
      throw Exception(ex);
    }
  }

  Future<Response> fetchImage({required String id}) async {
    try {
      return await _client
          .init()
          .get("${ApiEndPoints.MEDIA_URL}/$id",
        options: buildCacheOptions(const Duration(minutes:30 )),
      );
    } on DioError catch (ex) {
      throw Exception(ex);
    }
  }

  Future<Response> getUserSessions() async {
    try {


      return await _client
          .init()
          .get(
        "${BaseURL.Baseurl}/items/user_sessions",
        // options: buildCacheOptions(const Duration(seconds: 30,),),

        // Set headers using the 'headers' parameter
      );
    } on DioError catch (ex) {
      throw Exception("Session fetch error: ${ex.response!.data!}");
    }
  }

  Future<Response> getActionDetails({required int actionId,}) async {
    try {


      return await _client
          .init()
          .get(
        "${BaseURL.Baseurl}/items/point_actions/$actionId",
        // options: buildCacheOptions(const Duration(seconds: 30,),),

        // Set headers using the 'headers' parameter
      );
    } on DioError catch (ex) {
      throw Exception("Action fetch error: ${ex.response!.data!}");
    }
  }


Future<Response> checkUserPoints({required int actionId, required int userId}) async {
    try {


      return await _client
          .init()
          .get(
        "${BaseURL.Baseurl}/items/user_points?filter[user_id][_eq]=$userId&filter[action_id][_eq]=$actionId",
        // options: buildCacheOptions(const Duration(seconds: 30,),),

        // Set headers using the 'headers' parameter
      );
    } on DioError catch (ex) {
      throw Exception("Session fetch error: ${ex.response!.data!}");
    }
  }

  Future<Response> getAllActions() async {
    try {


      return await _client
          .init()
          .get(
        "${BaseURL.Baseurl}/point_actions",
        // options: buildCacheOptions(const Duration(seconds: 30,),),

        // Set headers using the 'headers' parameter
      );
    } on DioError catch (ex) {
      throw Exception("Session fetch error: ${ex.response!.data!}");
    }
  }

  Future<Response> getUserPointsResponse({required int userId}) async {
    try {


      return await _client
          .init()
          .get(
        "${BaseURL.Baseurl}/items/user_points?filter[user_id][_eq]=$userId",
        // options: buildCacheOptions(const Duration(seconds: 30,),),

        // Set headers using the 'headers' parameter
      );
    } on DioError catch (ex) {
      throw Exception("Session fetch error: ${ex.response!.data!}");
    }
  }

  Future<Response> getAllUserPoints() async {
    try {


      return await _client
          .init()
          .get(
        "${BaseURL.Baseurl}/items/user_points",
        // options: buildCacheOptions(const Duration(seconds: 30,),),

        // Set headers using the 'headers' parameter
      );
    } on DioError catch (ex) {
      throw Exception("Session fetch error: ${ex.response!.data!}");
    }
  }
 Future<Response> fetchUserPoints({required int userID}) async {
    try {


      return await _client
          .init()
          .get(
        "${BaseURL.Baseurl}/items/user_points?filter[user_id][_eq]=$userID",
        // options: buildCacheOptions(const Duration(seconds: 30,),),

        // Set headers using the 'headers' parameter
      );
    } on DioError catch (ex) {
      throw Exception("Session fetch error: ${ex.response!.data!}");
    }
  }
 Future<Response> fetchSocialPosts() async {
    try {


      return await _client
          .init()
          .get(
        "${BaseURL.Baseurl}/items/Social",
        // options: buildCacheOptions(const Duration(seconds: 30,),),

        // Set headers using the 'headers' parameter
      );
    } on DioError catch (ex) {
      throw Exception("Session fetch error: ${ex.response!.data!}");
    }
  }




  Future<Response> updateUserData({required int recordid,required int eventId,required Map<String, dynamic> body}) async {



    return await _client
        .init()
        .patch(
     // "${BaseURL.Baseurl}/items/event_registrations?filter[attendeeId][_eq]=$id&filter[eventId][_eq]=$eventId",
      "${BaseURL.Baseurl}/items/event_registrations/$recordid",
      data: body,



      // Set headers using the 'headers' parameter
    );

  }

  // Future<Response> updateUserData({required int id,required int eventId,required Map<String, dynamic> body}) async {
  //
  //
  //
  //   return await _client
  //       .init()
  //       .patch(
  //     "${BaseURL.Baseurl}/items/checkins?filter[checkins_plain_format][_eq]=day1,day2,day3&filter[eventId][_eq]=21",
  //     data: body,
  //
  //
  //
  //     // Set headers using the 'headers' parameter
  //   );
  //
  // }

}