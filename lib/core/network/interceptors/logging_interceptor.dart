import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Logs HTTP request and response details in debug builds, with credentials
/// masked before anything is written to the console.
class SafeLoggingInterceptor extends Interceptor {
  static final _sensitiveKey = RegExp(
    r'(password|passwd|pwd|token|secret|authorization|cookie|session|api[_-]?key)',
    caseSensitive: false,
  );
  static final _sensitiveText = RegExp(
    r'((?:password|passwd|pwd|access_token|refresh_token|token|secret|authorization|cookie)\s*[:=]\s*)([^\s,;&}]+)',
    caseSensitive: false,
  );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['safeHttpLogStart'] = DateTime.now().microsecondsSinceEpoch;
    _debugLog(
      [
        '[HTTP] --> ${options.method} ${_urlWithoutQuery(options.uri)}',
        'Query: ${_format(options.queryParameters)}',
        'Headers: ${_format(options.headers)}',
        'Payload: ${_format(options.data)}',
      ].join('\n'),
    );
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final duration = _requestDuration(response.requestOptions);
    _debugLog(
      [
        '[HTTP] <-- ${response.statusCode} ${response.requestOptions.method} '
            '${_urlWithoutQuery(response.requestOptions.uri)}'
            '${duration == null ? '' : ' (${duration}ms)'}',
        'Response headers: ${_format(response.headers.map)}',
        'Response body: ${_format(response.data)}',
      ].join('\n'),
    );
    handler.next(response);
  }

  static void logError(DioException err) {
    final request = err.requestOptions;
    final duration = _requestDuration(request);
    _debugLog(
      [
        '[HTTP] ERROR type=${err.type.name} '
            'status=${err.response?.statusCode ?? 'none'} '
            '${request.method} ${_urlWithoutQuery(request.uri)}'
            '${duration == null ? '' : ' (${duration}ms)'}',
        'Query: ${_format(request.queryParameters)}',
        'Payload: ${_format(request.data)}',
        if (err.response != null)
          'Error response: ${_format(err.response?.data)}',
        'Error message: ${_redactText(err.message ?? err.type.name)}',
        if (err.error != null) 'Underlying error: ${_format(err.error)}',
      ].join('\n'),
    );
  }

  static String _urlWithoutQuery(Uri uri) {
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$port${uri.path}';
  }

  static int? _requestDuration(RequestOptions options) {
    final startedAt = options.extra['safeHttpLogStart'];
    if (startedAt is! int) return null;
    return (DateTime.now().microsecondsSinceEpoch - startedAt) ~/ 1000;
  }

  static String _format(Object? value) {
    final safeValue = _sanitize(value);
    try {
      return const JsonEncoder.withIndent('  ').convert(safeValue);
    } catch (_) {
      return _redactText(safeValue.toString());
    }
  }

  static Object? _sanitize(Object? value) {
    if (value is FormData) {
      return {
        'fields': {
          for (final field in value.fields)
            field.key: _sanitizeField(field.key, field.value),
        },
        'files': [
          for (final file in value.files)
            _sensitiveKey.hasMatch(file.key)
                ? {'field': file.key, 'file': '<redacted>'}
                : {
                    'field': file.key,
                    'fileName': file.value.filename,
                    'contentType': file.value.contentType?.mimeType,
                    'length': file.value.length,
                  },
        ],
      };
    }
    if (value is Map) {
      return {
        for (final entry in value.entries)
          entry.key.toString(): _sanitizeField(
            entry.key.toString(),
            entry.value,
          ),
      };
    }
    if (value is List<int>) return '<binary payload: ${value.length} bytes>';
    if (value is Iterable && value is! String) {
      return value.map(_sanitize).toList();
    }
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map || decoded is List) return _sanitize(decoded);
      } catch (_) {}
      return _redactText(value);
    }
    if (value is ResponseBody) return '<stream response>';
    return value;
  }

  static Object? _sanitizeField(String key, Object? value) =>
      _sensitiveKey.hasMatch(key) ? '<redacted>' : _sanitize(value);

  static String _redactText(String value) => value.replaceAllMapped(
    _sensitiveText,
    (match) => '${match[1]}<redacted>',
  );

  static void _debugLog(String message) {
    assert(() {
      debugPrint(message);
      return true;
    }());
  }
}
