import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

enum BadgeVariant {
  primary,
  secondary,
  success,
  warning,
  error,
  info,
  neutral,
}

class AppBadge extends StatelessWidget {
  final String label;
  final BadgeVariant variant;
  final IconData? icon;
  final VoidCallback? onClose;

  const AppBadge({
    super.key,
    required this.label,
    this.variant = BadgeVariant.primary,
    this.icon,
    this.onClose,
  });

  Color _getBackgroundColor() {
    switch (variant) {
      case BadgeVariant.primary:
        return AppColors.primaryDefault.withValues(alpha: 0.1);
      case BadgeVariant.secondary:
        return AppColors.secondaryDefault.withValues(alpha: 0.1);
      case BadgeVariant.success:
        return AppColors.successLight;
      case BadgeVariant.warning:
        return AppColors.warningLight;
      case BadgeVariant.error:
        return AppColors.errorLight;
      case BadgeVariant.info:
        return AppColors.infoLight;
      case BadgeVariant.neutral:
        return AppColors.bgTertiary;
    }
  }

  Color _getTextColor() {
    switch (variant) {
      case BadgeVariant.primary:
        return AppColors.primaryDefault;
      case BadgeVariant.secondary:
        return AppColors.secondaryDefault;
      case BadgeVariant.success:
        return AppColors.successDefault;
      case BadgeVariant.warning:
        return AppColors.warningDefault;
      case BadgeVariant.error:
        return AppColors.errorDefault;
      case BadgeVariant.info:
        return AppColors.infoDefault;
      case BadgeVariant.neutral:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCircle),
      ),
      // Compact internal spacing from the primitive grid (the large editorial
      // tokens would balloon a chip and over-space its icon).
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space1,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: AppSpacing.iconXs,
              color: _getTextColor(),
            ),
            const SizedBox(width: AppSpacing.space1),
          ],
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: _getTextColor(),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onClose != null) ...[
            const SizedBox(width: AppSpacing.space1),
            GestureDetector(
              onTap: onClose,
              child: Icon(
                Icons.close,
                size: AppSpacing.iconSm,
                color: _getTextColor(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
