import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/theme/theme.dart';
import '../../../wardrobe/domain/entities/wardrobe_item_entity.dart';

/// Resolve a (possibly relative) wardrobe image path to an absolute URL.
String resolveItemImageUrl(String url) {
  if (url.isEmpty) return '';
  if (url.startsWith('http')) return url;
  return '${ApiEndpoints.serverAddress}$url';
}

/// Common colour names → swatch, so an item with no image still renders a
/// representative block (the design shows outfits as colour collages).
const Map<String, Color> _namedColors = {
  'camel': AppColors.camel,
  'tan': AppColors.camel,
  'oat': AppColors.sand,
  'sand': AppColors.sand,
  'beige': AppColors.linen,
  'cream': AppColors.cream,
  'ivory': AppColors.cream,
  'white': AppColors.white,
  'linen': AppColors.linen,
  'terracotta': AppColors.terracotta,
  'rust': AppColors.terracotta,
  'brown': AppColors.terracotta,
  'navy': AppColors.navy,
  'blue': AppColors.navy,
  'slate': AppColors.slate,
  'grey': AppColors.slate,
  'gray': AppColors.slate,
  'charcoal': AppColors.slate,
  'black': AppColors.black,
  'ink': AppColors.ink,
  'sage': Color(0xFF9CA98C),
  'green': Color(0xFF9CA98C),
};

Color? _hexToColor(String value) {
  var hex = value.trim().replaceAll('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  if (hex.length != 8) return null;
  final intVal = int.tryParse(hex, radix: 16);
  return intVal == null ? null : Color(intVal);
}

/// Best representative colour for an item: a palette hex if present, else a
/// named colour, else a neutral fallback.
Color itemColor(WardrobeItemEntity item, AppPalette palette) {
  for (final hex in item.colorPalette) {
    final c = _hexToColor(hex);
    if (c != null) return c;
  }
  final name = (item.color ?? '').toLowerCase().trim();
  if (name.isNotEmpty) {
    for (final entry in _namedColors.entries) {
      if (name.contains(entry.key)) return entry.value;
    }
  }
  return palette.surfaceAlt;
}

/// Single piece cell — image if available, else a colour block fallback.
class OutfitItemCell extends StatelessWidget {
  final WardrobeItemEntity item;
  const OutfitItemCell({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final url = resolveItemImageUrl(item.imageUrl);
    final fallback = ColoredBox(color: itemColor(item, palette));
    if (url.isEmpty) return fallback;
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      // These render as small collage tiles — decode accordingly, not full-res.
      memCacheWidth: 300,
      placeholder: (_, _) => fallback,
      errorWidget: (_, _, _) => fallback,
    );
  }
}

/// A compact preview collage of an outfit — up to four pieces laid out as a
/// grid, mirroring the ensemble cards in the design. [items] are the resolved
/// wardrobe pieces for the outfit (already filtered to those that exist).
class OutfitThumbnail extends StatelessWidget {
  final List<WardrobeItemEntity> items;
  const OutfitThumbnail({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    if (items.isEmpty) {
      return ColoredBox(
        color: palette.surfaceAlt,
        child: Icon(Icons.checkroom_outlined, color: palette.textTertiary),
      );
    }

    final shown = items.take(4).toList();
    // 1 piece → full bleed; 2 → side by side; 3/4 → 2×2 grid.
    final crossAxisCount = shown.length == 1 ? 1 : 2;
    return GridView.count(
      crossAxisCount: crossAxisCount,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      mainAxisSpacing: 0,
      crossAxisSpacing: 0,
      children: [for (final item in shown) OutfitItemCell(item: item)],
    );
  }
}
