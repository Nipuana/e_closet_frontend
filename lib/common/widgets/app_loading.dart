import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

enum LoadingVariant { circular, linear, skeleton }

class AppLoading extends StatelessWidget {
  final LoadingVariant variant;
  final String? message;
  final Color? color;
  final double size;
  final double strokeWidth;

  const AppLoading({
    super.key,
    this.variant = LoadingVariant.circular,
    this.message,
    this.color,
    this.size = 48.0,
    this.strokeWidth = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case LoadingVariant.circular:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  color ?? AppColors.primaryDefault,
                ),
                strokeWidth: strokeWidth,
              ),
            ),
            if (message != null) ...[
              SizedBox(height: AppSpacing.md),
              Text(
                message!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        );
      case LoadingVariant.linear:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 4,
              child: LinearProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  color ?? AppColors.primaryDefault,
                ),
                backgroundColor: AppColors.borderDefault,
              ),
            ),
            if (message != null) ...[
              SizedBox(height: AppSpacing.md),
              Text(
                message!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        );
      case LoadingVariant.skeleton:
        return SingleChildScrollView(
          child: Column(
            children: List.generate(
              3,
              (index) => Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.md),
                child: Container(
                  width: double.infinity,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.bgTertiary,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
              ),
            ),
          ),
        );
    }
  }
}
