import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

enum ButtonVariant { primary, secondary, destructive, ghost }
enum ButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final double? customWidth;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.leadingIcon,
    this.trailingIcon,
    this.customWidth,
  });

  Color _getBackgroundColor(AppPalette palette) {
    switch (variant) {
      case ButtonVariant.primary:
        // Black/ink CTA in light mode; flips to a light fill in dark mode so it
        // never disappears against the background (palette-aware).
        return onPressed == null ? AppColors.primaryDisabled : palette.textPrimary;
      case ButtonVariant.secondary:
        return palette.surfaceAlt;
      case ButtonVariant.destructive:
        return onPressed == null ? AppColors.errorLight : AppColors.errorDefault;
      case ButtonVariant.ghost:
        return Colors.transparent;
    }
  }

  Color _getTextColor(AppPalette palette) {
    switch (variant) {
      case ButtonVariant.primary:
        // Inverse of the (textPrimary) fill — light text on the dark button.
        return palette.background;
      case ButtonVariant.secondary:
        return palette.textPrimary;
      case ButtonVariant.destructive:
        return onPressed == null ? AppColors.textDisabled : Colors.white;
      case ButtonVariant.ghost:
        return palette.textPrimary;
    }
  }

  Color? _getBorderColor(AppPalette palette) {
    switch (variant) {
      case ButtonVariant.primary:
        return null;
      case ButtonVariant.secondary:
        return palette.border;
      case ButtonVariant.destructive:
        return null;
      case ButtonVariant.ghost:
        return palette.border;
    }
  }

  double _getHeight() {
    switch (size) {
      case ButtonSize.small:
        return AppSpacing.buttonHeightSm;
      case ButtonSize.medium:
        return AppSpacing.buttonHeightMd;
      case ButtonSize.large:
        return AppSpacing.buttonHeightLg;
    }
  }

  // Icons sized to sit just above the label so text and glyph read as one
  // unit (not the oversized 24/32px content icons).
  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 18;
      case ButtonSize.large:
        return 20;
    }
  }

  // Horizontal padding uses the fine primitive grid (NOT the large editorial
  // layout tokens) so content never exceeds the fixed button height.
  double _getHorizontalPadding() {
    switch (size) {
      case ButtonSize.small:
        return AppSpacing.space4; // 16
      case ButtonSize.medium:
        return AppSpacing.space5; // 20
      case ButtonSize.large:
        return AppSpacing.space6; // 24
    }
  }

  TextStyle _getTextStyle(AppPalette palette) {
    // height: 1.0 collapses the line box to the glyph so the label centers
    // cleanly against the icon (the default 1.5 leading offset the baseline).
    final color = _getTextColor(palette);
    switch (size) {
      case ButtonSize.small:
        return AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          height: 1.0,
        );
      case ButtonSize.medium:
        return AppTypography.labelLarge.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          height: 1.0,
        );
      case ButtonSize.large:
        return AppTypography.bodyLarge.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          height: 1.0,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = isFullWidth ? double.infinity : customWidth;
    final isPrimary = variant == ButtonVariant.primary;
    final palette = context.palette;
    final borderColor = _getBorderColor(palette);

    return SizedBox(
      width: width,
      height: _getHeight(),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getBackgroundColor(palette),
          disabledBackgroundColor: AppColors.primaryDisabled,
          disabledForegroundColor: AppColors.white,
          foregroundColor: _getTextColor(palette),
          side: borderColor != null
              ? BorderSide(color: borderColor, width: 1)
              : null,
          // Pill shape per the design system's button style.
          shape: const StadiumBorder(),
          // Vertical padding is 0 — the fixed SizedBox height defines the
          // button height and the Row centers content within it.
          padding: EdgeInsets.symmetric(
            horizontal: _getHorizontalPadding(),
            vertical: 0,
          ),
          // Keep the content tap target tidy inside the fixed height.
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          // Subtle lift on the filled primary button; flat for the rest.
          elevation: isPrimary && onPressed != null ? 2 : 0,
          shadowColor: isPrimary ? AppColors.black20 : Colors.transparent,
          overlayColor: _getTextColor(palette).withValues(alpha: 0.08),
        ),
        child: isLoading
            ? SizedBox(
                width: _getIconSize(),
                height: _getIconSize(),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(_getTextColor(palette)),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leadingIcon != null) ...[
                    Icon(leadingIcon, size: _getIconSize()),
                    SizedBox(width: AppSpacing.space2),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      style: _getTextStyle(palette),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    SizedBox(width: AppSpacing.space2),
                    Icon(trailingIcon, size: _getIconSize()),
                  ],
                ],
              ),
      ),
    );
  }
}
