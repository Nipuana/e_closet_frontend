import '../../domain/entities/outfit_entity.dart';

/// Maps the backend outfit payload (snake_case) to/from the domain entity.
/// Codegen-free manual (de)serialisation, matching the rest of the app.
class OutfitModel {
  final String? outfitId;
  final String userId;
  final String name;
  final List<String> items;
  final DateTime? lastWorn;
  final bool isFavorite;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const OutfitModel({
    this.outfitId,
    required this.userId,
    required this.name,
    this.items = const [],
    this.lastWorn,
    this.isFavorite = false,
    this.createdAt,
    this.updatedAt,
  });

  factory OutfitModel.fromJson(Map<String, dynamic> json) {
    return OutfitModel(
      outfitId: json['outfit_id'] as String?,
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      items: (json['items'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      lastWorn: _parseDate(json['last_worn']),
      isFavorite: json['is_favorite'] as bool? ?? false,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  OutfitEntity toEntity() {
    return OutfitEntity(
      id: outfitId,
      userId: userId,
      name: name,
      items: items,
      lastWorn: lastWorn,
      isFavorite: isFavorite,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
