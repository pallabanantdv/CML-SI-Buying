import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({this.onUnauthorized});
  final Future<void> Function()? onUnauthorized;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) onUnauthorized?.call();
    handler.next(err);
  }
}
