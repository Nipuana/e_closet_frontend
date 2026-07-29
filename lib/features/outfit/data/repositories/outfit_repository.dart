import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_messages.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/network_info.dart';
import '../../domain/entities/outfit_entity.dart';
import '../../domain/repositories/outfit_repository.dart';
import '../datasources/outfit_remote_datasource.dart';

final outfitRepositoryProvider = Provider<IOutfitRepository>((ref) {
  return OutfitRepository(
    remoteDatasource: ref.read(outfitRemoteDatasourceProvider),
    networkInfo: ref.read(networkInfoProvider),
  );
});

class OutfitRepository implements IOutfitRepository {
  final IOutfitRemoteDatasource _remoteDatasource;
  final NetworkInfo _networkInfo;

  OutfitRepository({
    required IOutfitRemoteDatasource remoteDatasource,
    required NetworkInfo networkInfo,
  })  : _remoteDatasource = remoteDatasource,
        _networkInfo = networkInfo;

  @override
  Future<Either<Failure, List<OutfitEntity>>> listOutfits() async {
    if (!await _networkInfo.isConnected) {
      return Left(NoInternetFailure(message: kNoInternetFailure));
    }
    try {
      final models = await _remoteDatasource.listOutfits();
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ApiFailure(message: userFacingError(e)));
    }
  }

  @override
  Future<Either<Failure, OutfitEntity>> createOutfit({
    required String name,
    required List<String> items,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Left(NoInternetFailure(message: kNoInternetFailure));
    }
    try {
      final model = await _remoteDatasource.createOutfit(name: name, items: items);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ApiFailure(message: userFacingError(e)));
    }
  }

  @override
  Future<Either<Failure, OutfitEntity>> updateOutfit({
    required String outfitId,
    String? name,
    List<String>? items,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Left(NoInternetFailure(message: kNoInternetFailure));
    }
    try {
      final model = await _remoteDatasource.updateOutfit(
        outfitId: outfitId,
        name: name,
        items: items,
      );
      return Right(model.toEntity());
    } catch (e) {
      return Left(ApiFailure(message: userFacingError(e)));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteOutfit(String outfitId) async {
    if (!await _networkInfo.isConnected) {
      return Left(NoInternetFailure(message: kNoInternetFailure));
    }
    try {
      await _remoteDatasource.deleteOutfit(outfitId);
      return const Right(unit);
    } catch (e) {
      return Left(ApiFailure(message: userFacingError(e)));
    }
  }

  @override
  Future<Either<Failure, Unit>> wearOutfit(String outfitId) async {
    if (!await _networkInfo.isConnected) {
      return Left(NoInternetFailure(message: kNoInternetFailure));
    }
    try {
      await _remoteDatasource.wearOutfit(outfitId);
      return const Right(unit);
    } catch (e) {
      return Left(ApiFailure(message: userFacingError(e)));
    }
  }
}
