import 'dart:async';

import '../../../core/diagnostics/app_diagnostics.dart';
import '../../../core/diagnostics/diagnostic_notifier.dart';
import '../../../core/errors/app_exception.dart';
import '../models/point_of_purchase_model.dart';
import '../repositories/point_of_purchase_repository.dart';

class PointOfPurchaseViewModel extends DiagnosticNotifier {
  PointOfPurchaseViewModel(this.repository);

  final PointOfPurchaseRepository repository;

  String get title => 'Point of Purchase';
  List<PointOfPurchaseModel> _records = const [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  int _listRequestId = 0;

  void resetSession() {
    ++_listRequestId;
    ++_detailRequestId;
    _hasLoaded = false;
    _records = const [];
    _selectedRecord = null;
    _selectedName = null;
    _errorMessage = null;
    _detailErrorMessage = null;
    _isLoading = false;
    _isLoadingDetail = false;
    notifyListeners();
  }

  Future<void> ensureLoaded() async {
    if (!_hasLoaded && !_isLoading) await loadPointOfPurchases();
  }

  String? _errorMessage;
  Map<String, dynamic>? _selectedRecord;
  String? _selectedName;
  bool _isLoadingDetail = false;
  String? _detailErrorMessage;
  int _detailRequestId = 0;
  List<Map<String, dynamic>> _supplierOptions = const [];
  List<Map<String, dynamic>> _itemOptions = const [];
  List<Map<String, dynamic>> _journalEntryOptions = const [];
  Map<String, List<Map<String, dynamic>>> _otherLinkOptions = const {};
  bool _isLoadingCreateOptions = false;
  String? _createOptionsError;
  bool _isCreating = false;
  String? _createErrorMessage;

  List<PointOfPurchaseModel> get records => _records;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get selectedRecord => _selectedRecord;
  String? get selectedName => _selectedName;
  bool get isLoadingDetail => _isLoadingDetail;
  String? get detailErrorMessage => _detailErrorMessage;
  List<Map<String, dynamic>> get supplierOptions => _supplierOptions;
  List<Map<String, dynamic>> get itemOptions => _itemOptions;
  List<Map<String, dynamic>> get journalEntryOptions => _journalEntryOptions;
  List<Map<String, dynamic>> linkOptions(String doctype) =>
      _otherLinkOptions[doctype] ?? const [];
  bool get isLoadingCreateOptions => _isLoadingCreateOptions;
  String? get createOptionsError => _createOptionsError;
  bool get isCreating => _isCreating;
  String? get createErrorMessage => _createErrorMessage;

  Future<void> loadCreateOptions() async {
    if (_isLoadingCreateOptions) return;
    _isLoadingCreateOptions = true;
    _createOptionsError = null;
    notifyListeners();
    try {
      final options = await Future.wait<List<Map<String, dynamic>>>([
        repository.getSupplierOptions(),
        repository.getItemOptions(),
        repository.getJournalEntryOptions(),
        repository.getLinkOptions('Warehouse'),
        repository.getLinkOptions('Island'),
        repository.getLinkOptions('Company'),
        repository.getLinkOptions(
          'Account',
          fields: const ['name', 'account_name'],
          titleField: 'account_name',
        ),
        repository.getLinkOptions('Mode of Payment'),
        repository.getLinkOptions('UOM'),
      ]);
      _supplierOptions = options[0];
      _itemOptions = options[1];
      _journalEntryOptions = options[2];
      _otherLinkOptions = {
        'Warehouse': options[3],
        'Island': options[4],
        'Company': options[5],
        'Account': options[6],
        'Mode of Payment': options[7],
        'UOM': options[8],
      };
    } on AppException catch (error) {
      _createOptionsError = error.message;
    } catch (_) {
      _createOptionsError = 'Unable to load purchase form options.';
    } finally {
      _isLoadingCreateOptions = false;
      notifyListeners();
    }
  }

  Future<bool> createPointOfPurchase(Map<String, dynamic> fields) async {
    if (_isCreating) return false;
    _isCreating = true;
    _createErrorMessage = null;
    notifyListeners();
    try {
      await repository.createPointOfPurchase(fields);
      _createErrorMessage = null;
      _isCreating = false;
      notifyListeners();
      // Refresh the list in the background after a successful create.
      unawaited(loadPointOfPurchases());
      return true;
    } on AppException catch (error) {
      _createErrorMessage = error.message;
      return false;
    } catch (_) {
      _createErrorMessage = 'Unable to create this purchase record.';
      return false;
    } finally {
      if (_isCreating) {
        _isCreating = false;
        notifyListeners();
      }
    }
  }

  void clearCreateError() {
    if (_createErrorMessage == null) return;
    _createErrorMessage = null;
    notifyListeners();
  }

  Future<void> loadPointOfPurchases() async {
    if (isDisposed || _isLoading) return;
    final listRequest = ++_listRequestId;
    AppDiagnostics.write('[$runtimeType] list load started');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await repository.getPointOfPurchases();
      if (isDisposed || listRequest != _listRequestId) return;
      _records = result;
      _hasLoaded = true;
      if (AppDiagnostics.enabled) {
        AppDiagnostics.write('[$runtimeType] parsed count=${_records.length}');
      }
    } on AppException catch (error) {
      if (isDisposed || listRequest != _listRequestId) return;
      _errorMessage = error.message;
    } catch (_) {
      if (isDisposed || listRequest != _listRequestId) return;
      _errorMessage = 'Unable to load point-of-purchase records.';
    } finally {
      if (!isDisposed && listRequest == _listRequestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadPointOfPurchase(String documentName) async {
    if (isDisposed || (_isLoadingDetail && _selectedName == documentName)) {
      return;
    }
    AppDiagnostics.write('[$runtimeType] detail load started');
    final requestId = ++_detailRequestId;
    _selectedName = documentName;
    _selectedRecord = null;
    _detailErrorMessage = null;
    _isLoadingDetail = true;
    notifyListeners();
    try {
      final record = await repository.getPointOfPurchase(documentName);
      if (isDisposed || requestId != _detailRequestId) return;
      _selectedRecord = record;
      AppDiagnostics.write('[$runtimeType] detail parsed');
    } on AppException catch (error) {
      if (isDisposed || requestId != _detailRequestId) return;
      _detailErrorMessage = error.message;
    } catch (_) {
      if (isDisposed || requestId != _detailRequestId) return;
      _detailErrorMessage = 'Unable to load this purchase record.';
    } finally {
      if (!isDisposed && requestId == _detailRequestId) {
        _isLoadingDetail = false;
        notifyListeners();
      }
    }
  }
}
