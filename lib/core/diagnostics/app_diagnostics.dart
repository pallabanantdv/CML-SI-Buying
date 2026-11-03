import 'package:flutter/foundation.dart';

const enableApiLogs = bool.fromEnvironment(
  'ENABLE_API_LOGS',
  defaultValue: false,
);

abstract final class AppDiagnostics {
  static const enabled = kDebugMode || enableApiLogs;

  // debugPrint itself works in release too. No assert gate or throttled queue.
  static void write(String message) {
    if (!enabled) return;
    for (final line in message.split('\n')) {
      for (var offset = 0; offset < line.length; offset += 700) {
        debugPrintSynchronously(
          '[CAML] ${line.substring(offset, (offset + 700).clamp(0, line.length))}',
        );
      }
    }
  }
}
