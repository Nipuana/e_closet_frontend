import 'package:equatable/equatable.dart';

/// A brand — global preset (userId == null) or user-owned.
class BrandEntity extends Equatable {
  final String brandId;
  final String? userId;
  final String name;

  const BrandEntity({required this.brandId, this.userId, required this.name});

  bool get isCustom => userId != null;

  @override
  List<Object?> get props => [brandId, userId, name];
}
