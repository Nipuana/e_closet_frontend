import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_messages.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/network_info.dart';
import '../../domain/entities/brand_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/catalog_remote_datasource.dart';

final catalogRepositoryProvider = Provider<ICatalogRepository>((ref) {
  return CatalogRepository(
    remoteDatasource: ref.read(catalogRemoteDatasourceProvider),
    networkInfo: ref.read(networkInfoProvider),
  );
});

class CatalogRepository implements ICatalogRepository {
  final ICatalogRemoteDatasource _remoteDatasource;
  final NetworkInfo _networkInfo;

  CatalogRepository({
    required ICatalogRemoteDatasource remoteDatasource,
    required NetworkInfo networkInfo,
  })  : _remoteDatasource = remoteDatasource,
        _networkInfo = networkInfo;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    if (!await _networkInfo.isConnected) {
      return Left(NoInternetFailure(message: kNoInternetFailure));
    }
    try {
      return Right(await action());
    } catch (e) {
      return Left(ApiFailure(message: userFacingError(e)));
    }
  }

  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories() =>
      _guard(() async => (await _remoteDatasource.getCategories()).map((m) => m.toEntity()).toList());

  @override
  Future<Either<Failure, CategoryEntity>> createCategory(String name) =>
      _guard(() async => (await _remoteDatasource.createCategory(name)).toEntity());

  @override
  Future<Either<Failure, List<BrandEntity>>> getBrands() =>
      _guard(() async => (await _remoteDatasource.getBrands()).map((m) => m.toEntity()).toList());

  @override
  Future<Either<Failure, BrandEntity>> createBrand(String name) =>
      _guard(() async => (await _remoteDatasource.createBrand(name)).toEntity());
}
