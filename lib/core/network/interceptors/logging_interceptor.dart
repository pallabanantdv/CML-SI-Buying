import 'dart:convert';

import 'package:dio/dio.dart';

import '../../diagnostics/app_diagnostics.dart';

/// Fail-closed logging: unknown scalar values are private business data.
/// Preserve payload structure and counts, never credentials or record values.
class SafeLoggingInterceptor extends Interceptor {
  SafeLoggingInterceptor({void Function(String)? sink})
    : _sink = sink ?? AppDiagnostics.write;
  final void Function(String) _sink;
  static int _sequence = 0;
  static const _id = 'caml.log.id';
  static const _clock = 'caml.log.clock';

  static Object? sanitize(Object? value) {
    if (value == null) return null;
    if (value is Map) {
      return {
        for (final entry in value.entries)
          entry.key.toString(): sanitize(entry.value),
      };
    }
    if (value is FormData) {
      return {
        'fields': {for (final entry in value.fields) entry.key: '[REDACTED]'},
        'files': '[REDACTED]',
      };
    }
    if (value is List) return value.map(sanitize).toList();
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map || decoded is List) return sanitize(decoded);
      } catch (_) {
        /* Opaque text is private. */
      }
    }
    return '[REDACTED]';
  }

  static String safeUrl(Uri uri) {
    final segments = uri.pathSegments;
    // Resource names and arbitrary method parameters can contain business data.
    final path = segments
        .asMap()
        .entries
        .map(
          (entry) =>
              entry.key >= 3 ? '[REDACTED]' : Uri.encodeComponent(entry.value),
        )
        .join('/');
    final query = {
      for (final key in uri.queryParameters.keys) key: '[REDACTED]',
    };
    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      path: '/$path',
      queryParameters: query.isEmpty ? null : query,
    ).toString();
  }

  void _emit(
    String event,
    RequestOptions request,
    Map<String, Object?> fields,
  ) {
    // A diagnostic sink must never change request completion or error handling.
    try {
      _sink(
        jsonEncode({
          'event': event,
          'requestId': request.extra[_id],
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'method': request.method,
          'url': safeUrl(request.uri),
          'durationMs':
              (request.extra[_clock] as Stopwatch?)?.elapsedMilliseconds,
          ...fields,
        }),
      );
    } catch (_) {
      /* Logging failures must not affect networking. */
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_id] = 'req-${++_sequence}';
    options.extra[_clock] = Stopwatch()..start();
    _emit('API REQUEST', options, {
      'query': sanitize(options.queryParameters),
      'headers': sanitize(options.headers),
      'body': sanitize(options.data),
      'timeoutsMs': {
        'connect': options.connectTimeout?.inMilliseconds,
        'send': options.sendTimeout?.inMilliseconds,
        'receive': options.receiveTimeout?.inMilliseconds,
      },
    });
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _emit('API RESPONSE', response.requestOptions, {
      'status': response.statusCode,
      'headers': sanitize(response.headers.map),
      'body': sanitize(response.data),
    });
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _emit('API ERROR', err.requestOptions, {
      'type': err.type.name, 'status': err.response?.statusCode,
      'message': sanitize(err.message), 'body': sanitize(err.response?.data),
      // Stack frames contain source locations; exception messages are omitted.
      'stack': err.stackTrace
          .toString()
          .split('\n')
          .where((line) => line.startsWith('#'))
          .take(20)
          .toList(),
    });
    handler.next(err);
  }
}
