import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/session_manager.dart';
import '../core/theme/theme.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/main/presentation/screens/main_shell.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import 'app.dart';

/// The app's first route. It renders nothing visible — the native (OS) splash
/// is held on screen (see `main.dart`) while we restore the session, then we
/// route to the app and drop the splash. This replaces the old animated
/// Flutter SplashScreen; the branding now lives entirely in the native splash.
class StartupGate extends ConsumerStatefulWidget {
  const StartupGate({super.key});

  @override
  ConsumerState<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends ConsumerState<StartupGate> {
  static const _minSplash = Duration(milliseconds: 1600);

  @override
  void initState() {
    super.initState();
    // Global "session expired" redirect (fires on any 401).
    ref.read(sessionManagerProvider).onSessionExpired = _redirectToLogin;
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  void _redirectToLogin() {
    appNavigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _boot() async {
    // Restore any persisted session while the branded native splash shows for
    // at least [_minSplash] so it doesn't flash by.
    final restore = ref.read(sessionManagerProvider).restoreSession();
    await Future<void>.delayed(_minSplash);
    final isLoggedIn = await restore;
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => isLoggedIn ? const MainShell() : const OnboardingScreen(),
      ),
    );
    // Reveal the app only once the destination's first frame is rendered.
    WidgetsBinding.instance.addPostFrameCallback((_) => FlutterNativeSplash.remove());
  }

  @override
  Widget build(BuildContext context) {
    // Invisible beneath the preserved native splash; bone matches it if seen.
    return const Scaffold(backgroundColor: AppColors.bone);
  }
}
