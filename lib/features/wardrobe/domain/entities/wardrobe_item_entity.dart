import 'package:equatable/equatable.dart';

/// A single piece in the user's wardrobe. Used by the dashboard's
/// "Recently added" and "Favourites" sections.
class WardrobeItemEntity extends Equatable {
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

  const WardrobeItemEntity({
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

  /// Best display title: explicit name, else the sub-category, else category.
  String get displayName =>
      (name != null && name!.isNotEmpty) ? name! : (subCategory ?? category);

  WardrobeItemEntity copyWith({
    String? itemId,
    String? userId,
    String? name,
    String? category,
    String? subCategory,
    String? brand,
    String? material,
    String? color,
    String? season,
    List<String>? colors,
    List<String>? colorPalette,
    String? imageUrl,
    double? purchasePrice,
    int? usageCount,
    List<String>? tags,
    bool? isFavorite,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WardrobeItemEntity(
      itemId: itemId ?? this.itemId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      brand: brand ?? this.brand,
      material: material ?? this.material,
      color: color ?? this.color,
      season: season ?? this.season,
      colors: colors ?? this.colors,
      colorPalette: colorPalette ?? this.colorPalette,
      imageUrl: imageUrl ?? this.imageUrl,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      usageCount: usageCount ?? this.usageCount,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        itemId,
        userId,
        name,
        category,
        subCategory,
        brand,
        material,
        color,
        season,
        colors,
        colorPalette,
        imageUrl,
        purchasePrice,
        usageCount,
        tags,
        isFavorite,
        isArchived,
        createdAt,
        updatedAt,
      ];
}
