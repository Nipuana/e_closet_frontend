import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../common/common.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../state/forgot_password_state.dart';
import '../view_model/forgot_password_view_model.dart';
import 'reset_password_screen.dart';

/// Step 2 of the reset flow — enter the 6-digit code emailed to [email].
class VerifyOtpScreen extends ConsumerStatefulWidget {
  final String email;

  const VerifyOtpScreen({super.key, required this.email});

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _handleVerify() {
    if (_formKey.currentState!.validate()) {
      ref.read(forgotPasswordViewModelProvider.notifier).verifyOtp(
            email: widget.email,
            otp: _otpController.text.trim(),
          );
    }
  }

  void _handleResend() {
    ref.read(forgotPasswordViewModelProvider.notifier).sendOtp(widget.email);
  }

  String? _validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter the 6-digit code';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'Code must be 6 digits';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordViewModelProvider);
    final palette = context.palette;
    final isLoading = state.status == ForgotPasswordStatus.loading;

    ref.listen(forgotPasswordViewModelProvider, (previous, next) {
      if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;

      if (next.status == ForgotPasswordStatus.otpVerified) {
        ref.read(forgotPasswordViewModelProvider.notifier).resetStatus();
        AppRoutes.push(context, ResetPasswordScreen(email: widget.email));
      } else if (next.status == ForgotPasswordStatus.otpSent) {
        // Resend succeeded.
        SnackBarUtils.showSuccess(context, 'A new code has been sent');
        ref.read(forgotPasswordViewModelProvider.notifier).resetStatus();
      } else if (next.status == ForgotPasswordStatus.error) {
        SnackBarUtils.showError(context, next.errorMessage ?? 'Verification failed');
      }
    });

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: AppSpacing.iconSm),
          color: palette.textPrimary,
          onPressed: () => AppRoutes.pop(context),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space6),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: palette.surface,
                          border: Border.all(color: AppColors.taupe30, width: 1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                          boxShadow: AppShadows.shadowMd,
                        ),
                        child: const Icon(
                          Icons.mark_email_read_outlined,
                          color: AppColors.taupe,
                          size: AppSpacing.iconLg,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space4),
                      Text(
                        'Enter Code',
                        style: AppTypography.displayLg.copyWith(color: palette.textPrimary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.space1),
                      Text(
                        'We sent a 6-digit verification code to\n${widget.email}',
                        style: AppTypography.bodyLarge.copyWith(color: palette.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.space5),
                      AppCard(
                        variant: CardVariant.elevated,
                        boxShadow: AppShadows.shadowMd,
                        padding: const EdgeInsets.all(AppSpacing.space5),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppTextInput(
                                label: 'VERIFICATION CODE',
                                hint: '000000',
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                prefixIcon: Icons.pin_outlined,
                                validator: _validateOtp,
                                onChanged: (value) {
                                  // Auto-submit once six digits are entered.
                                  if (value.trim().length == 6 && !isLoading) {
                                    FocusScope.of(context).unfocus();
                                    _handleVerify();
                                  }
                                },
                              ),
                              const SizedBox(height: AppSpacing.space5),
                              AppButton(
                                text: isLoading ? '' : 'Verify',
                                onPressed: isLoading ? null : _handleVerify,
                                isLoading: isLoading,
                                isFullWidth: true,
                                size: ButtonSize.large,
                                trailingIcon: Icons.arrow_forward,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Didn't get it? ",
                            style: AppTypography.bodyLarge.copyWith(color: palette.textSecondary),
                          ),
                          GestureDetector(
                            onTap: isLoading ? null : _handleResend,
                            child: Text(
                              'Resend Code',
                              style: AppTypography.bodyLarge.copyWith(
                                color: palette.accentStrong,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.space4),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
