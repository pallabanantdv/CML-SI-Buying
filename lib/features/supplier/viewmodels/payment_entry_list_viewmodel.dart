import '../../../core/diagnostics/diagnostic_notifier.dart';
import '../../../core/errors/app_exception.dart';
import '../repositories/supplier_payment_repository.dart';

class PaymentEntryListViewModel extends DiagnosticNotifier {
  PaymentEntryListViewModel(this.repository);
  final SupplierPaymentRepository repository;
  List<Map<String, dynamic>> records = [];
  int? status;
  bool loading = false, loadingMore = false, hasMore = false;
  String? error, submittingName;
  int _request = 0;
  int _offset = 0;

  Future<void> load({bool more = false}) async {
    if (isDisposed ||
        submittingName != null ||
        (more && (loading || loadingMore || !hasMore))) {
      return;
    }
    final request = ++_request;
    if (more) {
      loadingMore = true;
    } else {
      loading = true;
      loadingMore = false;
    }
    error = null;
    notifyListeners();
    try {
      final rows = await repository.entries(
        offset: more ? _offset : 0,
        status: status,
      );
      if (isDisposed || request != _request) return;
      records = more
          ? [
              ...records,
              ...rows.where(
                (row) =>
                    !records.any((existing) => existing['name'] == row['name']),
              ),
            ]
          : rows;
      _offset = (more ? _offset : 0) + rows.length;
      hasMore = rows.length == SupplierPaymentRepository.pageSize;
    } catch (e) {
      if (!isDisposed && request == _request) {
        error = e is AppException
            ? e.message
            : 'Unable to load payment entries. Please retry.';
      }
    } finally {
      if (!isDisposed && request == _request) {
        loading = false;
        loadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> filter(int? value) async {
    if (submittingName != null || value == status) return;
    status = value;
    records = [];
    hasMore = false;
    _offset = 0;
    await load();
  }

  Future<bool> submit(String name) async {
    if (isDisposed || loading || loadingMore || submittingName != null) {
      return false;
    }
    final record = records.where((row) => row['name'] == name).firstOrNull;
    if (record == null || int.tryParse('${record['docstatus']}') != 0) {
      return false;
    }
    submittingName = name;
    error = null;
    ++_request;
    notifyListeners();
    try {
      final updated = await repository.submit(name);
      if (isDisposed) return false;
      // Apply only the confirmed server result; no speculative status changes.
      records = [
        for (final row in records)
          if (row['name'] != name)
            row
          else if (status == null || status == 1)
            {...row, ...updated},
      ];
      if (status == 0 && _offset > 0) _offset--;
      return true;
    } catch (e) {
      if (!isDisposed) {
        error = e is AppException
            ? e.message
            : 'Unable to confirm submission. Refresh before trying again.';
      }
      return false;
    } finally {
      if (!isDisposed) {
        submittingName = null;
        notifyListeners();
      }
    }
  }
}
