import '../../../core/diagnostics/diagnostic_notifier.dart';
import '../models/dashboard_data.dart';
import '../repositories/dashboard_repository.dart';

class DashboardViewModel extends DiagnosticNotifier {
  DashboardViewModel(this.repository);
  final DashboardRepository repository;
  DashboardData? _data;
  bool _isLoading = false;
  String? _errorMessage;
  DashboardData? get data => _data;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _data != null && _data!.purchases.isEmpty;
  Future<void> ensureLoaded() async {
    if (_data == null && !_isLoading) await refresh();
  }

  Future<void> refresh() async {
    if (isDisposed || _isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final data = await repository.getDashboardData();
      if (!isDisposed) _data = data;
    } catch (_) {
      if (!isDisposed) {
        _errorMessage =
            'Unable to load the purchase overview. Please try again.';
      }
    } finally {
      if (!isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
}
