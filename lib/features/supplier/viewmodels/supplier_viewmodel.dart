import '../../../core/diagnostics/app_diagnostics.dart';
import '../../../core/diagnostics/diagnostic_notifier.dart';
import '../../../core/errors/app_exception.dart';
import '../models/supplier_model.dart';
import '../repositories/supplier_repository.dart';

class SupplierViewModel extends DiagnosticNotifier {
  SupplierViewModel(this.repository);

  final SupplierRepository repository;

  List<SupplierModel> _suppliers = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String _searchQuery = '';

  String get title => 'Suppliers';
  List<SupplierModel> get suppliers => _suppliers;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  List<SupplierModel> get filteredSuppliers {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _suppliers;
    return _suppliers
        .where((supplier) {
          final searchable = [
            supplier.name,
            supplier.id,
            supplier.group,
            supplier.type,
            supplier.location,
            supplier.phone,
            supplier.email,
          ].whereType<String>().join(' ').toLowerCase();
          return searchable.contains(query);
        })
        .toList(growable: false);
  }

  Future<void> loadSuppliers() async {
    if (isDisposed || _isLoading) return;
    AppDiagnostics.write('[$runtimeType] list load started');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await repository.getSuppliers();
      if (isDisposed) return;
      _suppliers = result;
      if (AppDiagnostics.enabled) {
        AppDiagnostics.write(
          '[$runtimeType] parsed count=${_suppliers.length}',
        );
      }
    } on AppException catch (error) {
      if (isDisposed) return;
      _errorMessage = error.message;
    } catch (_) {
      if (isDisposed) return;
      _errorMessage = 'Unable to load suppliers.';
    } finally {
      if (!isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> createSupplier(Map<String, dynamic> fields) async {
    if (_isSaving) return false;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final created = await repository.createSupplier(fields);
      _suppliers = [
        created,
        ..._suppliers.where((supplier) => supplier.id != created.id),
      ];
      return true;
    } on AppException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to create this supplier.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  void search(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }
}
