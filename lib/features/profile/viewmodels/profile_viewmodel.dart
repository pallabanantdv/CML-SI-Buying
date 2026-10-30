import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../models/profile_model.dart';
import '../repositories/profile_repository.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel(this.repository);

  final ProfileRepository repository;

  ProfileModel? _profile;
  bool _isLoading = false;
  String? _errorMessage;
  String? _requestedEmail;
  int _requestId = 0;

  ProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadProfile(String email) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty ||
        (_requestedEmail == normalizedEmail &&
            (_isLoading || _profile != null))) {
      return;
    }
    final requestId = ++_requestId;
    _requestedEmail = normalizedEmail;
    _isLoading = true;
    _errorMessage = null;
    _profile = null;
    notifyListeners();
    try {
      final profile = await repository.getProfile(normalizedEmail);
      if (requestId == _requestId) _profile = profile;
    } on AppException catch (error) {
      if (requestId == _requestId) _errorMessage = error.message;
    } catch (_) {
      if (requestId == _requestId) {
        _errorMessage = 'Unable to load this user profile.';
      }
    } finally {
      if (requestId == _requestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void clearProfile() {
    ++_requestId;
    _requestedEmail = null;
    _profile = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
