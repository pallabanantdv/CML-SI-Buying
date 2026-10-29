import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

import '../../config/constants/app_constants.dart';
import '../../config/environment/app_environment.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

class DioClient {
  DioClient({
    Dio? dio,
    CookieJar? cookieJar,
    Future<void> Function()? onUnauthorized,
  }) : dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: AppEnvironment.frappeBaseUrl,
               connectTimeout: AppConstants.connectTimeout,
               sendTimeout: AppConstants.connectTimeout,
               receiveTimeout: AppConstants.receiveTimeout,
               headers: const {'Accept': 'application/json'},
               contentType: Headers.jsonContentType,
             ),
           ) {
    if (cookieJar != null) this.dio.interceptors.add(CookieManager(cookieJar));
    this.dio.interceptors.addAll([
      ErrorInterceptor(),
      AuthInterceptor(onUnauthorized: onUnauthorized),
    ]);
    assert(() {
      this.dio.interceptors.add(SafeLoggingInterceptor());
      return true;
    }());
  }
  final Dio dio;
}
