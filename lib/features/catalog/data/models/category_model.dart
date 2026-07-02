import '../../domain/entities/category_entity.dart';

class CategoryModel {
  final String categoryId;
  final String? userId;
  final String name;
  final List<String> subcategories;

  CategoryModel({
    required this.categoryId,
    this.userId,
    required this.name,
    this.subcategories = const [],
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      categoryId: (json['category_id'] ?? json['_id'] ?? '').toString(),
      userId: json['user_id'] as String?,
      name: (json['name'] ?? '').toString(),
      subcategories: (json['subcategories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  CategoryEntity toEntity() => CategoryEntity(
        categoryId: categoryId,
        userId: userId,
        name: name,
        subcategories: subcategories,
      );
}
