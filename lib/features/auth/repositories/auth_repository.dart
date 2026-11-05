import 'package:cookie_jar/cookie_jar.dart';

import '../../../config/constants/api_endpoints.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/frappe_method_api.dart';
import '../../../core/services/session_service.dart';
import '../models/login_request.dart';
import '../../../core/cache/cache_manager.dart';
import '../models/user_model.dart';

abstract interface class AuthRepositoryContract {
  Future<UserModel> login(LoginRequest request);
  Future<void> logout();
  Future<void> clearLocalSession();
  Future<UserModel> currentUser();
  Future<bool> restoreSession();
}

class AuthRepository implements AuthRepositoryContract {
  AuthRepository(
    this._client,
    this._methods,
    this._session,
    this._cookieJar, {
    this.cache,
  });
  final CacheManager? cache;
  UserModel? _restoredUser;
  final ApiClient _client;
  final FrappeMethodApi _methods;
  final SessionService _session;
  final CookieJar _cookieJar;

  @override
  Future<UserModel> login(LoginRequest request) async {
    _restoredUser = null;
    await cache?.clearSession();
    await _client.post(ApiEndpoints.login, data: request.toJson());
    final user = await currentUser();
    if (user.id.isEmpty) {
      throw const AppException(
        'Sign in succeeded, but the server did not return a user.',
      );
    }
    await cache?.activate(user.id);
    await _session.markAuthenticated();
    return user;
  }

  @override
  Future<void> logout() async {
    try {
      if (cache?.connectivity.offline != true) {
        await _methods.callPostMethod('logout');
      }
    } finally {
      await clearLocalSession();
    }
  }

  @override
  Future<void> clearLocalSession() async {
    _restoredUser = null;
    try {
      await cache?.clearSession();
    } finally {
      try {
        await _session.clear();
      } finally {
        await _cookieJar.deleteAll();
      }
    }
  }

  @override
  Future<UserModel> currentUser() async {
    final restored = _restoredUser;
    _restoredUser = null;
    if (restored != null) return restored;
    if (cache?.owner != null && cache?.connectivity.hasNetwork == false) {
      return UserModel(id: cache!.owner!);
    }
    try {
      final user = UserModel.fromValue(
        await _methods.callGetMethod(ApiEndpoints.loggedUser),
      );
      if (user.id.isEmpty || user.id.toLowerCase() == 'guest') {
        throw const AppException(
          'Your session has expired. Please sign in again.',
          statusCode: 401,
          isAuthenticationError: true,
        );
      }
      return user;
    } on AppException catch (error) {
      if (cache?.owner != null &&
          ((error.statusCode == null && cache?.connectivity.offline == true) ||
              (error.statusCode ?? 0) >= 500)) {
        return UserModel(id: cache!.owner!);
      }
      rethrow;
    }
  }

  @override
  Future<bool> restoreSession() async {
    if (!await _session.isAuthenticated) return false;
    final saved = await cache?.savedIdentity();
    if (saved != null) await cache?.activate(saved);
    try {
      final user = await currentUser();
      if (user.id.isNotEmpty && user.id != cache?.owner) {
        await cache?.activate(user.id);
      }
      _restoredUser = user;
      return user.id.isNotEmpty;
    } on AppException catch (error) {
      if (error.isAuthenticationError || error.statusCode == 403) {
        await clearLocalSession();
      }
      rethrow;
    }
  }
}
