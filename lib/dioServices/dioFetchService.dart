import 'package:dio/dio.dart';

import 'dioClient.dart';

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

}