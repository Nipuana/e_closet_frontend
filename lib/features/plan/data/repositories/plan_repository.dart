import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/services/network_info.dart';
import '../../domain/entities/plan_entity.dart';
import '../../domain/repositories/plan_repository.dart';
import '../datasources/plan_remote_datasource.dart';

final planRepositoryProvider = Provider<IPlanRepository>((ref) {
  return PlanRepository(
    remoteDatasource: ref.read(planRemoteDatasourceProvider),
    networkInfo: ref.read(networkInfoProvider),
  );
});

class PlanRepository implements IPlanRepository {
  final IPlanRemoteDatasource _remoteDatasource;
  final NetworkInfo _networkInfo;

  PlanRepository({
    required IPlanRemoteDatasource remoteDatasource,
    required NetworkInfo networkInfo,
  })  : _remoteDatasource = remoteDatasource,
        _networkInfo = networkInfo;

  @override
  Future<Either<Failure, List<PlanEntity>>> listPlans({DateTime? from, DateTime? to}) async {
    if (!await _networkInfo.isConnected) {
      return Left(NoInternetFailure(message: 'No internet connection'));
    }
    try {
      final models = await _remoteDatasource.listPlans(from: from, to: to);
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PlanEntity>> createPlan({
    required String outfitId,
    required DateTime date,
    bool reminderEnabled = true,
    DateTime? reminderAt,
    String? title,
    String? note,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Left(NoInternetFailure(message: 'No internet connection'));
    }
    try {
      final model = await _remoteDatasource.createPlan(
        outfitId: outfitId,
        date: date,
        reminderEnabled: reminderEnabled,
        reminderAt: reminderAt,
        title: title,
        note: note,
      );
      return Right(model.toEntity());
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PlanEntity>> updatePlan({
    required String planId,
    DateTime? date,
    bool? reminderEnabled,
    DateTime? reminderAt,
    String? title,
    String? note,
    bool? worn,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Left(NoInternetFailure(message: 'No internet connection'));
    }
    try {
      final model = await _remoteDatasource.updatePlan(
        planId: planId,
        date: date,
        reminderEnabled: reminderEnabled,
        reminderAt: reminderAt,
        title: title,
        note: note,
        worn: worn,
      );
      return Right(model.toEntity());
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deletePlan(String planId) async {
    if (!await _networkInfo.isConnected) {
      return Left(NoInternetFailure(message: 'No internet connection'));
    }
    try {
      await _remoteDatasource.deletePlan(planId);
      return const Right(unit);
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }
}
