import 'package:dio/dio.dart';

import 'base_url.dart';
import 'dioClient.dart';

class DioDeleteService extends DioClient {
  final DioClient _client =  DioClient();




  Future<Response> deleteUserSession({required int sessionID}) async {
    try {


      return await _client
          .init()
          .delete(
        "${BaseURL.Baseurl}/items/user_sessions/$sessionID",
        // options: buildCacheOptions(const Duration(seconds: 30,),),

        // Set headers using the 'headers' parameter
      );
    } on DioError catch (ex) {
      throw Exception("Session delete error: ${ex.response!.data!}");
    }
  }




}

