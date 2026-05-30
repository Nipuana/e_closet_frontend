import '../../domain/entities/wardrobe_item_entity.dart';

/// Maps the backend wardrobe item payload (snake_case) to/from the domain entity.
/// Uses manual (de)serialisation to stay codegen-free.
class WardrobeItemApiModel {
  final String itemId;
  final String userId;
  final String? name;
  final String category;
  final String? subCategory;
  final String? brand;
  final String? material;
  final String? color;
  final String? season;
  final List<String> colors;
  final List<String> colorPalette;
  final String imageUrl;
  final double? purchasePrice;
  final int usageCount;
  final List<String> tags;
  final bool isFavorite;
  final bool isArchived;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WardrobeItemApiModel({
    required this.itemId,
    required this.userId,
    this.name,
    required this.category,
    this.subCategory,
    this.brand,
    this.material,
    this.color,
    this.season,
    this.colors = const [],
    this.colorPalette = const [],
    required this.imageUrl,
    this.purchasePrice,
    this.usageCount = 0,
    this.tags = const [],
    this.isFavorite = false,
    this.isArchived = false,
    this.createdAt,
    this.updatedAt,
  });

  factory WardrobeItemApiModel.fromJson(Map<String, dynamic> json) {
    return WardrobeItemApiModel(
      itemId: json['item_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String?,
      category: json['category'] as String? ?? '',
      subCategory: json['sub_category'] as String?,
      brand: json['brand'] as String?,
      material: json['material'] as String?,
      color: json['color'] as String?,
      season: json['season'] as String?,
      colors: (json['colors'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const [],
      colorPalette: (json['color_palette'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      imageUrl: json['image_url'] as String? ?? '',
      purchasePrice: (json['purchase_price'] as num?)?.toDouble(),
      usageCount: (json['usage_count'] as num?)?.toInt() ?? 0,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const [],
      isFavorite: json['is_favorite'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? false,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  WardrobeItemEntity toEntity() {
    return WardrobeItemEntity(
      itemId: itemId,
      userId: userId,
      name: name,
      category: category,
      subCategory: subCategory,
      brand: brand,
      material: material,
      color: color,
      season: season,
      colors: colors,
      colorPalette: colorPalette,
      imageUrl: imageUrl,
      purchasePrice: purchasePrice,
      usageCount: usageCount,
      tags: tags,
      isFavorite: isFavorite,
      isArchived: isArchived,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
