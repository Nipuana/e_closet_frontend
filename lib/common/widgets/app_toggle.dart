import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class AppToggle extends StatelessWidget {
  final String? label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDisabled;
  final String? helperText;

  const AppToggle({
    super.key,
    this.label,
    required this.value,
    required this.onChanged,
    this.isDisabled = false,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: isDisabled ? null : () => onChanged(!value),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: value,
                onChanged: isDisabled ? null : onChanged,
                activeThumbColor: AppColors.primaryDefault,
                inactiveThumbColor: AppColors.borderDefault,
                inactiveTrackColor: AppColors.bgTertiary,
                activeTrackColor: AppColors.primaryDefault.withValues(alpha: 0.3),
              ),
              if (label != null) ...[
                SizedBox(width: AppSpacing.md),
                Flexible(
                  child: Text(
                    label!,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDisabled ? AppColors.textDisabled : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (helperText != null) ...[
          SizedBox(height: AppSpacing.sm),
          Padding(
            padding: EdgeInsets.only(left: 48 + AppSpacing.md),
            child: Text(
              helperText!,
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
