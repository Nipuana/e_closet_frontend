import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../common/common.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/utils/validation_utils.dart';
import '../state/forgot_password_state.dart';
import '../view_model/forgot_password_view_model.dart';

/// Step 3 of the reset flow — set a new password using the verified reset token.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      final mismatch = ValidationUtils.validatePasswordMatch(
        _passwordController.text,
        _confirmPasswordController.text,
      );
      if (mismatch != null) {
        SnackBarUtils.showError(context, mismatch);
        return;
      }

      ref.read(forgotPasswordViewModelProvider.notifier).resetPassword(_passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordViewModelProvider);
    final palette = context.palette;
    final isLoading = state.status == ForgotPasswordStatus.loading;

    ref.listen(forgotPasswordViewModelProvider, (previous, next) {
      if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;

      if (next.status == ForgotPasswordStatus.passwordReset) {
        SnackBarUtils.showSuccess(context, next.message ?? 'Password reset successfully');
        // Clear the flow and return to the login screen at the root.
        ref.read(forgotPasswordViewModelProvider.notifier).clear();
        AppRoutes.popToFirst(context);
      } else if (next.status == ForgotPasswordStatus.error) {
        SnackBarUtils.showError(context, next.errorMessage ?? 'Reset failed');
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
                          Icons.password_outlined,
                          color: AppColors.taupe,
                          size: AppSpacing.iconLg,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space4),
                      Text(
                        'New Password',
                        style: AppTypography.displayLg.copyWith(color: palette.textPrimary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.space1),
                      Text(
                        'Choose a new password for your account.',
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
                                label: 'NEW PASSWORD',
                                hint: 'Enter new password',
                                controller: _passwordController,
                                obscureText: true,
                                prefixIcon: Icons.lock_outlined,
                                validator: ValidationUtils.validatePassword,
                              ),
                              const SizedBox(height: AppSpacing.space4),
                              AppTextInput(
                                label: 'CONFIRM PASSWORD',
                                hint: 'Re-enter new password',
                                controller: _confirmPasswordController,
                                obscureText: true,
                                prefixIcon: Icons.lock_outlined,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please confirm your password';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.space5),
                              AppButton(
                                text: isLoading ? '' : 'Reset Password',
                                onPressed: isLoading ? null : _handleSubmit,
                                isLoading: isLoading,
                                isFullWidth: true,
                                size: ButtonSize.large,
                                trailingIcon: Icons.check,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space5),
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
