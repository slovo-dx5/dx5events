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
          .get("https://subscriptions.cioafrica.co/items/event_registrations?limit=800",
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

}