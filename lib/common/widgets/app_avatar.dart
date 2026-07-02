import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

enum AvatarSize { small, medium, large, xlarge }

class AppAvatar extends StatelessWidget {
  final String? initials;
  final ImageProvider<Object>? image;
  final Color? backgroundColor;
  final Color? textColor;
  final AvatarSize size;
  final Border? border;
  final VoidCallback? onTap;

  const AppAvatar({
    super.key,
    this.initials,
    this.image,
    this.backgroundColor,
    this.textColor,
    this.size = AvatarSize.medium,
    this.border,
    this.onTap,
  }) : assert(initials != null || image != null, 'Either initials or image must be provided');

  double _getSize() {
    switch (size) {
      case AvatarSize.small:
        return AppSpacing.iconLg;
      case AvatarSize.medium:
        return 40.0;
      case AvatarSize.large:
        return 48.0;
      case AvatarSize.xlarge:
        return 56.0;
    }
  }

  double _getFontSize() {
    switch (size) {
      case AvatarSize.small:
        return AppTypography.labelSmall.fontSize ?? 12;
      case AvatarSize.medium:
        return AppTypography.labelMedium.fontSize ?? 13;
      case AvatarSize.large:
        return AppTypography.labelLarge.fontSize ?? 14;
      case AvatarSize.xlarge:
        return AppTypography.bodyMedium.fontSize ?? 14;
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarSize = _getSize();

    Widget avatar = Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? AppColors.primaryDefault,
        image: image != null
            ? DecorationImage(
                image: image!,
                fit: BoxFit.cover,
              )
            : null,
        border: border ?? Border.all(color: Colors.transparent, width: 2),
      ),
      child: image == null
          ? Center(
              child: Text(
                initials ?? '?',
                style: TextStyle(
                  fontSize: _getFontSize(),
                  fontWeight: FontWeight.w600,
                  color: textColor ?? AppColors.textInverse,
                ),
              ),
            )
          : null,
    );

    if (onTap != null) {
      avatar = GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }
}
