import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Global Material theme wired to the E-Closet "bone / stone / taupe"
/// editorial design system. Every default Material surface (app bars, dialogs,
/// snackbars, text selection, inputs) inherits these brand tokens.
class AppTheme {
  AppTheme._();

  // ─────────────────────────────────────────────
  // Light Theme
  // ─────────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.stone800,
        onPrimary: AppColors.white,
        secondary: AppColors.taupe,
        onSecondary: AppColors.white,
        tertiary: AppColors.taupeDark,
        surface: AppColors.white,
        onSurface: AppColors.stone800,
        surfaceContainerHighest: AppColors.stone100,
        error: AppColors.danger,
        onError: AppColors.white,
        outline: AppColors.stone200,
      ),
    );

    return base.copyWith(
      extensions: const <ThemeExtension<dynamic>>[AppPalette.light],
      textTheme: _textTheme(base.textTheme, AppColors.stone800, AppColors.stone500),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.stone800,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: AppColors.stone700, size: AppSpacing.iconMd),
      ),
      inputDecorationTheme: _inputDecorationTheme(
        fill: AppColors.white,
        border: AppColors.border,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.stone200,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: _snackBarTheme(),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.topOnly),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.taupe,
        selectionColor: AppColors.taupe30,
        selectionHandleColor: AppColors.taupe,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.taupe,
      ),
      iconTheme: const IconThemeData(color: AppColors.stone600),
      splashColor: AppColors.taupe12,
      highlightColor: AppColors.taupe12,
    );
  }

  // ─────────────────────────────────────────────
  // Dark Theme
  // ─────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.stone800,
        secondary: AppColors.taupe,
        onSecondary: AppColors.white,
        tertiary: AppColors.taupeLight,
        surface: AppColors.darkCard,
        onSurface: AppColors.darkForeground,
        surfaceContainerHighest: AppColors.darkSecondary,
        error: AppColors.danger,
        onError: AppColors.white,
        outline: AppColors.darkBorder,
      ),
    );

    return base.copyWith(
      extensions: const <ThemeExtension<dynamic>>[AppPalette.dark],
      textTheme: _textTheme(
        base.textTheme,
        AppColors.darkForeground,
        AppColors.darkMutedForeground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkForeground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      inputDecorationTheme: _inputDecorationTheme(
        fill: AppColors.darkInputBackground,
        border: AppColors.darkBorder,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: _snackBarTheme(),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.taupe,
        selectionColor: AppColors.taupe30,
        selectionHandleColor: AppColors.taupe,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.taupe,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────
  static TextTheme _textTheme(TextTheme base, Color primary, Color secondary) {
    return base.copyWith(
      displayLarge: AppTypography.displayXl.copyWith(color: primary),
      displayMedium: AppTypography.displayLg.copyWith(color: primary),
      displaySmall: AppTypography.headingXlarge.copyWith(color: primary),
      headlineMedium: AppTypography.headingLarge.copyWith(color: primary),
      headlineSmall: AppTypography.headingMedium.copyWith(color: primary),
      titleLarge: AppTypography.headingMedium.copyWith(color: primary),
      titleMedium: AppTypography.headingSmall.copyWith(color: primary),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: primary),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: primary),
      bodySmall: AppTypography.bodySmall.copyWith(color: secondary),
      labelLarge: AppTypography.labelLarge.copyWith(color: primary),
      labelMedium: AppTypography.labelMedium.copyWith(color: primary),
      labelSmall: AppTypography.labelSmall.copyWith(color: secondary),
    );
  }

  static InputDecorationTheme _inputDecorationTheme({
    required Color fill,
    required Color border,
  }) {
    OutlineInputBorder outline(Color color, double width) => OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      // Use the primitive grid for the field interior — the large editorial
      // layout tokens (paddingMdValue == 24) make default inputs over-tall.
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space4,
      ),
      hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
      border: outline(border, 1),
      enabledBorder: outline(border, 1),
      focusedBorder: outline(AppColors.taupe, 2),
      errorBorder: outline(AppColors.danger, 1),
      focusedErrorBorder: outline(AppColors.danger, 2),
    );
  }

  static SnackBarThemeData _snackBarTheme() {
    return SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.stone800,
      contentTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.white),
      actionTextColor: AppColors.taupeLight,
      elevation: 6,
      insetPadding: const EdgeInsets.all(AppSpacing.paddingMdValue),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
    );
  }
}
