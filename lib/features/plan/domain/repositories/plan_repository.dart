import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/plan_entity.dart';

abstract interface class IPlanRepository {
  Future<Either<Failure, List<PlanEntity>>> listPlans({DateTime? from, DateTime? to});
  Future<Either<Failure, PlanEntity>> createPlan({
    required String outfitId,
    required DateTime date,
    bool reminderEnabled,
    DateTime? reminderAt,
    String? title,
    String? note,
  });
  Future<Either<Failure, PlanEntity>> updatePlan({
    required String planId,
    DateTime? date,
    bool? reminderEnabled,
    DateTime? reminderAt,
    String? title,
    String? note,
    bool? worn,
  });
  Future<Either<Failure, Unit>> deletePlan(String planId);
}
