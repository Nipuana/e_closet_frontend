import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';

enum CardVariant { default_, elevated, outlined }

class AppCard extends StatelessWidget {
  final Widget child;
  final CardVariant variant;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const AppCard({
    super.key,
    required this.child,
    this.variant = CardVariant.default_,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.border,
    this.boxShadow,
  });

  BoxDecoration _getDecoration(BuildContext context) {
    final palette = context.palette;
    final surface = backgroundColor ?? palette.surface;
    switch (variant) {
      case CardVariant.default_:
        return BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: border ?? Border.all(color: palette.border, width: 1),
          boxShadow: boxShadow,
        );
      case CardVariant.elevated:
        return BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: border,
          boxShadow: boxShadow ??
              [
                BoxShadow(
                  color: AppColors.shadowDefault,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
        );
      case CardVariant.outlined:
        return BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: border ?? Border.all(color: palette.border, width: 2),
          boxShadow: boxShadow,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        decoration: _getDecoration(context),
        child: Padding(
          padding: padding ??
              AppSpacing.paddingLg,
          child: child,
        ),
      ),
    );
  }
}
