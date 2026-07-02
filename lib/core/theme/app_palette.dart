import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Brightness-aware semantic palette. Screens read structural colors
/// (background / surface / text / border) from `context.palette` so they adapt
/// to light & dark, while brand accents (camel/terracotta) stay constant.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color border;
  final Color accent;
  final Color accentStrong;

  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.accent,
    required this.accentStrong,
  });

  static const AppPalette light = AppPalette(
    background: AppColors.cream,
    surface: AppColors.white,
    surfaceAlt: AppColors.linen,
    textPrimary: AppColors.stone800,
    textSecondary: AppColors.stone500,
    textTertiary: AppColors.stone400,
    border: AppColors.mist,
    accent: AppColors.camel,
    accentStrong: AppColors.terracotta,
  );

  static const AppPalette dark = AppPalette(
    background: Color(0xFF141311),
    surface: Color(0xFF1E1D1A),
    surfaceAlt: Color(0xFF272520),
    textPrimary: Color(0xFFF2EFEA),
    textSecondary: Color(0xFFB7AFA3),
    textTertiary: Color(0xFF8B8377),
    border: Color(0xFF35332E),
    accent: AppColors.camel,
    accentStrong: Color(0xFFC68A63),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? border,
    Color? accent,
    Color? accentStrong,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      border: border ?? this.border,
      accent: accent ?? this.accent,
      accentStrong: accentStrong ?? this.accentStrong,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      border: Color.lerp(border, other.border, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentStrong: Color.lerp(accentStrong, other.accentStrong, t)!,
    );
  }
}

extension AppPaletteX on BuildContext {
  /// Brightness-resolved semantic palette for the current theme.
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
