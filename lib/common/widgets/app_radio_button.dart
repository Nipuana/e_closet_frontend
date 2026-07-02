import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class AppRadioButton<T> extends StatelessWidget {
  final String label;
  final T value;
  final T? groupValue;
  final ValueChanged<T?> onChanged;
  final bool isDisabled;
  final String? helperText;

  const AppRadioButton({
    super.key,
    required this.label,
    required this.value,
    required this.groupValue,
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
          onTap: isDisabled ? null : () => onChanged(value),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // RadioGroup (Flutter 3.32+) replaces the deprecated
              // Radio.groupValue/onChanged. Each button manages its own
              // group so the widget's public API stays unchanged.
              RadioGroup<T>(
                groupValue: groupValue,
                onChanged: onChanged,
                child: Radio<T>(
                  value: value,
                  enabled: !isDisabled,
                  fillColor: WidgetStateProperty.resolveWith<Color>(
                    (Set<WidgetState> states) {
                      if (states.contains(WidgetState.disabled)) {
                        return AppColors.borderDefault;
                      }
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.primaryDefault;
                      }
                      return AppColors.bgPrimary;
                    },
                  ),
                  activeColor: AppColors.primaryDefault,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDisabled ? AppColors.textDisabled : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (helperText != null) ...[
          SizedBox(height: AppSpacing.sm),
          Padding(
            padding: EdgeInsets.only(left: 24 + AppSpacing.md),
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
