import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class AppCheckbox extends StatefulWidget {
  final String? label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isIndeterminate;
  final bool isDisabled;
  final String? helperText;

  const AppCheckbox({
    super.key,
    this.label,
    required this.value,
    required this.onChanged,
    this.isIndeterminate = false,
    this.isDisabled = false,
    this.helperText,
  });

  @override
  State<AppCheckbox> createState() => _AppCheckboxState();
}

class _AppCheckboxState extends State<AppCheckbox> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: widget.isDisabled ? null : () => widget.onChanged(!widget.value),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: widget.isIndeterminate ? null : widget.value,
                onChanged: widget.isDisabled
                    ? null
                    : (value) {
                        widget.onChanged(value ?? false);
                      },
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
              side: const BorderSide(color: AppColors.borderDefault, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              ),
              if (widget.label != null) ...[
                SizedBox(width: AppSpacing.md),
                Flexible(
                  child: Text(
                    widget.label!,
                    style: AppTypography.bodyMedium.copyWith(
                      color: widget.isDisabled
                          ? AppColors.textDisabled
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (widget.helperText != null) ...[
          SizedBox(height: AppSpacing.sm),
          Padding(
            padding: EdgeInsets.only(left: 32 + AppSpacing.md),
            child: Text(
              widget.helperText!,
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
