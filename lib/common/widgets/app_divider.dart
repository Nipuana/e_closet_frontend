import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

enum DividerOrientation { horizontal, vertical }

class AppDivider extends StatelessWidget {
  final DividerOrientation orientation;
  final double thickness;
  final Color? color;
  final String? label;
  final EdgeInsetsGeometry? margin;

  const AppDivider({
    super.key,
    this.orientation = DividerOrientation.horizontal,
    this.thickness = 1.0,
    this.color,
    this.label,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final dividerColor = color ?? context.palette.border;

    if (orientation == DividerOrientation.horizontal) {
      if (label != null) {
        return Container(
          margin: margin ?? EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: Divider(
                  height: thickness,
                  thickness: thickness,
                  color: dividerColor,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  label!,
                  style: AppTypography.labelSmall.copyWith(
                    color: context.palette.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  height: thickness,
                  thickness: thickness,
                  color: dividerColor,
                ),
              ),
            ],
          ),
        );
      }
      return Divider(
        height: thickness + AppSpacing.lg * 2,
        thickness: thickness,
        color: dividerColor,
        indent: 0,
        endIndent: 0,
      );
    } else {
      return SizedBox(
        height: 100,
        child: VerticalDivider(
          width: thickness + AppSpacing.lg * 2,
          thickness: thickness,
          color: dividerColor,
          indent: 0,
          endIndent: 0,
        ),
      );
    }
  }
}
