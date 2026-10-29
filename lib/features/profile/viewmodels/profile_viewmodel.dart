import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../models/profile_model.dart';
import '../repositories/profile_repository.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel(this._repository);
  final ProfileRepository _repository;
  ProfileModel? _profile;
  String? _errorMessage;
  bool _isLoading = false;
  bool _disposed = false;
  ProfileModel? get profile => _profile;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    _notify();
    try {
      _profile = await _repository.load();
    } on AppException catch (error) {
      _errorMessage = error.message;
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
