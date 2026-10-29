import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../models/login_request.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._repository);
  final AuthRepositoryContract _repository;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  bool _initialized = false;
  String? _errorMessage;
  UserModel? _user;
  bool _disposed = false;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  bool get initialized => _initialized;
  String? get errorMessage => _errorMessage;
  UserModel? get user => _user;

  Future<void> restoreSession() async {
    _setLoading(true);
    try {
      _isAuthenticated = await _repository.restoreSession();
      if (_isAuthenticated) _user = await _repository.currentUser();
    } on AppException catch (error) {
      _errorMessage = error.message;
      _isAuthenticated = false;
    } finally {
      _initialized = true;
      _setLoading(false);
    }
  }

  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _user = await _repository.login(
        LoginRequest(username: username, password: password),
      );
      _isAuthenticated = true;
      return true;
    } on AppException catch (error) {
      _errorMessage = error.message;
      return false;
    } finally {
      _initialized = true;
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _repository.logout();
    } on AppException catch (error) {
      _errorMessage = error.message;
    } finally {
      _user = null;
      _isAuthenticated = false;
      _setLoading(false);
    }
  }

  Future<void> expireSession() async {
    await _repository.clearLocalSession();
    _user = null;
    _isAuthenticated = false;
    _initialized = true;
    _notify();
  }

  void clearError() {
    _errorMessage = null;
    _notify();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _notify();
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
