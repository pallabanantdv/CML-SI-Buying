import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

class ConnectivityService extends ChangeNotifier with WidgetsBindingObserver {
  bool offline = false;
  bool refreshFailed = false;
  bool hasNetwork = true;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _debounce;
  Timer? _retry;
  bool _foreground = true;
  VoidCallback? onReconnect;
  Future<void> initialize() async {
    WidgetsBinding.instance.addObserver(this);
    _retry = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_foreground && hasNetwork && offline) onReconnect?.call();
    });
    _subscription = Connectivity().onConnectivityChanged.listen(_changed);
    try {
      final values = await Connectivity().checkConnectivity();
      hasNetwork = values.any((v) => v != ConnectivityResult.none);
      offline = !hasNetwork;
    } catch (_) {
      /* Requests still detect network failures. */
    }
  }

  Future<void> check() async {
    try {
      _changed(await Connectivity().checkConnectivity());
    } catch (_) {
      /* Dio remains authoritative if platform detection is unavailable. */
    }
  }

  void _changed(List<ConnectivityResult> values) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      final available = values.any((v) => v != ConnectivityResult.none);
      final recovered = available && (!hasNetwork || offline);
      hasNetwork = available;
      if (!available) offline = true;
      notifyListeners();
      if (recovered) onReconnect?.call();
    });
  }

  void success() {
    if (!offline && !refreshFailed) return;
    offline = !hasNetwork;
    refreshFailed = false;
    notifyListeners();
  }

  void reportRefreshFailure() {
    refreshFailed = true;
    notifyListeners();
  }

  void failure(DioException error, {bool isRefresh = true}) {
    if (error.response == null && error.type != DioExceptionType.cancel) {
      offline = true;
    }
    if (error.response != null) offline = !hasNetwork;
    if (isRefresh) refreshFailed = true;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (state == AppLifecycleState.resumed) {
      unawaited(check());
      onReconnect?.call();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _debounce?.cancel();
    _retry?.cancel();
    super.dispose();
  }
}
