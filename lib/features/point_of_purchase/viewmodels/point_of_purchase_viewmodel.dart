import 'dart:async';

import '../../../core/cache/cache_manager.dart';
import '../../../core/diagnostics/app_diagnostics.dart';
import '../../../core/diagnostics/diagnostic_notifier.dart';
import '../../../core/errors/app_exception.dart';
import '../models/point_of_purchase_model.dart';
import '../models/supplier_advance.dart';

import 'package:cml_si_buying/features/point_of_purchase/repositories/point_of_purchase_repository.dart';

class PointOfPurchaseViewModel extends DiagnosticNotifier {
  PointOfPurchaseViewModel(this.repository) {
    repository.cache?.addListener(_cacheChanged);
  }

  final PointOfPurchaseRepository repository;
  void _cacheChanged() => notifyListeners();
  bool get hasSavedData =>
      repository.cache?.hasSavedData(
        '/api/resource/Supplier%20Point%20Of%20Purchase',
      ) ??
      false;
  @override
  void dispose() {
    repository.cache?.removeListener(_cacheChanged);
    super.dispose();
  }

  String get title => 'Point of Purchase';
  List<PointOfPurchaseModel> _records = const [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  int _listRequestId = 0;
  int _sessionId = 0;

  void resetSession() {
    ++_sessionId;
    _resetSupplierAdvances();
    _isSubmitting = false;
    _submitErrorMessage = null;
    _isCreating = false;
    _createErrorMessage = null;
    _isLoadingCreateOptions = false;
    _createOptionsError = null;
    _hasCreateOptions = false;
    _supplierOptions = const [];
    _itemOptions = const [];
    _journalEntryOptions = const [];
    _otherLinkOptions = const {};
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

  void revokeSavedData() {
    final name = _selectedName;
    resetSession();
    _selectedName = name;
    _errorMessage =
        'This saved data is no longer available. Reconnect and tap Retry.';
    _detailErrorMessage = _errorMessage;
    notifyListeners();
  }

  Future<void> refreshReferenceData() async {
    if (_hasCreateOptions || _createOptionsError != null) {
      await loadCreateOptions();
    }
    final supplier = _advanceSupplier;
    if (supplier != null) await loadSupplierAdvances(supplier, force: true);
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
  bool _hasCreateOptions = false;
  bool get hasCreateOptions => _hasCreateOptions;
  String? _createOptionsError;
  bool _isCreating = false;
  String? _createErrorMessage;

  List<PointOfPurchaseModel> get records => _records;
  bool get isLoading => _isLoading;
  bool get isRefreshing =>
      (_isLoading && _hasLoaded) ||
      (repository.cache?.isRefreshing(
            '/api/resource/Supplier%20Point%20Of%20Purchase',
          ) ??
          false);
  bool get hasLoaded => _hasLoaded;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get selectedRecord => _selectedRecord;
  String? get selectedName => _selectedName;
  bool get isLoadingDetail => _isLoadingDetail;
  bool get isRefreshingDetail =>
      (_isLoadingDetail && _selectedRecord != null) ||
      (repository.cache?.isRefreshing(
            '/api/resource/Supplier%20Point%20Of%20Purchase/${Uri.encodeComponent(_selectedName ?? '')}',
          ) ??
          false);
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

  List<SupplierAdvance> _supplierAdvances = const [];
  String? _advanceSupplier;
  bool _isLoadingSupplierAdvances = false;
  bool _supplierAdvancesLoaded = false;
  String? _supplierAdvancesError;
  int _advanceRequestId = 0;
  List<SupplierAdvance> get supplierAdvances => _supplierAdvances;
  bool get isLoadingSupplierAdvances => _isLoadingSupplierAdvances;
  String? get supplierAdvancesError => _supplierAdvancesError;
  int get availableAdvanceMinor => _supplierAdvances.fold<int>(
    0,
    (total, advance) => total + advance.unallocatedMinor,
  );
  double get availableAdvance => availableAdvanceMinor / 100;

  void _resetSupplierAdvances() {
    ++_advanceRequestId;
    _advanceSupplier = null;
    _supplierAdvances = const [];
    _isLoadingSupplierAdvances = false;
    _supplierAdvancesLoaded = false;
    _supplierAdvancesError = null;
  }

  void clearSupplierAdvances() {
    if (isDisposed) return;
    _resetSupplierAdvances();
    notifyListeners();
  }

  Future<void> loadSupplierAdvances(
    String? supplier, {
    bool force = false,
  }) async {
    if (isDisposed) return;
    final name = supplier?.trim() ?? '';
    if (name.isEmpty) {
      clearSupplierAdvances();
      return;
    }
    if (_advanceSupplier == name &&
        (_isLoadingSupplierAdvances || (!force && _supplierAdvancesLoaded))) {
      return;
    }
    final request = ++_advanceRequestId;
    if (_advanceSupplier != name) {
      _supplierAdvances = const [];
      _supplierAdvancesLoaded = false;
    }
    _advanceSupplier = name;
    _isLoadingSupplierAdvances = true;
    _supplierAdvancesError = null;
    notifyListeners();
    try {
      final advances = await repository.getSupplierAdvances(name);
      if (isDisposed || request != _advanceRequestId) return;
      _supplierAdvances = List.unmodifiable(advances);
      _supplierAdvancesLoaded = true;
    } on AppException catch (error) {
      if (!isDisposed && request == _advanceRequestId) {
        _supplierAdvancesError = error.message;
      }
    } catch (_) {
      if (!isDisposed && request == _advanceRequestId) {
        _supplierAdvancesError =
            'Unable to load supplier advances. Please retry.';
      }
    } finally {
      if (!isDisposed && request == _advanceRequestId) {
        _isLoadingSupplierAdvances = false;
        notifyListeners();
      }
    }
  }

  String? validateAdvanceDeduction(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final amount = double.tryParse(text);
    if (amount == null || !amount.isFinite) return 'Enter a valid amount.';
    if (amount < 0) return 'Enter zero or a positive amount.';
    final scaled = amount * 100;
    if (!scaled.isFinite || scaled > 9007199254740991) {
      return 'Enter a smaller amount.';
    }
    final minor = scaled.round();
    if ((scaled - minor).abs() > 0.000001) {
      return 'Use at most two decimal places.';
    }
    if (minor == 0) return null;
    if (_advanceSupplier == null) return 'Select a supplier first.';
    if (_isLoadingSupplierAdvances) {
      return 'Wait for the supplier advances to load.';
    }
    if (!_supplierAdvancesLoaded || _supplierAdvancesError != null) {
      return 'Load the supplier advances before deducting an advance.';
    }
    if (minor > availableAdvanceMinor) {
      return 'Deduction cannot exceed the available advance.';
    }
    return null;
  }

  List<SupplierAdvanceAllocation> allocateSupplierAdvances(String deduction) {
    if (validateAdvanceDeduction(deduction) != null) return const [];
    var remaining = ((double.tryParse(deduction.trim()) ?? 0) * 100).round();
    final rows = <SupplierAdvanceAllocation>[];
    for (final advance in _supplierAdvances) {
      if (remaining <= 0) break;
      if (advance.unallocatedMinor <= 0) continue;
      final allocated = remaining < advance.unallocatedMinor
          ? remaining
          : advance.unallocatedMinor;
      rows.add(
        SupplierAdvanceAllocation(advance: advance, allocatedMinor: allocated),
      );
      remaining -= allocated;
    }
    return List.unmodifiable(rows);
  }

  Future<void> loadCreateOptions() async {
    if (_isLoadingCreateOptions) return;
    final sessionId = _sessionId;
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
      if (sessionId != _sessionId || isDisposed) return;
      _hasCreateOptions = true;
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
      if (sessionId != _sessionId || isDisposed) return;
      _createOptionsError = error.message;
    } catch (_) {
      if (sessionId != _sessionId || isDisposed) return;
      _createOptionsError = 'Unable to load purchase form options.';
    } finally {
      if (sessionId == _sessionId && !isDisposed) {
        _isLoadingCreateOptions = false;
        notifyListeners();
      }
    }
  }

  Future<Map<String, dynamic>> getPurchaseForEditing(String name) =>
      repository.getPointOfPurchase(name);

  Future<Map<String, String?>> getWarehouseAccounts(String warehouse) =>
      repository.getWarehouseAccounts(warehouse);

  Future<bool> updatePointOfPurchase(
    String name,
    Map<String, dynamic> fields,
  ) async {
    if (isDisposed || _isCreating || _isSubmitting) return false;
    final session = _sessionId;
    _isCreating = true;
    _createErrorMessage = null;
    notifyListeners();
    try {
      final updated = await repository.updatePointOfPurchase(name, fields);
      if (isDisposed || session != _sessionId) return false;
      if (_selectedName == name) {
        ++_detailRequestId;
        _isLoadingDetail = false;
        _selectedRecord = updated;
      }
      _records = [
        for (final record in _records)
          if (record.name == name)
            PointOfPurchaseModel.fromJson(updated)
          else
            record,
      ];
      unawaited(loadPointOfPurchases());
      return true;
    } on AppException catch (error) {
      if (!isDisposed && session == _sessionId) {
        _createErrorMessage = error.message;
      }
      return false;
    } catch (_) {
      if (!isDisposed && session == _sessionId) {
        _createErrorMessage = 'Unable to update this purchase.';
      }
      return false;
    } finally {
      if (!isDisposed && session == _sessionId) {
        _isCreating = false;
        notifyListeners();
      }
    }
  }

  Future<bool> createPointOfPurchase(Map<String, dynamic> fields) async {
    if (_isCreating) return false;
    final sessionId = _sessionId;
    _isCreating = true;
    _createErrorMessage = null;
    notifyListeners();
    try {
      await repository.createPointOfPurchase(fields);
      if (sessionId != _sessionId || isDisposed) return false;
      _createErrorMessage = null;
      _isCreating = false;
      notifyListeners();
      // Refresh the list in the background after a successful create.
      unawaited(loadPointOfPurchases());
      return true;
    } on AppException catch (error) {
      if (sessionId != _sessionId || isDisposed) return false;
      _createErrorMessage = error.message;
      return false;
    } catch (_) {
      if (sessionId != _sessionId || isDisposed) return false;
      _createErrorMessage = 'Unable to create this purchase record.';
      return false;
    } finally {
      if (_isCreating && sessionId == _sessionId && !isDisposed) {
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

  Future<void> loadPointOfPurchases({bool force = true}) async {
    if (isDisposed || _isLoading) return;
    final listRequest = ++_listRequestId;
    AppDiagnostics.write('[$runtimeType] list load started');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await (force
          ? CacheManager.force(() => repository.getPointOfPurchases())
          : repository.getPointOfPurchases());
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

  bool _isSubmitting = false;
  String? _submitErrorMessage;
  bool get isSubmitting => _isSubmitting;
  String? get submitErrorMessage => _submitErrorMessage;

  Future<bool> submitPointOfPurchase(String documentName) async {
    if (isDisposed || _isSubmitting) return false;
    if (_selectedName != documentName ||
        int.tryParse('${_selectedRecord?['docstatus']}') != 0) {
      _submitErrorMessage = 'Only draft purchases can be submitted.';
      notifyListeners();
      return false;
    }
    final session = _sessionId;
    _isSubmitting = true;
    _submitErrorMessage = null;
    ++_detailRequestId; // A previous draft read must not overwrite the result.
    _isLoadingDetail = false;
    notifyListeners();
    try {
      final submitted = await repository.submitPointOfPurchase(documentName);
      if (isDisposed || session != _sessionId) return false;
      if (_selectedName == documentName) {
        ++_detailRequestId;
        _isLoadingDetail = false;
        _selectedRecord = submitted;
        _detailErrorMessage = null;
      }
      _records = [
        for (final record in _records)
          if (record.name == documentName)
            PointOfPurchaseModel.fromJson(submitted)
          else
            record,
      ];
      // Refresh related lists and advance balances after confirmed submission.
      unawaited(loadPointOfPurchases());
      _resetSupplierAdvances();
      return true;
    } on AppException catch (error) {
      if (!isDisposed && session == _sessionId) {
        _submitErrorMessage = error.message;
      }
      return false;
    } catch (_) {
      if (!isDisposed && session == _sessionId) {
        _submitErrorMessage = 'Unable to confirm submission. Refresh the record before trying again.';
      }
      return false;
    } finally {
      if (!isDisposed && session == _sessionId) {
        _isSubmitting = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadPointOfPurchase(
    String documentName, {
    bool force = true,
  }) async {
    if (isDisposed || (_isLoadingDetail && _selectedName == documentName)) {
      return;
    }
    AppDiagnostics.write('[$runtimeType] detail load started');
    final requestId = ++_detailRequestId;
    if (_selectedName != documentName) {
      _selectedRecord = null;
      _submitErrorMessage = null;
    }
    _selectedName = documentName;
    _detailErrorMessage = null;
    _isLoadingDetail = true;
    notifyListeners();
    try {
      final record = await (force
          ? CacheManager.force(
              () => repository.getPointOfPurchase(documentName),
            )
          : repository.getPointOfPurchase(documentName));
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
