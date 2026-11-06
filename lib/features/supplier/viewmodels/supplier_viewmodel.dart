import 'dart:typed_data';

import '../../../core/cache/cache_manager.dart';
import '../../../core/diagnostics/app_diagnostics.dart';
import '../../../core/diagnostics/diagnostic_notifier.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/models/html_print_document.dart';
import '../models/supplier_model.dart';
import '../repositories/supplier_repository.dart';

class SupplierViewModel extends DiagnosticNotifier {
  SupplierViewModel(this.repository) {
    repository.cache?.addListener(_cacheChanged);
  }

  final SupplierRepository repository;
  void _cacheChanged() => notifyListeners();
  bool get hasSavedData =>
      repository.cache?.hasSavedData('/api/resource/Supplier') ?? false;
  @override
  void dispose() {
    repository.cache?.removeListener(_cacheChanged);
    super.dispose();
  }

  List<SupplierModel> _suppliers = const [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  bool _isSaving = false;
  String? _errorMessage;
  String _searchQuery = '';

  String get title => 'Suppliers';
  List<SupplierModel> get suppliers => _suppliers;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
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

  Map<String, dynamic>? _selectedSupplier;
  String? _selectedSupplierId;
  String? _detailErrorMessage;
  bool _isLoadingDetail = false;
  int _detailRequestId = 0;
  Map<String, dynamic>? get selectedSupplier => _selectedSupplier;
  String? get selectedSupplierId => _selectedSupplierId;
  String? get detailErrorMessage => _detailErrorMessage;
  bool get isLoadingDetail => _isLoadingDetail;
  bool _isLoadingPrint = false;
  String? _printError;
  bool get isLoadingPrint => _isLoadingPrint;
  String? get printError => _printError;

  Future<HtmlPrintDocument?> loadPrintPreview(String supplierId) async {
    if (isDisposed || _isLoadingPrint) return null;
    final session = _sessionId;
    _isLoadingPrint = true;
    _printError = null;
    notifyListeners();
    try {
      final html = await repository.getSupplierCardHtml(supplierId);
      final cookies = await repository.printCookies();
      if (isDisposed || session != _sessionId) return null;
      return HtmlPrintDocument(
        html: HtmlPrintDocument.extractHtml(html),
        title: 'Supplier Print Preview',
        documentId: supplierId,
        baseUrl: repository.printServerUri.resolve('/printview'),
        cookies: Map.unmodifiable(cookies),
        loadPdf: () async {
          if (isDisposed || session != _sessionId) {
            throw const AppException(
              'The account changed. Please reopen the preview.',
            );
          }
          return repository.getSupplierCard(supplierId);
        },
      );
    } on AppException catch (error) {
      if (!isDisposed && session == _sessionId) _printError = error.message;
    } catch (_) {
      if (!isDisposed && session == _sessionId) {
        _printError =
            'Unable to load the supplier print preview. Please retry.';
      }
    } finally {
      if (!isDisposed && session == _sessionId) {
        _isLoadingPrint = false;
        notifyListeners();
      }
    }
    return null;
  }

  Future<void> loadSupplier(String documentName, {bool force = true}) async {
    if (isDisposed ||
        (_isLoadingDetail && _selectedSupplierId == documentName)) {
      return;
    }
    final request = ++_detailRequestId;
    if (_selectedSupplierId != documentName) {
      _selectedSupplier = null;
      _printError = null;
    }
    _selectedSupplierId = documentName;
    _isLoadingDetail = true;
    _detailErrorMessage = null;
    notifyListeners();
    try {
      final result = await (force
          ? CacheManager.force(() => repository.getSupplier(documentName))
          : repository.getSupplier(documentName));
      if (!isDisposed && request == _detailRequestId) {
        _selectedSupplier = result;
      }
    } on AppException catch (error) {
      if (!isDisposed && request == _detailRequestId) {
        _detailErrorMessage = error.message;
      }
    } catch (_) {
      if (!isDisposed && request == _detailRequestId) {
        _detailErrorMessage = 'Unable to load this supplier. Please retry.';
      }
    } finally {
      if (!isDisposed && request == _detailRequestId) {
        _isLoadingDetail = false;
        notifyListeners();
      }
    }
  }

  int _sessionId = 0;
  void resetSession() {
    ++_sessionId;
    ++_detailRequestId;
    _isLoadingPrint = false;
    _printError = null;
    _selectedSupplier = null;
    _selectedSupplierId = null;
    _detailErrorMessage = null;
    _isLoadingDetail = false;
    _suppliers = const [];
    _hasLoaded = false;
    _isLoading = false;
    _isSaving = false;
    _errorMessage = null;
    _searchQuery = '';
    notifyListeners();
  }

  void revokeSavedData() {
    final selected = _selectedSupplierId;
    resetSession();
    _selectedSupplierId = selected;
    _detailErrorMessage =
        'This saved supplier is no longer available. Reconnect and tap Retry.';
    _errorMessage =
        'This saved data is no longer available. Reconnect and tap Retry.';
    notifyListeners();
  }

  bool get isRefreshing =>
      (_isLoading && _hasLoaded) ||
      (repository.cache?.isRefreshing('/api/resource/Supplier') ?? false);
  Future<void> loadSuppliers({bool force = true}) async {
    if (isDisposed || _isLoading) return;
    final sessionId = _sessionId;
    AppDiagnostics.write('[$runtimeType] list load started');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await (force
          ? CacheManager.force(() => repository.getSuppliers())
          : repository.getSuppliers());
      if (isDisposed || sessionId != _sessionId) return;
      _suppliers = result;
      _hasLoaded = true;
      if (AppDiagnostics.enabled) {
        AppDiagnostics.write(
          '[$runtimeType] parsed count=${_suppliers.length}',
        );
      }
    } on AppException catch (error) {
      if (isDisposed || sessionId != _sessionId) return;
      _errorMessage = error.message;
    } catch (_) {
      if (isDisposed || sessionId != _sessionId) return;
      _errorMessage = 'Unable to load suppliers.';
    } finally {
      if (!isDisposed && sessionId == _sessionId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> createSupplier(
    Map<String, dynamic> fields, {
    Uint8List? imageBytes,
    String? imageFilename,
  }) async {
    if (_isSaving) return false;
    final sessionId = _sessionId;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final payload = Map<String, dynamic>.from(fields);
      if (imageBytes != null && imageFilename != null) {
        payload['image'] = await repository.uploadSupplierImage(
          imageBytes,
          imageFilename,
        );
        if (isDisposed || sessionId != _sessionId) return false;
      }
      final created = await repository.createSupplier(payload);
      if (sessionId != _sessionId || isDisposed) return false;
      _suppliers = [
        created,
        ..._suppliers.where((supplier) => supplier.id != created.id),
      ];
      return true;
    } on AppException catch (error) {
      if (sessionId != _sessionId || isDisposed) return false;
      _errorMessage = error.message;
      return false;
    } catch (_) {
      if (sessionId != _sessionId || isDisposed) return false;
      _errorMessage = 'Unable to create this supplier.';
      return false;
    } finally {
      if (sessionId == _sessionId && !isDisposed) {
        _isSaving = false;
        notifyListeners();
      }
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
