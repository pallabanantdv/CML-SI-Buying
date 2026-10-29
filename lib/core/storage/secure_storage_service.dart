import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService(this._storage);
  final FlutterSecureStorage _storage;
  static const _sessionKey = 'frappe_session_active';
  Future<void> setSessionActive(bool active) =>
      _storage.write(key: _sessionKey, value: active ? '1' : '0');
  Future<bool> hasSession() async =>
      await _storage.read(key: _sessionKey) == '1';
  Future<void> clear() => _storage.delete(key: _sessionKey);
}
