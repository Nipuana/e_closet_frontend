import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../data/repositories/catalog_repository.dart';
import '../entities/brand_entity.dart';
import '../entities/category_entity.dart';
import '../repositories/catalog_repository.dart';

final getCategoriesUsecaseProvider = Provider<GetCategoriesUsecase>(
    (ref) => GetCategoriesUsecase(ref.read(catalogRepositoryProvider)));
final createCategoryUsecaseProvider = Provider<CreateCategoryUsecase>(
    (ref) => CreateCategoryUsecase(ref.read(catalogRepositoryProvider)));
final getBrandsUsecaseProvider = Provider<GetBrandsUsecase>(
    (ref) => GetBrandsUsecase(ref.read(catalogRepositoryProvider)));
final createBrandUsecaseProvider = Provider<CreateBrandUsecase>(
    (ref) => CreateBrandUsecase(ref.read(catalogRepositoryProvider)));

class GetCategoriesUsecase {
  final ICatalogRepository _repo;
  GetCategoriesUsecase(this._repo);
  Future<Either<Failure, List<CategoryEntity>>> call() => _repo.getCategories();
}

class CreateCategoryUsecase {
  final ICatalogRepository _repo;
  CreateCategoryUsecase(this._repo);
  Future<Either<Failure, CategoryEntity>> call(String name) => _repo.createCategory(name);
}

class GetBrandsUsecase {
  final ICatalogRepository _repo;
  GetBrandsUsecase(this._repo);
  Future<Either<Failure, List<BrandEntity>>> call() => _repo.getBrands();
}

class CreateBrandUsecase {
  final ICatalogRepository _repo;
  CreateBrandUsecase(this._repo);
  Future<Either<Failure, BrandEntity>> call(String name) => _repo.createBrand(name);
}
