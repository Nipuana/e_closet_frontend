import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../auth/domain/usecases/usecase.dart';
import '../../data/repositories/wardrobe_repository.dart' as data_repo;
import '../entities/wardrobe_item_entity.dart';
import '../repositories/wardrobe_repository.dart';

class AddItemParams extends Equatable {
  final String? imagePath;
  final String category;
  final String? name;
  final String? subCategory;
  final String? brand;
  final String? material;
  final String? color;
  final String? season;
  final List<String>? colors;
  final double? price;
  final List<String>? tags;

  const AddItemParams({
    this.imagePath,
    required this.category,
    this.name,
    this.subCategory,
    this.brand,
    this.material,
    this.color,
    this.season,
    this.colors,
    this.price,
    this.tags,
  });

  @override
  List<Object?> get props =>
      [imagePath, category, name, subCategory, brand, material, color, season, colors, price, tags];
}

final addItemUsecaseProvider = Provider<AddItemUsecase>((ref) {
  return AddItemUsecase(
    wardrobeRepository: ref.read(data_repo.wardrobeRepositoryProvider),
  );
});

class AddItemUsecase
    implements UsecaseWithParms<WardrobeItemEntity, AddItemParams> {
  final IWardrobeRepository _wardrobeRepository;

  AddItemUsecase({required IWardrobeRepository wardrobeRepository})
      : _wardrobeRepository = wardrobeRepository;

  @override
  Future<Either<Failure, WardrobeItemEntity>> call(AddItemParams params) {
    return _wardrobeRepository.addItem(
      imagePath: params.imagePath,
      category: params.category,
      name: params.name,
      subCategory: params.subCategory,
      brand: params.brand,
      material: params.material,
      color: params.color,
      season: params.season,
      colors: params.colors,
      price: params.price,
      tags: params.tags,
    );
  }
}
