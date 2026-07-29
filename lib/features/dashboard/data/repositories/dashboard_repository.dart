import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error_messages.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/network_info.dart';
import '../../domain/entities/dashboard_overview_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';

final dashboardRepositoryProvider = Provider<IDashboardRepository>((ref) {
  return DashboardRepository(
    remoteDatasource: ref.read(dashboardRemoteDatasourceProvider),
    networkInfo: ref.read(networkInfoProvider),
  );
});

class DashboardRepository implements IDashboardRepository {
  final IDashboardRemoteDatasource _remoteDatasource;
  final NetworkInfo _networkInfo;

  DashboardRepository({
    required IDashboardRemoteDatasource remoteDatasource,
    required NetworkInfo networkInfo,
  })  : _remoteDatasource = remoteDatasource,
        _networkInfo = networkInfo;

  @override
  Future<Either<Failure, DashboardOverviewEntity>> getOverview() async {
    if (!await _networkInfo.isConnected) {
      return Left(NoInternetFailure(message: kNoInternetFailure));
    }
    try {
      final model = await _remoteDatasource.getOverview();
      return Right(model.toEntity());
    } catch (e) {
      return Left(ApiFailure(message: userFacingError(e)));
    }
  }
}
