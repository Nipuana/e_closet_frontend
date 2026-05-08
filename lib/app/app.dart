import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../common/widgets/shake_theme_gate.dart';
import '../../core/theme/theme_mode_provider.dart';
import 'startup_gate.dart';

final appNavigatorKey = GlobalKey<NavigatorState>();

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'E-Closet',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      home: const StartupGate(),
      // Shake anywhere (sustained ~1.22s) to open the appearance switcher.
      builder: (context, child) =>
          ShakeThemeGate(child: child ?? const SizedBox.shrink()),
    );
  }
}
