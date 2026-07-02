import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app.dart';
import '../../core/services/shake_detector.dart';
import '../../core/theme/theme.dart';
import 'theme_control_sheet.dart';

/// Wraps the app so a sustained shake anywhere opens the [ThemeControlSheet].
/// Mounted via [MaterialApp.builder], so it covers every screen.
class ShakeThemeGate extends ConsumerStatefulWidget {
  final Widget child;

  const ShakeThemeGate({super.key, required this.child});

  @override
  ConsumerState<ShakeThemeGate> createState() => _ShakeThemeGateState();
}

class _ShakeThemeGateState extends ConsumerState<ShakeThemeGate> {
  late final ShakeDetector _detector;
  bool _sheetOpen = false;

  @override
  void initState() {
    super.initState();
    _detector = ShakeDetector(onShake: _openThemeSheet)..start();
  }

  @override
  void dispose() {
    _detector.dispose();
    super.dispose();
  }

  void _openThemeSheet() {
    if (_sheetOpen) return;
    // Use the navigator's context (guaranteed below the Navigator/Overlay).
    final ctx = appNavigatorKey.currentContext;
    if (ctx == null) return;

    _sheetOpen = true;
    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Theme.of(ctx).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.topOnly),
      builder: (_) => const ThemeControlSheet(),
    ).whenComplete(() => _sheetOpen = false);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
