

import 'package:dio/dio.dart';


import 'dioClient.dart';

import 'endpoints/endpoint.dart';

class DioOTPService extends DioClient {
  final DioOTPClient _otpclient =  DioOTPClient();

  Future<Response> generateOTP( Map<String, dynamic> body) async {

    return await _otpclient.init().post(
        ApiEndPoints.GENERATE_OTP_URL,
        data: body);

  }

  Future<Response> updateOTP( Map<String, dynamic> body) async {
    try {
      return await _otpclient.init().patch(
          ApiEndPoints.UPDATE_OTP_URL,
          data: body);
    } on DioError catch (ex) {
      throw Exception(ex);
    }
  }

  Future<Response> verifyOTP({required String email, required String otp}) async {

    return await _otpclient
        .init()
        .get(ApiEndPoints.VERIFY_OTP_URL,
        queryParameters: {"email":email,"otp":otp}

    );

  }


}
