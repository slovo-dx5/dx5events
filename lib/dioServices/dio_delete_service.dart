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

  // ---- Revamped social feature (normalized collections) --------------------

  Future<Response> deleteReaction({required int reactionId}) async {
    try {
      return await _client.init().delete("${BaseURL.Baseurl}/items/post_reactions/$reactionId");
    } on DioError catch (ex) {
      throw Exception("Reaction delete error: ${ex.response!.data!}");
    }
  }

  Future<Response> deleteComment({required int commentId}) async {
    try {
      return await _client.init().delete("${BaseURL.Baseurl}/items/post_comments/$commentId");
    } on DioError catch (ex) {
      throw Exception("Comment delete error: ${ex.response!.data!}");
    }
  }

  Future<Response> deleteBlock({required int blockId}) async {
    try {
      return await _client.init().delete("${BaseURL.Baseurl}/items/user_blocks/$blockId");
    } on DioError catch (ex) {
      throw Exception("Block delete error: ${ex.response!.data!}");
    }
  }

  Future<Response> deletePost({required int postId}) async {
    try {
      return await _client.init().delete("${BaseURL.Baseurl}/items/Social/$postId");
    } on DioError catch (ex) {
      throw Exception("Post delete error: ${ex.response!.data!}");
    }
  }
}

