import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../data/repositories/plan_repository.dart';
import '../entities/plan_entity.dart';
import '../repositories/plan_repository.dart';

final listPlansUsecaseProvider = Provider<ListPlansUsecase>(
    (ref) => ListPlansUsecase(ref.read(planRepositoryProvider)));
final createPlanUsecaseProvider = Provider<CreatePlanUsecase>(
    (ref) => CreatePlanUsecase(ref.read(planRepositoryProvider)));
final updatePlanUsecaseProvider = Provider<UpdatePlanUsecase>(
    (ref) => UpdatePlanUsecase(ref.read(planRepositoryProvider)));
final deletePlanUsecaseProvider = Provider<DeletePlanUsecase>(
    (ref) => DeletePlanUsecase(ref.read(planRepositoryProvider)));

class ListPlansUsecase {
  final IPlanRepository _repo;
  ListPlansUsecase(this._repo);
  Future<Either<Failure, List<PlanEntity>>> call({DateTime? from, DateTime? to}) =>
      _repo.listPlans(from: from, to: to);
}

class CreatePlanUsecase {
  final IPlanRepository _repo;
  CreatePlanUsecase(this._repo);
  Future<Either<Failure, PlanEntity>> call({
    required String outfitId,
    required DateTime date,
    bool reminderEnabled = true,
    DateTime? reminderAt,
    String? title,
    String? note,
  }) =>
      _repo.createPlan(
        outfitId: outfitId,
        date: date,
        reminderEnabled: reminderEnabled,
        reminderAt: reminderAt,
        title: title,
        note: note,
      );
}

class UpdatePlanUsecase {
  final IPlanRepository _repo;
  UpdatePlanUsecase(this._repo);
  Future<Either<Failure, PlanEntity>> call({
    required String planId,
    DateTime? date,
    bool? reminderEnabled,
    DateTime? reminderAt,
    String? title,
    String? note,
    bool? worn,
  }) =>
      _repo.updatePlan(
        planId: planId,
        date: date,
        reminderEnabled: reminderEnabled,
        reminderAt: reminderAt,
        title: title,
        note: note,
        worn: worn,
      );
}

class DeletePlanUsecase {
  final IPlanRepository _repo;
  DeletePlanUsecase(this._repo);
  Future<Either<Failure, Unit>> call(String planId) => _repo.deletePlan(planId);
}
