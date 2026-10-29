import '../storage/secure_storage_service.dart';

class SessionService {
  SessionService(this._storage);
  final SecureStorageService _storage;
  Future<bool> get isAuthenticated => _storage.hasSession();
  Future<void> markAuthenticated() => _storage.setSessionActive(true);
  Future<void> clear() => _storage.clear();
}
