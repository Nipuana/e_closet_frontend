import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/brand_entity.dart';
import '../entities/category_entity.dart';

abstract interface class ICatalogRepository {
  Future<Either<Failure, List<CategoryEntity>>> getCategories();
  Future<Either<Failure, CategoryEntity>> createCategory(String name);
  Future<Either<Failure, List<BrandEntity>>> getBrands();
  Future<Either<Failure, BrandEntity>> createBrand(String name);
}
