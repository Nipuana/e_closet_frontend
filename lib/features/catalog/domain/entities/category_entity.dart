import 'package:equatable/equatable.dart';

/// A wardrobe category — global preset (userId == null) or user-owned.
class CategoryEntity extends Equatable {
  final String categoryId;
  final String? userId;
  final String name;
  final List<String> subcategories;

  const CategoryEntity({
    required this.categoryId,
    this.userId,
    required this.name,
    this.subcategories = const [],
  });

  bool get isCustom => userId != null;

  @override
  List<Object?> get props => [categoryId, userId, name, subcategories];
}
