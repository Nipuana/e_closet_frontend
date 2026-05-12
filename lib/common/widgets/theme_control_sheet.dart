import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme.dart';
import '../../core/theme/theme_mode_provider.dart';

/// Appearance switcher shown when the user shakes the device. Lets them pick
/// system / light / dark, applied app-wide via [themeModeProvider].
class ThemeControlSheet extends ConsumerWidget {
  const ThemeControlSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final controller = ref.read(themeModeProvider.notifier);
    final palette = context.palette;

    return SafeArea(
      child: Padding(
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
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space5),
            Row(
              children: [
                Icon(Icons.brightness_6_outlined,
                    color: palette.accentStrong, size: AppSpacing.iconSm),
                const SizedBox(width: AppSpacing.space2),
                Text(
                  'Appearance',
                  style: AppTypography.headingLarge.copyWith(color: palette.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              'Shake to open this anytime. Choose how E-Closet looks.',
              style: AppTypography.bodyMedium.copyWith(color: palette.textSecondary),
            ),
            const SizedBox(height: AppSpacing.space5),
            _ThemeOption(
              icon: Icons.brightness_auto_outlined,
              label: 'System default',
              description: 'Match your device setting',
              selected: mode == ThemeMode.system,
              onTap: () => controller.setMode(ThemeMode.system),
            ),
            const SizedBox(height: AppSpacing.space3),
            _ThemeOption(
              icon: Icons.light_mode_outlined,
              label: 'Light',
              description: 'Bright, warm neutrals',
              selected: mode == ThemeMode.light,
              onTap: () => controller.setMode(ThemeMode.light),
            ),
            const SizedBox(height: AppSpacing.space3),
            _ThemeOption(
              icon: Icons.dark_mode_outlined,
              label: 'Dark',
              description: 'Low-light, ink surfaces',
              selected: mode == ThemeMode.dark,
              onTap: () => controller.setMode(ThemeMode.dark),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: selected ? palette.surfaceAlt : palette.surface,
      borderRadius: AppRadius.lg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lg,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space3,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.lg,
            border: Border.all(
              color: selected ? palette.accent : palette.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: AppSpacing.iconSm,
                  color: selected ? palette.accentStrong : palette.textSecondary),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.labelLarge.copyWith(color: palette.textPrimary),
                    ),
                    Text(
                      description,
                      style: AppTypography.captionSmall.copyWith(color: palette.textTertiary),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, color: palette.accent, size: AppSpacing.iconSm),
            ],
          ),
        ),
      ),
    );
  }
}
