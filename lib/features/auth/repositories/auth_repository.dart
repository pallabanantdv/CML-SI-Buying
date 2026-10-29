import 'package:cookie_jar/cookie_jar.dart';

import '../../../config/constants/api_endpoints.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/frappe_method_api.dart';
import '../../../core/services/session_service.dart';
import '../models/login_request.dart';
import '../models/user_model.dart';

abstract interface class AuthRepositoryContract {
  Future<UserModel> login(LoginRequest request);
  Future<void> logout();
  Future<void> clearLocalSession();
  Future<UserModel> currentUser();
  Future<bool> restoreSession();
}

class AuthRepository implements AuthRepositoryContract {
  AuthRepository(this._client, this._methods, this._session, this._cookieJar);
  final ApiClient _client;
  final FrappeMethodApi _methods;
  final SessionService _session;
  final CookieJar _cookieJar;

  @override
  Future<UserModel> login(LoginRequest request) async {
    await _client.post(ApiEndpoints.login, data: request.toJson());
    final user = await currentUser();
    if (user.id.isEmpty) {
      throw const AppException(
        'Sign in succeeded, but the server did not return a user.',
      );
    }
    await _session.markAuthenticated();
    return user;
  }

  @override
  Future<void> logout() async {
    try {
      await _methods.callPostMethod('logout');
    } finally {
      await _session.clear();
      await _cookieJar.deleteAll();
    }
  }

  @override
  Future<void> clearLocalSession() async {
    await _session.clear();
    await _cookieJar.deleteAll();
  }

  @override
  Future<UserModel> currentUser() async => UserModel.fromValue(
    await _methods.callGetMethod(ApiEndpoints.loggedUser),
  );
  @override
  Future<bool> restoreSession() async {
    if (!await _session.isAuthenticated) return false;
    try {
      final user = await currentUser();
      return user.id.isNotEmpty;
    } on AppException catch (error) {
      if (error.isAuthenticationError) await logout();
      rethrow;
    }
  }
}
