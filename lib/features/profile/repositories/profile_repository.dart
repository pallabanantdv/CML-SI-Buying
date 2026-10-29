import '../../auth/repositories/auth_repository.dart';
import '../models/profile_model.dart';

class ProfileRepository {
  ProfileRepository(this._authRepository);
  final AuthRepository _authRepository;
  Future<ProfileModel> load() async {
    final user = await _authRepository.currentUser();
    return ProfileModel(email: user.id, fullName: user.fullName);
  }
}
