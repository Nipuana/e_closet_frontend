import '../../domain/entities/brand_entity.dart';

class BrandModel {
  final String brandId;
  final String? userId;
  final String name;

  BrandModel({required this.brandId, this.userId, required this.name});

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      brandId: (json['brand_id'] ?? json['_id'] ?? '').toString(),
      userId: json['user_id'] as String?,
      name: (json['name'] ?? '').toString(),
    );
  }

  BrandEntity toEntity() => BrandEntity(brandId: brandId, userId: userId, name: name);
}
