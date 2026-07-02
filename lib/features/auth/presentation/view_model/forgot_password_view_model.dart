import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../state/forgot_password_state.dart';

final forgotPasswordViewModelProvider =
    NotifierProvider<ForgotPasswordViewModel, ForgotPasswordState>(
  () => ForgotPasswordViewModel(),
);

/// Drives the three-step reset flow: request OTP → verify OTP → set password.
class ForgotPasswordViewModel extends Notifier<ForgotPasswordState> {
  late IAuthRepository _authRepository;

  @override
  ForgotPasswordState build() {
    _authRepository = ref.read(authRepositoryProvider);
    return const ForgotPasswordState();
  }

  /// Step 1 — email a verification code to [email].
  Future<void> sendOtp(String email) async {
    state = state.copyWith(status: ForgotPasswordStatus.loading, errorMessage: null);

    final result = await _authRepository.requestPasswordReset(email);

    result.fold(
      (failure) => state = state.copyWith(
        status: ForgotPasswordStatus.error,
        errorMessage: failure.message,
      ),
      (message) => state = state.copyWith(
        status: ForgotPasswordStatus.otpSent,
        message: message,
        errorMessage: null,
      ),
    );
  }

  /// Step 2 — verify [otp] for [email] and capture the reset token.
  Future<void> verifyOtp({required String email, required String otp}) async {
    state = state.copyWith(status: ForgotPasswordStatus.loading, errorMessage: null);

    final result = await _authRepository.verifyOtp(email: email, otp: otp);

    result.fold(
      (failure) => state = state.copyWith(
        status: ForgotPasswordStatus.error,
        errorMessage: failure.message,
      ),
      (token) => state = state.copyWith(
        status: ForgotPasswordStatus.otpVerified,
        resetToken: token,
        errorMessage: null,
      ),
    );
  }

  /// Step 3 — set the new password using the token from [verifyOtp].
  Future<void> resetPassword(String newPassword) async {
    final token = state.resetToken;
    if (token == null || token.isEmpty) {
      state = state.copyWith(
        status: ForgotPasswordStatus.error,
        errorMessage: 'Session expired. Please restart the reset process.',
      );
      return;
    }

    state = state.copyWith(status: ForgotPasswordStatus.loading, errorMessage: null);

    final result = await _authRepository.resetPassword(token: token, newPassword: newPassword);

    result.fold(
      (failure) => state = state.copyWith(
        status: ForgotPasswordStatus.error,
        errorMessage: failure.message,
      ),
      (message) => state = state.copyWith(
        status: ForgotPasswordStatus.passwordReset,
        message: message,
        errorMessage: null,
      ),
    );
  }

  /// Return to the pre-request state (e.g. after a snackbar was shown) so
  /// screens can re-run a step without a stale success/error status lingering.
  void resetStatus() {
    state = state.copyWith(status: ForgotPasswordStatus.initial, errorMessage: null);
  }

  void clear() {
    state = const ForgotPasswordState();
  }
}
