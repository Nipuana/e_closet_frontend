import 'package:flutter/material.dart';

import '../theme/theme.dart';

class SnackBarUtils {
  const SnackBarUtils._();

  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message,
      background: AppColors.success,
      icon: Icons.check_circle_outline,
      duration: const Duration(seconds: 2),
    );
  }

  static void showError(BuildContext context, String message) {
    _show(
      context,
      message,
      background: AppColors.danger,
      icon: Icons.error_outline,
      duration: const Duration(seconds: 3),
    );
  }

  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message,
      background: AppColors.info,
      icon: Icons.info_outline,
      duration: const Duration(seconds: 2),
    );
  }

  static void showWarning(BuildContext context, String message) {
    _show(
      context,
      message,
      background: AppColors.warning,
      icon: Icons.warning_amber_outlined,
      duration: const Duration(seconds: 2),
    );
  }

  static void _show(
    BuildContext context,
    String message, {
    required Color background,
    required IconData icon,
    required Duration duration,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: AppColors.white, size: AppSpacing.iconSm),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: background,
          behavior: SnackBarBehavior.floating,
          elevation: 6,
          duration: duration,
          margin: const EdgeInsets.all(AppSpacing.space4),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space3,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
        ),
      );
  }
}
