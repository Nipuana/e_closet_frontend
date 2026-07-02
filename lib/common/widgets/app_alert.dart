import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

enum AlertVariant { success, warning, error, info }

class AppAlert extends StatelessWidget {
  final String title;
  final String message;
  final AlertVariant variant;
  final VoidCallback? onClose;
  final Widget? action;
  final bool showIcon;

  const AppAlert({
    super.key,
    required this.title,
    required this.message,
    this.variant = AlertVariant.info,
    this.onClose,
    this.action,
    this.showIcon = true,
  });

  Color _getBackgroundColor() {
    switch (variant) {
      case AlertVariant.success:
        return AppColors.successLight;
      case AlertVariant.warning:
        return AppColors.warningLight;
      case AlertVariant.error:
        return AppColors.errorLight;
      case AlertVariant.info:
        return AppColors.infoLight;
    }
  }

  Color _getBorderColor() {
    switch (variant) {
      case AlertVariant.success:
        return AppColors.successDefault;
      case AlertVariant.warning:
        return AppColors.warningDefault;
      case AlertVariant.error:
        return AppColors.errorDefault;
      case AlertVariant.info:
        return AppColors.infoDefault;
    }
  }

  Color _getTextColor() {
    switch (variant) {
      case AlertVariant.success:
        return AppColors.successDark;
      case AlertVariant.warning:
        return AppColors.warningDark;
      case AlertVariant.error:
        return AppColors.errorDark;
      case AlertVariant.info:
        return AppColors.infoDark;
    }
  }

  IconData _getIcon() {
    switch (variant) {
      case AlertVariant.success:
        return Icons.check_circle_outlined;
      case AlertVariant.warning:
        return Icons.warning_outlined;
      case AlertVariant.error:
        return Icons.error_outlined;
      case AlertVariant.info:
        return Icons.info_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        border: Border(left: BorderSide(color: _getBorderColor(), width: 4)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showIcon) ...[
                Icon(
                  _getIcon(),
                  color: _getTextColor(),
                  size: AppSpacing.iconMd,
                ),
                SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.labelLarge.copyWith(
                        color: _getTextColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      message,
                      style: AppTypography.bodySmall.copyWith(
                        color: _getTextColor(),
                      ),
                    ),
                  ],
                ),
              ),
              if (onClose != null) ...[
                SizedBox(width: AppSpacing.md),
                GestureDetector(
                  onTap: onClose,
                  child: Icon(
                    Icons.close,
                    color: _getTextColor(),
                    size: AppSpacing.iconMd,
                  ),
                ),
              ],
            ],
          ),
          if (action != null) ...[
            SizedBox(height: AppSpacing.md),
            action!,
          ],
        ],
      ),
    );
  }
}
