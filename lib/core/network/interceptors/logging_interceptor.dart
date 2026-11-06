import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../diagnostics/app_diagnostics.dart';

/// Log business values while masking authentication secrets.
class SafeLoggingInterceptor extends Interceptor {
  SafeLoggingInterceptor({void Function(String)? sink})
    : _sink = sink ?? AppDiagnostics.write;
  final void Function(String) _sink;
  static int _sequence = 0;
  static const _id = 'caml.log.id';
  static const _clock = 'caml.log.clock';
  static bool _isSecret(String key) => RegExp(
    r'password|passwd|secret|token|cookie|authorization|api[_-]?key|session[_-]?id|^sid$|^pwd$',
    caseSensitive: false,
  ).hasMatch(key);

  static Object? sanitize(Object? value) {
    if (value == null) return null;
    if (value is Uint8List) {
      try {
        return sanitize(jsonDecode(utf8.decode(value)));
      } catch (_) {
        return {'binaryBytes': value.length};
      }
    }
    if (value is Map) {
      return {
        for (final entry in value.entries)
          entry.key.toString(): _isSecret(entry.key.toString())
              ? '[REDACTED]'
              : sanitize(entry.value),
      };
    }
    if (value is FormData) {
      return {
        'fields': {
          for (final entry in value.fields)
            entry.key: _isSecret(entry.key)
                ? '[REDACTED]'
                : sanitize(entry.value),
        },
        'files': '[REDACTED]',
      };
    }
    if (value is List) return value.map(sanitize).toList();
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map || decoded is List) return sanitize(decoded);
      } catch (_) {
        /* Ordinary text is logged as received. */
      }
    }
    return value;
  }

  static String safeUrl(Uri uri) {
    final query = {
      for (final entry in uri.queryParametersAll.entries)
        entry.key: _isSecret(entry.key)
            ? ['[REDACTED]']
            : entry.value.map((value) {
                final sanitized = sanitize(value);
                return sanitized is String ? sanitized : jsonEncode(sanitized);
              }).toList(),
    };
    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      path: uri.path,
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
