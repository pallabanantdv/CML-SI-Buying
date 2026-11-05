import 'package:flutter/foundation.dart';

import '../../../core/cache/cache_manager.dart';
import '../../../core/errors/app_exception.dart';
import '../models/profile_model.dart';
import '../repositories/profile_repository.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel(this.repository) {
    repository.cache?.addListener(_cacheChanged);
  }

  final ProfileRepository repository;
  bool _disposed = false;
  void _cacheChanged() => notifyListeners();
  bool get hasSavedData =>
      repository.cache?.hasSavedData('/api/resource/User') ?? false;
  @override
  void dispose() {
    _disposed = true;
    ++_requestId;
    repository.cache?.removeListener(_cacheChanged);
    super.dispose();
  }

  ProfileModel? _profile;
  bool _isLoading = false;
  String? _errorMessage;
  String? _requestedEmail;
  int _requestId = 0;

  ProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isRefreshing =>
      (_isLoading && _profile != null) ||
      (repository.cache?.isRefreshing('/api/resource/User') ?? false);
  String? get errorMessage => _errorMessage;

  Future<void> loadProfile(
    String email, {
    bool force = false,
    bool refresh = true,
  }) async {
    final normalizedEmail = email.trim();
    if (_disposed ||
        normalizedEmail.isEmpty ||
        (!force &&
            _requestedEmail == normalizedEmail &&
            (_isLoading || _profile != null))) {
      return;
    }
    final requestId = ++_requestId;
    if (_requestedEmail != normalizedEmail) _profile = null;
    _requestedEmail = normalizedEmail;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final profile = await (refresh
          ? CacheManager.force(() => repository.getProfile(normalizedEmail))
          : repository.getProfile(normalizedEmail));
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

  void revokeSavedData() {
    if (_disposed) return;
    clearProfile();
    _errorMessage =
        'This saved profile is no longer available. Reconnect and tap Retry.';
    notifyListeners();
  }

  void clearProfile() {
    if (_disposed) return;
    ++_requestId;
    _requestedEmail = null;
    _profile = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
