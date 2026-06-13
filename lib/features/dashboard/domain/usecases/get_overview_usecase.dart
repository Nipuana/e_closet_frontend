import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../entities/dashboard_overview_entity.dart';
import '../repositories/dashboard_repository.dart';

final getOverviewUsecaseProvider = Provider<GetOverviewUsecase>((ref) {
  return GetOverviewUsecase(ref.read(dashboardRepositoryProvider));
});

class GetOverviewUsecase {
  final IDashboardRepository _repository;

  GetOverviewUsecase(this._repository);

  Future<Either<Failure, DashboardOverviewEntity>> call() =>
      _repository.getOverview();
}
