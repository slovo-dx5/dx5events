import 'package:dio/dio.dart';
import 'package:dio_http_cache/dio_http_cache.dart';

import 'dioClient.dart';
import 'endpoints/endpoint.dart';

class DioFetchService extends DioClient {
  DioClient _client = new DioClient();

  Future<Response> fetchCIOAttendees({required String eventID}) async {
    try {
      return await _client
          .init()
          .get("https://subscriptions.cioafrica.co/items/event_registrations?filter[eventId][_eq]=$eventID&filter[status][_eq]=approved&limit=800",
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
          .get("https://subscriptions.cioafrica.co/items/Customer_Event_Registrations?filter[eventID][_eq]=$eventID&filter[status][_eq]=approved&limit=800",
     //   options: buildCacheOptions(const Duration(minutes: 30)),
           );
    } on DioError catch (ex) {
      throw Exception(ex);
    }
  }

  Future<Response> fetchSingleAttendee({required int id, required int eventID}) async {
    try {
      return await _client
          .init()
          .get("https://subscriptions.cioafrica.co/items/event_registrations?filter[attendeeId][_eq]=$id&filter[eventId][_eq]=$eventID",
        //   options: buildCacheOptions(const Duration(minutes: 30)),
      );
    } on DioError catch (ex) {
      throw Exception(ex);
    }
  }


  Future<Response> fetchdx5veAgenda({required String eventID}) async {
    int dodod=6;
    try {
      return await _client
          .init()
         // .get("https://subscriptions.cioafrica.co/items/agenda?filter[event_id][_eq]=$eventID",
          .get("https://subscriptions.cioafrica.co/items/agenda?filter[event_id][_eq]=$eventID",
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
         // .get("https://subscriptions.cioafrica.co/items/agenda?filter[event_id][_eq]=$eventID",
          .get("https://subscriptions.cioafrica.co/items/user_sessions?filter[attendee_id][_eq]=$attendeeID",
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
          .get("https://subscriptions.cioafrica.co/items/sponsors",
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
          .get("https://subscriptions.cioafrica.co/items/partners",
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
          .get("https://subscriptions.cioafrica.co/items/events/$eventID",
        //options: buildCacheOptions(const Duration(minutes: 30)),
           );
    } on DioError catch (ex) {
      throw Exception(ex);
    }
  }


  Future<Response> fetchLastMinuteCheckins() async {
    try {
      return await _client
          .init()
          .get("https://subscriptions.cioafrica.co/items/last_minute_checkins?limit=500",
        options: buildCacheOptions(const Duration(minutes: 2)),
           );
    } on DioError catch (ex) {
      throw Exception(ex);
    }
  }
  Future<Response> fetchCISOPartners() async {
    try {
      return await _client
          .init()
          .get("https://subscriptions.cioafrica.co/items/partners",
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
          .get("https://subscriptions.cioafrica.co/items/speakers",
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
          .get("https://subscriptions.cioafrica.co/items/speakers?filter[id][_eq]=$speakerKey",
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
          .get("https://subscriptions.cioafrica.co/items/event_speaker_topics",
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
        "https://subscriptions.cioafrica.co/items/user_sessions",
        // options: buildCacheOptions(const Duration(seconds: 30,),),

        // Set headers using the 'headers' parameter
      );
    } on DioError catch (ex) {
      throw Exception("Session fetch error: ${ex.response!.data!}");
    }
  }

  Future<Response> updateUserData({required int id,required Map<String, dynamic> body}) async {



    return await _client
        .init()
        .patch(
      "https://subscriptions.cioafrica.co/items/event_registrations/$id",
      data: body,



      // Set headers using the 'headers' parameter
    );

  }

}