import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../common/common.dart';
import '../../../../core/theme/theme.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../auth/presentation/screens/register_screen.dart';

/// First-run onboarding: a 3-slide carousel. The primary button reads "Next"
/// while there are more slides and becomes "Get started" on the last one, which
/// opens a sheet offering sign up or log in.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_SlideData> _slides = [
    _SlideData(
      icon: Icons.checkroom_outlined,
      tileColor: AppColors.taupe,
      iconColor: AppColors.white,
      title: 'Your wardrobe,\nquietly curated.',
      body: 'Digitize every piece you own and keep your whole closet in one '
          'elegant place.',
    ),
    _SlideData(
      icon: Icons.dry_cleaning_outlined,
      tileColor: AppColors.charcoal,
      iconColor: AppColors.taupeLight,
      title: 'Plan ensembles\nwith intention.',
      body: 'Compose outfits ahead of time and never wonder what to wear '
          'again.',
    ),
    _SlideData(
      icon: Icons.insights_outlined,
      tileColor: AppColors.navy,
      iconColor: AppColors.white80,
      title: 'Know what you\ntruly wear.',
      body: 'Cost-per-wear and favourites reveal the pieces that earn their '
          'place.',
    ),
  ];

  bool get _isLastPage => _currentPage == _slides.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPrimaryPressed() {
    if (_isLastPage) {
      _showAuthSheet();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _showAuthSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.palette.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.topOnly),
      builder: (sheetContext) => _AuthSheet(
        onCreateAccount: () {
          Navigator.of(sheetContext).pop();
          AppRoutes.push(context, const RegisterScreen());
        },
        onLogin: () {
          Navigator.of(sheetContext).pop();
          AppRoutes.push(context, const LoginScreen());
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    // Tighter vertical gaps in landscape so the slide keeps enough height.
    final double controlGap = isLandscape ? AppSpacing.space3 : AppSpacing.space6;
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              children: [
                // ── Skip (always available; opens the auth sheet) ──
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.space2,
                    right: AppSpacing.space3,
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showAuthSheet,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space3,
                          vertical: AppSpacing.space2,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Skip',
                        style: AppTypography.labelMedium.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                // ── Slides ──
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemBuilder: (context, index) => _Slide(data: _slides[index]),
                  ),
                ),
                // ── Dots ──
                SizedBox(height: controlGap),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (i) {
                    final active = i == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 22 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: active ? palette.accent : palette.border,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                    );
                  }),
                ),
                // ── Primary action ──
                SizedBox(height: controlGap),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space6),
                  child: AppButton(
                    text: _isLastPage ? 'Get started' : 'Next',
                    onPressed: _onPrimaryPressed,
                    isFullWidth: true,
                    size: ButtonSize.large,
                    trailingIcon: _isLastPage ? null : Icons.arrow_forward,
                  ),
                ),
                SizedBox(height: isLandscape ? AppSpacing.space3 : AppSpacing.space5),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideData {
  final IconData icon;
  final Color tileColor;
  final Color iconColor;
  final String title;
  final String body;

  const _SlideData({
    required this.icon,
    required this.tileColor,
    required this.iconColor,
    required this.title,
    required this.body,
  });
}

class _Slide extends StatelessWidget {
  final _SlideData data;

  const _Slide({required this.data});

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final hero = Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: data.tileColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppShadows.shadowMd,
      ),
      alignment: Alignment.center,
      child: Icon(data.icon, size: isLandscape ? 56 : 72, color: data.iconColor),
    );

    final copy = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'E — CLOSET',
          style: AppTypography.labelSmall.copyWith(
            color: context.palette.accentStrong,
            letterSpacing: 3.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
        Text(
          data.title,
          style: AppTypography.displayLg.copyWith(color: context.palette.textPrimary),
        ),
        const SizedBox(height: AppSpacing.space3),
        Text(
          data.body,
          style: AppTypography.bodyLarge.copyWith(color: context.palette.textSecondary),
        ),
      ],
    );

    // Landscape: hero and copy sit side by side so the short height still fits;
    // the copy scrolls within its column if it can't (never clips).
    if (isLandscape) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space6,
          AppSpacing.space2,
          AppSpacing.space6,
          AppSpacing.space2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(flex: 4, child: hero),
            const SizedBox(width: AppSpacing.space6),
            Expanded(
              flex: 6,
              child: Center(
                child: SingleChildScrollView(child: copy),
              ),
            ),
          ],
        ),
      );
    }

    // Portrait: hero stacked above the copy.
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space6,
        AppSpacing.space2,
        AppSpacing.space6,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: hero),
          const SizedBox(height: AppSpacing.space8),
          copy,
        ],
      ),
    );
  }
}

/// Bottom sheet offering the two entry paths into the app.
class _AuthSheet extends StatelessWidget {
  final VoidCallback onCreateAccount;
  final VoidCallback onLogin;

  const _AuthSheet({required this.onCreateAccount, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space6,
          AppSpacing.space4,
          AppSpacing.space6,
          AppSpacing.space6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grab handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.palette.border,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space5),
            Text(
              'Welcome to E-Closet',
              style: AppTypography.headingLarge.copyWith(color: context.palette.textPrimary),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              'Create an account or sign in to start building your wardrobe.',
              style: AppTypography.bodyMedium.copyWith(color: context.palette.textSecondary),
            ),
            const SizedBox(height: AppSpacing.space6),
            AppButton(
              text: 'Create account',
              onPressed: onCreateAccount,
              isFullWidth: true,
              size: ButtonSize.large,
              trailingIcon: Icons.arrow_forward,
            ),
            const SizedBox(height: AppSpacing.space3),
            AppButton(
              text: 'I already have an account',
              onPressed: onLogin,
              variant: ButtonVariant.ghost,
              isFullWidth: true,
              size: ButtonSize.large,
            ),
          ],
        ),
      ),
    );
  }
}
