import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

enum InputSize { small, medium, large }

class AppTextInput extends StatefulWidget {
  final String? label;
  final String hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final InputSize size;
  final int maxLines;
  final int minLines;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final bool obscureText;
  final String? helperText;
  final String? errorText;
  final bool isReadOnly;
  final ValueChanged<String>? onChanged;
  final InputDecoration? customDecoration;

  const AppTextInput({
    super.key,
    this.label,
    required this.hint,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.size = InputSize.medium,
    this.maxLines = 1,
    this.minLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.obscureText = false,
    this.helperText,
    this.errorText,
    this.isReadOnly = false,
    this.onChanged,
    this.customDecoration,
  });

  @override
  State<AppTextInput> createState() => _AppTextInputState();
}

class _AppTextInputState extends State<AppTextInput> {
  late bool _showPassword;

  @override
  void initState() {
    super.initState();
    _showPassword = !widget.obscureText;
  }

  // Vertical content padding tuned per size so the field reaches the intended
  // touch height without an outer fixed-height box (which would clip the
  // validation error text rendered beneath the field).
  double _getVerticalPadding() {
    switch (widget.size) {
      case InputSize.small:
        return AppSpacing.space2;
      case InputSize.medium:
        return AppSpacing.space3;
      case InputSize.large:
        return AppSpacing.space4;
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case InputSize.small:
        return AppSpacing.iconSm;
      case InputSize.medium:
        return AppSpacing.iconMd;
      case InputSize.large:
        return AppSpacing.iconMd;
    }
  }

  TextStyle _getInputTextStyle() {
    switch (widget.size) {
      case InputSize.small:
        return AppTypography.bodySmall;
      case InputSize.medium:
        return AppTypography.bodyMedium;
      case InputSize.large:
        return AppTypography.bodyLarge;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTypography.labelSmall.copyWith(
              color: palette.textSecondary,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.space2),
        ],
        TextFormField(
            controller: widget.controller,
            validator: widget.validator,
            keyboardType: widget.keyboardType,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            obscureText: !_showPassword && widget.obscureText,
            readOnly: widget.isReadOnly,
            onChanged: widget.onChanged,
            style: _getInputTextStyle().copyWith(
              color: palette.textPrimary,
            ),
            decoration: widget.customDecoration ??
                InputDecoration(
                  hintText: widget.hint,
                  hintStyle: _getInputTextStyle().copyWith(
                    color: palette.textTertiary,
                  ),
                  helperText: widget.helperText,
                  helperStyle: AppTypography.captionSmall.copyWith(
                    color: palette.textSecondary,
                  ),
                  errorText: widget.errorText,
                  errorStyle: AppTypography.captionSmall.copyWith(
                    color: AppColors.errorDefault,
                  ),
                  prefixIcon: widget.prefixIcon != null
                      ? Padding(
                          padding: EdgeInsets.only(
                            left: AppSpacing.paddingMdValue,
                            right: AppSpacing.paddingSmValue,
                          ),
                          child: Icon(
                            widget.prefixIcon,
                            size: _getIconSize(),
                            color: palette.textSecondary,
                          ),
                        )
                      : null,
                  suffixIcon: widget.obscureText
                      ? Padding(
                          padding: EdgeInsets.only(
                            right: AppSpacing.paddingMdValue,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _showPassword = !_showPassword;
                              });
                            },
                            child: Icon(
                              _showPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: _getIconSize(),
                              color: palette.textSecondary,
                            ),
                          ),
                        )
                      : widget.suffixIcon != null
                          ? Padding(
                              padding: EdgeInsets.only(
                                right: AppSpacing.paddingMdValue,
                              ),
                              child: GestureDetector(
                                onTap: widget.onSuffixIconPressed,
                                child: Icon(
                                  widget.suffixIcon,
                                  size: _getIconSize(),
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            )
                          : null,
                  isDense: true,
                  filled: true,
                  fillColor: palette.surface,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.paddingMdValue,
                    vertical: _getVerticalPadding(),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide(
                      color: palette.border,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide(
                      color: palette.border,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: const BorderSide(
                      color: AppColors.borderFocused,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: const BorderSide(
                      color: AppColors.errorDefault,
                      width: 1,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: const BorderSide(
                      color: AppColors.errorDefault,
                      width: 2,
                    ),
                  ),
                ),
          ),
      ],
    );
  }
}
