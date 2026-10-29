import 'package:flutter_test/flutter_test.dart';
import 'package:cml_si_buying/core/errors/app_exception.dart';
import 'package:cml_si_buying/features/auth/models/login_request.dart';
import 'package:cml_si_buying/features/auth/models/user_model.dart';
import 'package:cml_si_buying/features/auth/repositories/auth_repository.dart';
import 'package:cml_si_buying/features/auth/viewmodels/auth_viewmodel.dart';

void main() {
  late _AuthRepository repository;
  late AuthViewModel viewModel;

  setUp(() {
    repository = _AuthRepository();
    viewModel = AuthViewModel(repository);
  });

  tearDown(() => viewModel.dispose());

  test('login success updates user and authentication state', () async {
    expect(await viewModel.login('buyer@example.com', 'pw'), isTrue);
    expect(viewModel.isAuthenticated, isTrue);
    expect(viewModel.user?.id, 'buyer@example.com');
    expect(viewModel.isLoading, isFalse);
  });

  test('login failure exposes safe error and resets loading state', () async {
    repository.failure = const AppException('Invalid credentials.');
    expect(await viewModel.login('buyer@example.com', 'bad'), isFalse);
    expect(viewModel.isAuthenticated, isFalse);
    expect(viewModel.errorMessage, 'Invalid credentials.');
    expect(viewModel.isLoading, isFalse);
  });

  test('restores a previously valid session', () async {
    repository.hasSession = true;
    await viewModel.restoreSession();
    expect(viewModel.initialized, isTrue);
    expect(viewModel.isAuthenticated, isTrue);
    expect(viewModel.user?.id, 'buyer@example.com');
  });
}

class _AuthRepository implements AuthRepositoryContract {
  bool hasSession = false;
  AppException? failure;
  @override
  Future<UserModel> login(LoginRequest request) async {
    final error = failure;
    if (error != null) throw error;
    return UserModel(id: request.username);
  }
  @override
  Future<void> logout() async {
    hasSession = false;
  }
  @override
  Future<void> clearLocalSession() async {
    hasSession = false;
  }
  @override
  Future<UserModel> currentUser() async => const UserModel(id: 'buyer@example.com');
  @override
  Future<bool> restoreSession() async => hasSession;
}
