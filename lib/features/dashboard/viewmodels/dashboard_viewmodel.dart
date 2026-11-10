import '../../../core/diagnostics/diagnostic_notifier.dart';
import '../models/dashboard_data.dart';
import '../repositories/dashboard_repository.dart';

class DashboardViewModel extends DiagnosticNotifier {
  DashboardViewModel(this.repository);
  final DashboardRepository repository;
  DashboardData? _data;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _fromDate, _toDate;
  DashboardData? get data => _data;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _data != null && _data!.summary.transactionCount == 0;
  Future<void> setDateRange(DateTime? from, DateTime? to) async {
    if (_isLoading) return;
    _fromDate = from;
    _toDate = to;
    await refresh();
  }

  Future<void> ensureLoaded() async {
    if (_data == null && !_isLoading) await refresh();
  }

  Future<void> refresh() async {
    if (isDisposed || _isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final source = repository;
      final data =
          source is DateFilteredDashboardRepository &&
              _fromDate != null &&
              _toDate != null
          ? await source.getDashboardDataForRange(_fromDate!, _toDate!)
          : await source.getDashboardData();
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
