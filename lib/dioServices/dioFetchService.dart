import 'package:dio/dio.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:dx5veevents/dioServices/base_url.dart';

import 'dioClient.dart';
import 'endpoints/endpoint.dart';

class DioFetchService extends DioClient {
  final DioClient _client =  DioClient();

  // Future<Response> fetchCIOAttendees({required String eventID}) async {
  //   try {
  //     return await _client
  //         .init()
  //         .get("${BaseURL.Baseurl}/items/event_registrations?filter[eventId][_eq]=$eventID&filter[status][_eq]=approved&limit=2500",
  //    //   options: buildCacheOptions(const Duration(minutes: 30)),
  //          );
  //   } on DioError catch (ex) {
  //     throw Exception(ex);
  //   }
  // }
  Future<Response> fetchCIOAttendees({
    required String eventID,
    int page = 1,
    int pageSize = 20,
    String searchQuery = '',
  }) async {
    try {
      // Calculate offset based on page and pageSize
      final int offset = (page - 1) * pageSize;

      // Start with base filters
    //  String filterParams = "&filter[eventId][_eq]=$eventID&filter[status][_eq]=approved";
      String filterParams = "&filter[eventId][_eq]=$eventID";

      // Add search query if provided
      if (searchQuery.isNotEmpty) {
        // Add OR conditions for search across multiple fields
        filterParams += "&filter[_or][0][first_name][_contains]=$searchQuery";
        filterParams += "&filter[_or][1][last_name][_contains]=$searchQuery";
        filterParams += "&filter[_or][2][role][_contains]=$searchQuery";
        filterParams += "&filter[_or][3][company][_contains]=$searchQuery";
      }

      // Build final URL with pagination and filters
      final String url =
          "${BaseURL.Baseurl}/items/event_registrations?limit=$pageSize&offset=$offset$filterParams";

      // Construct cache options with appropriate keys and TTL
      final Options cacheOptions = buildCacheOptions(
        const Duration(minutes: 30),
        maxStale: const Duration(days: 1),
        // Include pagination and search parameters in the cache key for proper caching
        primaryKey: 'event_attendees_${eventID}_${page}_${pageSize}_${searchQuery.isEmpty ? "no_search" : searchQuery}',
      );

      return await _client.init().get(
        url,
        options: cacheOptions,
      );
    } on DioError catch (ex) {
      // Consider more specific error handling for different error types
      if (ex.type == DioErrorType.connectTimeout ||
          ex.type == DioErrorType.receiveTimeout) {
        throw Exception("Connection timeout. Please check your internet connection.");
      } else if (ex.response != null) {
        throw Exception("Server returned status code ${ex.response?.statusCode}");
      }
      throw Exception("Failed to fetch attendees: ${ex.message}");
    }
  }
  Future<Response> fetchAllCIOAttendees({required String eventID}) async {
    try {
      return await _client
          .init()
          .get("${BaseURL.Baseurl}/items/event_registrations?filter[eventId][_eq]=$eventID&limit=2500",
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
          .get("${BaseURL.Baseurl}/items/event_Registrations?filter[eventID][_eq]=$eventID&filter[status][_eq]=approved&limit=4000",
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
  Future<Response> fetchAppSponsor() async {
    try {
      return await _client
          .init()
          .get("${BaseURL.Baseurl}/items/sponsor_contact",
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
          .get("${BaseURL.Baseurl}/items/sponsors?limit=500",

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
          .get("${BaseURL.Baseurl}/items/last_minute_checkins?limit=2000&filter[event_id][_eq]=$eventID",
        options: buildCacheOptions(const Duration(minutes: 2)),
           );
    } on DioError catch (ex) {
      throw Exception(ex);
    }
  }
  Future<Response> fetchLastMinuteRooms({required int eventID,required String existingRoom}) async {
    try {
      return await _client
          .init()
          .get("${BaseURL.Baseurl}/items/last_minute_checkins?limit=2000&filter[event_id][_eq]=$eventID&filter[room_name][_eq]=$existingRoom",
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

  Future<Response> fetchSpeakersByIds(List<int> ids) async {
    final idList = ids.join(',');
    try {
      return await _client
          .init()
          .get("${BaseURL.Baseurl}/items/speakers?filter[id][_in]=$idList&limit=-1");
    } on DioError catch (ex) {
      throw Exception(ex);
    }
  }

  Future<Response> fetchSponsorsByIds(List<int> ids) async {
    final idList = ids.join(',');
    try {
      return await _client
          .init()
          .get("${BaseURL.Baseurl}/items/sponsors?filter[id][_in]=$idList&limit=-1");
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




  /// Bulk-inserts activity log rows into `app_activity_logs`.
  /// Directus accepts an array body for batched creation.
  /// DioError is rethrown unwrapped so the caller can inspect response.data
  /// (e.g. RECORD_NOT_UNIQUE for idempotency handling).
  Future<Response> postActivityLogs(List<Map<String, dynamic>> rows) {
    return _client
        .init()
        .post("${BaseURL.Baseurl}/items/app_activity_logs", data: rows);
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