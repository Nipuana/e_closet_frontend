import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/dashboard_overview_entity.dart';

abstract interface class IDashboardRepository {
  Future<Either<Failure, DashboardOverviewEntity>> getOverview();
}
