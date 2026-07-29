import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_messages.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/network_info.dart';
import '../../domain/entities/wardrobe_item_entity.dart';
import '../../domain/repositories/wardrobe_repository.dart';
import '../datasources/wardrobe_datasource.dart';
import '../datasources/wardrobe_remote_datasource.dart';

final wardrobeRepositoryProvider = Provider<IWardrobeRepository>((ref) {
  return WardrobeRepository(
    remoteDatasource: ref.read(wardrobeRemoteDatasourceProvider),
    networkInfo: ref.read(networkInfoProvider),
  );
});

class WardrobeRepository implements IWardrobeRepository {
  final IWardrobeRemoteDatasource _remoteDatasource;
  final NetworkInfo _networkInfo;

  WardrobeRepository({
    required IWardrobeRemoteDatasource remoteDatasource,
    required NetworkInfo networkInfo,
  })  : _remoteDatasource = remoteDatasource,
        _networkInfo = networkInfo;

  @override
  Future<Either<Failure, WardrobeItemEntity>> addItem({
    String? imagePath,
    required String category,
    String? name,
    String? subCategory,
    String? brand,
    String? material,
    String? color,
    String? season,
    List<String>? colors,
    double? price,
    List<String>? tags,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Left(NoInternetFailure(message: kNoInternetFailure));
    }
    try {
      final model = await _remoteDatasource.addItem(
        imagePath: imagePath,
        category: category,
        name: name,
        subCategory: subCategory,
        brand: brand,
        material: material,
        color: color,
        season: season,
        colors: colors,
        price: price,
        tags: tags,
      );
      return Right(model.toEntity());
    } catch (e) {
      return Left(ApiFailure(message: userFacingError(e)));
    }
  }

  @override
  Future<Either<Failure, WardrobeItemEntity>> updateItem({
    required String itemId,
    required String category,
    String? name,
    String? subCategory,
    String? brand,
    String? material,
    String? color,
    String? season,
    List<String>? colors,
    double? price,
    List<String>? tags,
    String? imagePath,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Left(NoInternetFailure(message: kNoInternetFailure));
    }
    try {
      final model = await _remoteDatasource.updateItem(
        itemId: itemId,
        category: category,
        name: name,
        subCategory: subCategory,
        brand: brand,
        material: material,
        color: color,
        season: season,
        colors: colors,
        price: price,
        tags: tags,
        imagePath: imagePath,
      );
      return Right(model.toEntity());
    } catch (e) {
      return Left(ApiFailure(message: userFacingError(e)));
    }
  }

  @override
  Future<Either<Failure, List<WardrobeItemEntity>>> getAllItems() async {
    if (!await _networkInfo.isConnected) {
      return Left(NoInternetFailure(message: kNoInternetFailure));
    }
    try {
      final models = await _remoteDatasource.getAllItems();
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ApiFailure(message: userFacingError(e)));
    }
  }

  @override
  Future<Either<Failure, List<WardrobeItemEntity>>> getRecentItems({int limit = 10}) async {
    if (!await _networkInfo.isConnected) {
      return Left(NoInternetFailure(message: kNoInternetFailure));
    }
    try {
      final models = await _remoteDatasource.getRecentItems(limit: limit);
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ApiFailure(message: userFacingError(e)));
    }
  }

  @override
  Future<Either<Failure, List<WardrobeItemEntity>>> getFavoriteItems({int? limit}) async {
    if (!await _networkInfo.isConnected) {
      return Left(NoInternetFailure(message: kNoInternetFailure));
    }
    try {
      final models = await _remoteDatasource.getFavoriteItems(limit: limit);
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ApiFailure(message: userFacingError(e)));
    }
  }

  @override
  Future<Either<Failure, WardrobeItemEntity>> getItem(String itemId) async {
    if (!await _networkInfo.isConnected) {
      return Left(NoInternetFailure(message: kNoInternetFailure));
    }
    try {
      final model = await _remoteDatasource.getItem(itemId);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ApiFailure(message: userFacingError(e)));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteItem(String itemId) async {
    if (!await _networkInfo.isConnected) {
      return Left(NoInternetFailure(message: kNoInternetFailure));
    }
    try {
      await _remoteDatasource.deleteItem(itemId);
      return const Right(unit);
    } catch (e) {
      return Left(ApiFailure(message: userFacingError(e)));
    }
  }

  @override
  Future<Either<Failure, WardrobeItemEntity>> markWorn(String itemId) async {
    if (!await _networkInfo.isConnected) {
      return Left(NoInternetFailure(message: kNoInternetFailure));
    }
    try {
      final model = await _remoteDatasource.markWorn(itemId);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ApiFailure(message: userFacingError(e)));
    }
  }

  @override
  Future<Either<Failure, WardrobeItemEntity>> toggleFavorite({
    required String itemId,
    required bool isFavorite,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Left(NoInternetFailure(message: kNoInternetFailure));
    }
    try {
      final model = await _remoteDatasource.toggleFavorite(
        itemId: itemId,
        isFavorite: isFavorite,
      );
      return Right(model.toEntity());
    } catch (e) {
      return Left(ApiFailure(message: userFacingError(e)));
    }
  }
}
