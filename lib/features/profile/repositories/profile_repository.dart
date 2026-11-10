import '../../../core/cache/cache_manager.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/frappe_resource_api.dart';
import '../models/profile_model.dart';

class ProfileRepository {
  ProfileRepository(this._resourceApi);

  static const _userFields = [
    'name',
    'email',
    'first_name',
    'full_name',
    'user_image',
    'username',
    'enabled',
    'language',
    'time_zone',
    'user_type',
    'creation',
    'last_login',
    'last_active',
  ];

  final FrappeResourceApi _resourceApi;
  CacheManager? get cache => _resourceApi.cache;

  String? imageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    final uri = _resourceApi.serverUri.resolve(path.trim());
    return uri.scheme == 'http' || uri.scheme == 'https'
        ? uri.toString()
        : null;
  }

  Future<ProfileModel> getProfile(String email) async {
    final users = await _resourceApi.getDocList(
      'User',
      fields: _userFields,
      filters: [
        ['name', '=', email],
      ],
      limitPageLength: 1,
    );
    if (users.isEmpty) {
      throw const AppException('No user profile was found for this account.');
    }

    // User profile reads are intentionally field-limited. This excludes API
    // keys, password reset tokens, and other authentication settings.
    var roles = <String>[];
    try {
      final roleRecords = await _resourceApi.getDocList(
        'Has Role',
        optionalPermission: true,
        fields: const ['role'],
        filters: [
          ['parent', '=', email],
        ],
        limitPageLength: 100,
      );
      roles = roleRecords
          .map((record) => '${record['role'] ?? ''}'.trim())
          .where((role) => role.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      // Some Frappe roles restrict direct child-table reads. The profile itself
      // remains useful and should still be displayed.
    }

    return ProfileModel.fromJson(users.first, roles: roles);
  }
}
