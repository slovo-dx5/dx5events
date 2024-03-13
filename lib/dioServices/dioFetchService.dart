import 'package:dio/dio.dart';
import 'package:dio_http_cache/dio_http_cache.dart';

import 'dioClient.dart';
import 'endpoints/endpoint.dart';

class DioFetchService extends DioClient {
  DioClient _client = new DioClient();

  Future<Response> fetchCISOAttendees() async {
    try {
      return await _client
          .init()
          .get("https://subscriptions.cioafrica.co/items/event_registrations?filter[eventId][_eq]=3&filter[status][_eq]=approved&limit=800",
     //   options: buildCacheOptions(const Duration(minutes: 30)),
           );
    } on DioError catch (ex) {
      throw Exception(ex);
    }
  }


  Future<Response> fetchCISOAgenda() async {
    try {
      return await _client
          .init()
          .get("https://subscriptions.cioafrica.co/items/agenda/1",
        options: buildCacheOptions(const Duration(minutes: 30)),
           );
    } on DioError catch (ex) {
      throw Exception(ex);
    }
  }
  Future<Response> fetchCISOSponsors() async {
    try {
      return await _client
          .init()
          .get("https://subscriptions.cioafrica.co/items/sponsors",
        //options: buildCacheOptions(const Duration(minutes: 30)),
           );
    } on DioError catch (ex) {
      throw Exception(ex);
    }
  }

  Future<Response> fetchCISOSpeakers() async {
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