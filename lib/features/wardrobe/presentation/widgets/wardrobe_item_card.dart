import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/wardrobe_item_entity.dart';

/// Compact wardrobe item tile used in the dashboard's horizontal feeds.
/// Shows the item image, category, and a tappable favourite heart.
class WardrobeItemCard extends StatelessWidget {
  final WardrobeItemEntity item;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onTap;

  const WardrobeItemCard({
    super.key,
    required this.item,
    this.onFavoriteToggle,
    this.onTap,
  });

  String get _resolvedImageUrl {
    final url = item.imageUrl;
    if (url.startsWith('http')) return url;
    // Uploaded images are served from the server root (/uploads/...), not /api.
    return '${ApiEndpoints.serverAddress}$url';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 132,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.radiusLg),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: context.palette.surfaceAlt,
                      child: _resolvedImageUrl.isEmpty
                          ? _placeholder()
                          : CachedNetworkImage(
                              imageUrl: _resolvedImageUrl,
                              fit: BoxFit.cover,
                              // Decode at the small feed-thumbnail size, not the
                              // full photo resolution.
                              memCacheWidth: 360,
                              placeholder: (_, _) => _placeholder(),
                              errorWidget: (_, _, _) => _placeholder(),
                            ),
                    ),
                    Positioned(
                      top: AppSpacing.space2,
                      right: AppSpacing.space2,
                      child: _FavoriteButton(
                        isFavorite: item.isFavorite,
                        onTap: onFavoriteToggle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              item.category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(color: context.palette.textPrimary),
            ),
            if (item.subCategory != null && item.subCategory!.isNotEmpty)
              Text(
                item.subCategory!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.captionSmall.copyWith(color: context.palette.textTertiary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => const Center(
        child: Icon(
          Icons.checkroom_outlined,
          color: AppColors.stone300,
          size: AppSpacing.iconLg,
        ),
      );
}

class _FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback? onTap;

  const _FavoriteButton({required this.isFavorite, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: context.palette.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          size: AppSpacing.iconXs,
          color: isFavorite ? AppColors.danger : context.palette.textTertiary,
        ),
      ),
    );
  }
}
