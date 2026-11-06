import 'dart:convert';

import 'package:dio/dio.dart';

import '../../errors/app_exception.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    final body = _decodeErrorBody(err.response?.data);
    final message = _frappeMessage(body) ?? _statusMessage(status, err.type);
    handler.reject(
      err.copyWith(
        error: AppException(
          message,
          statusCode: status,
          code: _stringValue(body, 'exc_type'),
          isAuthenticationError: status == 401,
        ),
      ),
    );
  }

  // PDF endpoints still return JSON when rendering or validation fails. Dio
  // keeps that JSON as bytes because the original request expects a PDF.
  static dynamic _decodeErrorBody(dynamic body) {
    try {
      if (body is List<int>) return jsonDecode(utf8.decode(body));
      if (body is String) return jsonDecode(body);
    } catch (_) {
      // Non-JSON error pages retain the normal HTTP status fallback.
    }
    return body;
  }

  static String? _frappeMessage(dynamic body) {
    if (body is! Map) return null;
    final direct = body['message'] ?? body['_error_message'];
    if (direct is String && direct.trim().isNotEmpty) return direct;
    final serverMessages = body['_server_messages'];
    if (serverMessages is String) {
      try {
        final decoded = jsonDecode(serverMessages);
        if (decoded is List && decoded.isNotEmpty) {
          final item = decoded.first;
          if (item is String) {
            final inner = jsonDecode(item);
            if (inner is Map && inner['message'] is String) {
              return inner['message'] as String;
            }
            return item;
          }
        }
      } catch (_) {}
    }
    // Some Frappe rendering errors omit _server_messages but include the
    // exception class and message. Do not expose the full server traceback.
    final exception = body['exception'];
    if (exception is String &&
        exception.trim().isNotEmpty &&
        !exception.contains('\n')) {
      return exception.trim();
    }
    return null;
  }

  static String? _stringValue(dynamic body, String key) =>
      body is Map && body[key] is String ? body[key] as String : null;

  static String _statusMessage(int? status, DioExceptionType type) {
    if (type == DioExceptionType.connectionTimeout ||
        type == DioExceptionType.sendTimeout ||
        type == DioExceptionType.receiveTimeout) {
      return 'The server took too long to respond.';
    }
    if (type == DioExceptionType.connectionError) {
      return 'Unable to connect. Check your internet connection.';
    }
    switch (status) {
      case 400:
        return 'The request could not be processed.';
      case 401:
        return 'Your session has expired. Please sign in again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'The requested record was not found.';
      case 409:
        return 'This record has changed. Refresh and try again.';
      case 417:
        return 'The server could not validate this request.';
      case 500:
        return 'The server encountered an error.';
      default:
        return 'Something went wrong while contacting the server.';
    }
  }
}
