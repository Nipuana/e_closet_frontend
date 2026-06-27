import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/google_auth_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../state/auth_state.dart';

final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(
  () => AuthViewModel(),
);

class AuthViewModel extends Notifier<AuthState> {
  late LoginUsecase _loginUsecase;
  late RegisterUsecase _registerUsecase;
  late LogoutUsecase _logoutUsecase;
  late IAuthRepository _authRepository;
  late GoogleAuthService _googleAuthService;

  @override
  AuthState build() {
    _loginUsecase = ref.read(loginUsecaseProvider);
    _registerUsecase = ref.read(registerUsecaseProvider);
    _logoutUsecase = ref.read(logoutUsecaseProvider);
    _authRepository = ref.read(authRepositoryProvider);
    _googleAuthService = ref.read(googleAuthServiceProvider);

    return const AuthState();
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String userType,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);

    final params = RegisterUsecaseParams(
      username: username,
      email: email,
      password: password,
      userType: userType,
    );

    final result = await _registerUsecase(params);

    result.fold(
      (failure) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.message,
        );
      },
      (success) {
        state = state.copyWith(
          status: AuthStatus.registered,
          errorMessage: null,
        );
      },
    );
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);

    final params = LoginUsecaseParams(
      email: email,
      password: password,
    );

    final result = await _loginUsecase(params);

    result.fold(
      (failure) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.message,
        );
      },
      (authEntity) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          authEntity: authEntity,
          errorMessage: null,
        );
      },
    );
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading);

    String? idToken;
    try {
      idToken = await _googleAuthService.signIn();
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
      return;
    }

    // User dismissed the Google chooser — return to the idle form state.
    if (idToken == null) {
      state = const AuthState();
      return;
    }

    final result = await _authRepository.signInWithGoogle(idToken);

    result.fold(
      (failure) {
        state = state.copyWith(status: AuthStatus.error, errorMessage: failure.message);
      },
      (authEntity) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          authEntity: authEntity,
          errorMessage: null,
        );
      },
    );
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await _logoutUsecase();

    result.fold(
      (failure) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.message,
        );
      },
      (success) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          authEntity: null,
          errorMessage: null,
        );
      },
    );
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void resetStatus() {
    state = const AuthState();
  }
}
