import "package:dio/dio.dart";
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'base_url.dart';


class DioClient {
  Dio init() {
    Dio _dio = new Dio();
    // _dio.interceptors.add(PrettyDioLogger(
    //   requestHeader: true,
    //   requestBody: true,
    // ));
    //
    _dio.transformer as DefaultTransformer; //.jsonDecodeCallback = parseJson;
    _dio.options.headers["Authorization"] = "Bearer oEgjgIbG1oyqMKscjSsQLfPznOaOUzW7";



    return _dio;
  }
}

class DioOTPClient {
  Dio init() {
    Dio _dio =  Dio();
    //  _dio.interceptors.add(new ApiInterceptors());


    _dio.transformer as DefaultTransformer; //.jsonDecodeCallback = parseJson;
   _dio.options.baseUrl = BaseURL.OTPBaseurl;
    // _dio.options.headers["Authorization"] = "Bearer oEgjgIbG1oyqMKscjSsQLfPznOaOUzW7";



    return _dio;
  }
}
