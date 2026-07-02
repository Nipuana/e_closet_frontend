import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../common/common.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/utils/validation_utils.dart';
import '../state/auth_state.dart';
import '../view_model/auth_view_model.dart';
import '../../../main/presentation/screens/main_shell.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      ref.read(authViewModelProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final palette = context.palette;

    ref.listen(authViewModelProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        SnackBarUtils.showSuccess(context, 'Login successful!');
        AppRoutes.pushAndRemoveUntil(context, const MainShell());
      } else if (next.status == AuthStatus.error) {
        SnackBarUtils.showError(context, next.errorMessage ?? 'Login failed');
      }
    });

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Fit-to-screen: content is vertically centered and sized to the
            // viewport, so nothing scrolls in the normal state. The scroll view
            // only engages when the keyboard shrinks the available height.
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space6),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: AppSpacing.space6),
                      // Logo/Icon
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
                          Icons.checkroom_outlined,
                          color: AppColors.taupe,
                          size: AppSpacing.iconLg,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space4),
                      Text(
                        'Welcome Back',
                        style: AppTypography.displayLg.copyWith(color: palette.textPrimary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.space1),
                      Text(
                        'Sign in to access your wardrobe',
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
                                label: 'EMAIL',
                                hint: 'your@email.com',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icons.email_outlined,
                                validator: ValidationUtils.validateEmail,
                              ),
                              const SizedBox(height: AppSpacing.space4),
                              AppTextInput(
                                label: 'PASSWORD',
                                hint: 'Enter your password',
                                controller: _passwordController,
                                obscureText: true,
                                prefixIcon: Icons.lock_outlined,
                                validator: ValidationUtils.validatePassword,
                              ),
                              const SizedBox(height: AppSpacing.space2),
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: () => AppRoutes.push(
                                    context,
                                    const ForgotPasswordScreen(),
                                  ),
                                  child: Text(
                                    'Forgot Password?',
                                    style: AppTypography.labelMedium.copyWith(
                                      color: palette.accentStrong,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.space4),
                              AppButton(
                                text: authState.status == AuthStatus.loading ? '' : 'Login',
                                onPressed: authState.status == AuthStatus.loading
                                    ? null
                                    : _handleLogin,
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
                                text: 'Continue with Google',
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
                      // Sign Up Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: AppTypography.bodyLarge.copyWith(color: palette.textSecondary),
                          ),
                          GestureDetector(
                            onTap: () => AppRoutes.push(context, const RegisterScreen()),
                            child: Text(
                              'Sign Up',
                              style: AppTypography.bodyLarge.copyWith(
                                color: palette.accentStrong,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.space6),
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
