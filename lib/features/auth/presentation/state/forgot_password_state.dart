import 'package:equatable/equatable.dart';

enum ForgotPasswordStatus {
  initial,
  loading,
  otpSent,
  otpVerified,
  passwordReset,
  error,
}

class ForgotPasswordState extends Equatable {
  final ForgotPasswordStatus status;

  /// Short-lived token returned by verify-otp; consumed by the reset step.
  final String? resetToken;

  /// Informational success message (e.g. from the request-OTP call).
  final String? message;
  final String? errorMessage;

  const ForgotPasswordState({
    this.status = ForgotPasswordStatus.initial,
    this.resetToken,
    this.message,
    this.errorMessage,
  });

  ForgotPasswordState copyWith({
    ForgotPasswordStatus? status,
    String? resetToken,
    String? message,
    String? errorMessage,
  }) {
    return ForgotPasswordState(
      status: status ?? this.status,
      resetToken: resetToken ?? this.resetToken,
      message: message ?? this.message,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, resetToken, message, errorMessage];
}
