import 'package:dio/dio.dart';

/// Logs request metadata only. Bodies and credential-bearing headers are omitted.
class SafeLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    assert(() {
      // Avoid logging query values, bodies, cookies, or authorization headers.
      // ignore: avoid_print
      print('[HTTP] ${options.method} ${options.uri.path}');
      return true;
    }());
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    assert(() {
      // ignore: avoid_print
      print(
        '[HTTP] ${response.statusCode} ${response.requestOptions.uri.path}',
      );
      return true;
    }());
    handler.next(response);
  }
}
