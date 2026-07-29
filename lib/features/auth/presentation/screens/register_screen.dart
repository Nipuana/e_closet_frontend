import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../common/common.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/utils/validation_utils.dart';
import '../../../main/presentation/screens/main_shell.dart';
import '../state/auth_state.dart';
import '../view_model/auth_view_model.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  static const String _defaultUserType = 'user';

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState!.validate()) {
      final passwordMatch = ValidationUtils.validatePasswordMatch(
        _passwordController.text,
        _confirmPasswordController.text,
      );

      if (passwordMatch != null) {
        SnackBarUtils.showError(context, passwordMatch);
        return;
      }

      ref.read(authViewModelProvider.notifier).register(
            username: _usernameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            userType: _defaultUserType,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final palette = context.palette;

    ref.listen(authViewModelProvider, (previous, next) {
      if (next.status == AuthStatus.registered) {
        SnackBarUtils.showSuccess(context, 'Registration successful! Please login.');
        AppRoutes.pop(context);
      } else if (next.status == AuthStatus.authenticated) {
        // Google sign-up authenticates immediately — go straight to the app.
        SnackBarUtils.showSuccess(context, 'Welcome to E-Closet!');
        AppRoutes.pushAndRemoveUntil(context, const MainShell());
      } else if (next.status == AuthStatus.error) {
        SnackBarUtils.showError(
          context,
          next.errorMessage ?? 'Could not create your account. Please try again.',
        );
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
            // Fit-to-screen layout: vertically centered, sized to the viewport,
            // so the form doesn't scroll in the normal state. The scroll view
            // only kicks in when the keyboard reduces the available height.
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space6),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: AppSpacing.space2),
                      // Logo/Icon
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: palette.surface,
                          border: Border.all(color: AppColors.taupe30, width: 1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                          boxShadow: AppShadows.shadowMd,
                        ),
                        child: const Icon(
                          Icons.checkroom_outlined,
                          color: AppColors.taupe,
                          size: AppSpacing.iconLg,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space4),
                      Text(
                        'Get Started',
                        style: AppTypography.displayLg.copyWith(color: palette.textPrimary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.space1),
                      Text(
                        'Create your account to start organizing',
                        style: AppTypography.bodyLarge.copyWith(color: palette.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.space5),
                      // Form card
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
                                label: 'USERNAME',
                                hint: 'Better Username',
                                controller: _usernameController,
                                prefixIcon: Icons.person_outlined,
                                validator: ValidationUtils.validateUsername,
                              ),
                              const SizedBox(height: AppSpacing.space4),
                              AppTextInput(
                                label: 'EMAIL',
                                hint: 'Email@mail.com',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icons.email_outlined,
                                validator: ValidationUtils.validateEmail,
                              ),
                              const SizedBox(height: AppSpacing.space4),
                              AppTextInput(
                                label: 'PASSWORD',
                                hint: 'Password',
                                controller: _passwordController,
                                obscureText: true,
                                prefixIcon: Icons.lock_outlined,
                                validator: ValidationUtils.validatePassword,
                              ),
                              const SizedBox(height: AppSpacing.space4),
                              AppTextInput(
                                label: 'CONFIRM PASSWORD',
                                hint: 'Confirm Password',
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
                                text: authState.status == AuthStatus.loading ? '' : 'Signup',
                                onPressed: authState.status == AuthStatus.loading
                                    ? null
                                    : _handleRegister,
                                isLoading: authState.status == AuthStatus.loading,
                                isFullWidth: true,
                                size: ButtonSize.large,
                                trailingIcon: Icons.arrow_forward,
                              ),
                              const SizedBox(height: AppSpacing.space4),
                              Row(
                                children: [
                                  const Expanded(child: AppDivider()),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.space4,
                                    ),
                                    child: Text(
                                      'OR CONTINUE WITH',
                                      style: AppTypography.captionSmall.copyWith(
                                        color: palette.textTertiary,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                  const Expanded(child: AppDivider()),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.space4),
                              AppButton(
                                text: 'Sign up with Google',
                                onPressed: authState.status == AuthStatus.loading
                                    ? null
                                    : () => ref
                                        .read(authViewModelProvider.notifier)
                                        .signInWithGoogle(),
                                variant: ButtonVariant.ghost,
                                size: ButtonSize.large,
                                leadingIcon: FontAwesomeIcons.google,
                                isFullWidth: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space4),
                      // Login Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: AppTypography.bodyLarge.copyWith(color: palette.textSecondary),
                          ),
                          GestureDetector(
                            onTap: () => AppRoutes.pop(context),
                            child: Text(
                              'Login',
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
