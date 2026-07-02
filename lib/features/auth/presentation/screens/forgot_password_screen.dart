import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../common/common.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/utils/validation_utils.dart';
import '../state/forgot_password_state.dart';
import '../view_model/forgot_password_view_model.dart';
import 'verify_otp_screen.dart';

/// Step 1 of the reset flow — collect the account email and request an OTP.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      ref.read(forgotPasswordViewModelProvider.notifier).sendOtp(_emailController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordViewModelProvider);
    final palette = context.palette;
    final isLoading = state.status == ForgotPasswordStatus.loading;

    ref.listen(forgotPasswordViewModelProvider, (previous, next) {
      // Only the top-most screen should react to the shared flow state.
      if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;

      if (next.status == ForgotPasswordStatus.otpSent) {
        final email = _emailController.text.trim();
        SnackBarUtils.showSuccess(context, next.message ?? 'Verification code sent');
        ref.read(forgotPasswordViewModelProvider.notifier).resetStatus();
        AppRoutes.push(context, VerifyOtpScreen(email: email));
      } else if (next.status == ForgotPasswordStatus.error) {
        SnackBarUtils.showError(context, next.errorMessage ?? 'Something went wrong');
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
                          Icons.lock_reset_outlined,
                          color: AppColors.taupe,
                          size: AppSpacing.iconLg,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space4),
                      Text(
                        'Forgot Password',
                        style: AppTypography.displayLg.copyWith(color: palette.textPrimary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.space1),
                      Text(
                        'Enter your email and we’ll send you a verification code to reset your password.',
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
                                label: 'EMAIL',
                                hint: 'your@email.com',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icons.email_outlined,
                                validator: ValidationUtils.validateEmail,
                              ),
                              const SizedBox(height: AppSpacing.space5),
                              AppButton(
                                text: isLoading ? '' : 'Send Code',
                                onPressed: isLoading ? null : _handleSubmit,
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
                            'Remembered it? ',
                            style: AppTypography.bodyLarge.copyWith(color: palette.textSecondary),
                          ),
                          GestureDetector(
                            onTap: () => AppRoutes.pop(context),
                            child: Text(
                              'Back to Login',
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
