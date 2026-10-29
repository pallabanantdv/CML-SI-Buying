import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../models/dashboard_model.dart';
import '../repositories/dashboard_repository.dart';

class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel(this._repository);
  final DashboardRepository _repository;
  DashboardModel? _dashboard;
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;
  DashboardModel? get dashboard => _dashboard;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Future<void> loadDashboard() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    _notify();
    try {
      _dashboard = await _repository.load();
    } on AppException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load dashboard data.';
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
