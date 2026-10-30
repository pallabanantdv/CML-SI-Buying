import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../models/point_of_purchase_model.dart';
import '../repositories/point_of_purchase_repository.dart';

class PointOfPurchaseViewModel extends ChangeNotifier {
  PointOfPurchaseViewModel(this.repository);

  final PointOfPurchaseRepository repository;

  String get title => 'Point of Purchase';
  List<PointOfPurchaseModel> _records = const [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _selectedRecord;
  String? _selectedName;
  bool _isLoadingDetail = false;
  String? _detailErrorMessage;
  int _detailRequestId = 0;

  List<PointOfPurchaseModel> get records => _records;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get selectedRecord => _selectedRecord;
  String? get selectedName => _selectedName;
  bool get isLoadingDetail => _isLoadingDetail;
  String? get detailErrorMessage => _detailErrorMessage;

  Future<void> loadPointOfPurchases() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _records = await repository.getPointOfPurchases();
    } on AppException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load point-of-purchase records.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPointOfPurchase(String documentName) async {
    final requestId = ++_detailRequestId;
    _selectedName = documentName;
    _selectedRecord = null;
    _detailErrorMessage = null;
    _isLoadingDetail = true;
    notifyListeners();
    try {
      final record = await repository.getPointOfPurchase(documentName);
      if (requestId != _detailRequestId) return;
      _selectedRecord = record;
    } on AppException catch (error) {
      if (requestId != _detailRequestId) return;
      _detailErrorMessage = error.message;
    } catch (_) {
      if (requestId != _detailRequestId) return;
      _detailErrorMessage = 'Unable to load this purchase record.';
    } finally {
      if (requestId == _detailRequestId) {
        _isLoadingDetail = false;
        notifyListeners();
      }
    }
  }
}
