import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/services/network_info.dart';
import '../../domain/entities/wardrobe_layout_entity.dart';
import '../../domain/repositories/closet_repository.dart';
import '../datasources/closet_remote_datasource.dart';

final closetRepositoryProvider = Provider<IClosetRepository>((ref) {
  return ClosetRepository(
    remoteDatasource: ref.read(closetRemoteDatasourceProvider),
    networkInfo: ref.read(networkInfoProvider),
  );
});

class ClosetRepository implements IClosetRepository {
  final IClosetRemoteDatasource _remoteDatasource;
  final NetworkInfo _networkInfo;

  ClosetRepository({
    required IClosetRemoteDatasource remoteDatasource,
    required NetworkInfo networkInfo,
  })  : _remoteDatasource = remoteDatasource,
        _networkInfo = networkInfo;

  @override
  Future<Either<Failure, List<WardrobeLayoutEntity>>> listLayouts() async {
    if (!await _networkInfo.isConnected) {
      return Left(NoInternetFailure(message: 'No internet connection'));
    }
    try {
      final models = await _remoteDatasource.listLayouts();
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, WardrobeLayoutEntity>> saveLayout(WardrobeLayoutEntity layout) async {
    if (!await _networkInfo.isConnected) {
      return Left(NoInternetFailure(message: 'No internet connection'));
    }
    try {
      final model = await _remoteDatasource.saveLayout(
        layoutId: layout.id,
        name: layout.name,
        cabinetType: layout.cabinetType,
        finish: layout.finish,
        cols: layout.cols,
        rows: layout.rows,
        grid: layout.grid,
        placements: layout.placements,
      );
      return Right(model.toEntity());
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteLayout(String layoutId) async {
    if (!await _networkInfo.isConnected) {
      return Left(NoInternetFailure(message: 'No internet connection'));
    }
    try {
      await _remoteDatasource.deleteLayout(layoutId);
      return const Right(unit);
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }
}
