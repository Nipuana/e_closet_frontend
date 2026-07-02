import 'package:equatable/equatable.dart';

/// An assembled outfit ("ensemble") — a named set of wardrobe pieces the user
/// has put together. [items] holds the referenced wardrobe item ids; the UI
/// resolves them against the wardrobe to render thumbnails and totals.
class OutfitEntity extends Equatable {
  final String? id;
  final String userId;
  final String name;
  final List<String> items;
  final DateTime? lastWorn;
  final bool isFavorite;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const OutfitEntity({
    this.id,
    this.userId = '',
    required this.name,
    this.items = const [],
    this.lastWorn,
    this.isFavorite = false,
    this.createdAt,
    this.updatedAt,
  });

  int get pieceCount => items.length;

  OutfitEntity copyWith({
    String? id,
    String? userId,
    String? name,
    List<String>? items,
    DateTime? lastWorn,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OutfitEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      items: items ?? this.items,
      lastWorn: lastWorn ?? this.lastWorn,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, name, items, lastWorn, isFavorite, createdAt, updatedAt];
}
