import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';

/// Lightweight editorial placeholder for tabs whose full screens are not yet
/// built. Keeps the shell navigable while matching the design system.
class TabPlaceholder extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;

  const TabPlaceholder({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: AppSpacing.paddingHorizontalLg,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: palette.surfaceAlt,
                    borderRadius: AppRadius.lg,
                  ),
                  child: Icon(icon, color: palette.accent, size: AppSpacing.iconLg),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  eyebrow,
                  style: AppTypography.labelSmall.copyWith(
                    color: palette.accent,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.headingLarge.copyWith(color: palette.textPrimary),
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(color: palette.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
