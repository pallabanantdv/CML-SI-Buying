import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';
import '../network/dio_client.dart';
import '../network/frappe_method_api.dart';
import '../network/frappe_resource_api.dart';
import '../services/session_service.dart';
import '../storage/preferences_service.dart';
import '../storage/secure_storage_service.dart';
import '../../features/auth/repositories/auth_repository.dart';
import '../../features/auth/viewmodels/auth_viewmodel.dart';
import '../../features/dashboard/repositories/dashboard_repository.dart';
import '../../features/dashboard/viewmodels/dashboard_viewmodel.dart';
import '../../features/profile/repositories/profile_repository.dart';
import '../../features/profile/viewmodels/profile_viewmodel.dart';

class AppDependencies {
  const AppDependencies({
    required this.auth,
    required this.dashboard,
    required this.profile,
    required this.preferences,
  });
  final AuthViewModel auth;
  final DashboardViewModel dashboard;
  final ProfileViewModel profile;
  final PreferencesService preferences;
}

abstract final class DependencyInjection {
  static Future<AppDependencies> create() async {
    final prefs = PreferencesService(await SharedPreferences.getInstance());
    final storage = SecureStorageService(const FlutterSecureStorage());
    final cookieJar = await _cookieJar();
    late final AuthViewModel auth;
    final dio = DioClient(
      cookieJar: cookieJar,
      onUnauthorized: () async => auth.expireSession(),
    );
    final api = ApiClient(dio);
    final methods = FrappeMethodApi(api);
    final resources = FrappeResourceApi(api);
    final session = SessionService(storage);
    final authRepository = AuthRepository(api, methods, session, cookieJar);
    auth = AuthViewModel(authRepository);
    return AppDependencies(
      auth: auth,
      dashboard: DashboardViewModel(DashboardRepository(resources, methods)),
      profile: ProfileViewModel(ProfileRepository(authRepository)),
      preferences: prefs,
    );
  }

  static Future<CookieJar> _cookieJar() async {
    if (kIsWeb) return CookieJar();
    final directory = await getApplicationSupportDirectory();
    return PersistCookieJar(
      storage: FileStorage(
        '${directory.path}${defaultTargetPlatform == TargetPlatform.windows ? r'\' : '/'}cml_si_buying_cookies',
      ),
    );
  }
}
