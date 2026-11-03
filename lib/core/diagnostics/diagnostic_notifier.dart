import 'package:flutter/foundation.dart';

import 'app_diagnostics.dart';

abstract class DiagnosticNotifier extends ChangeNotifier {
  bool _disposed = false;
  bool get isDisposed => _disposed;

  @override
  void notifyListeners() {
    if (_disposed) return;
    if (AppDiagnostics.enabled) {
      AppDiagnostics.write(
        '[$runtimeType] notifyListeners listeners=$hasListeners',
      );
    }
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
