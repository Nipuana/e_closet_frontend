import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/notification_service.dart';
import '../../domain/entities/plan_entity.dart';
import '../../domain/usecases/plan_usecases.dart';

enum PlanStatus { initial, loading, ready, error }

class PlanState extends Equatable {
  final PlanStatus status;
  final List<PlanEntity> plans;
  final String? error;

  const PlanState({
    this.status = PlanStatus.initial,
    this.plans = const [],
    this.error,
  });

  PlanState copyWith({PlanStatus? status, List<PlanEntity>? plans, String? error}) {
    return PlanState(
      status: status ?? this.status,
      plans: plans ?? this.plans,
      error: error,
    );
  }

  /// Plans falling on a specific calendar day.
  List<PlanEntity> plansOn(DateTime day) {
    return plans
        .where((p) => p.day == DateTime(day.year, day.month, day.day))
        .toList();
  }

  @override
  List<Object?> get props => [status, plans, error];
}

final planViewModelProvider =
    NotifierProvider<PlanViewModel, PlanState>(PlanViewModel.new);

class PlanViewModel extends Notifier<PlanState> {
  @override
  PlanState build() => const PlanState();

  NotificationService get _notifications => ref.read(notificationServiceProvider);

  Future<void> load() async {
    state = state.copyWith(status: PlanStatus.loading);
    final result = await ref.read(listPlansUsecaseProvider)();
    result.fold(
      (failure) => state = state.copyWith(status: PlanStatus.error, error: failure.message),
      (plans) {
        final sorted = [...plans]..sort((a, b) => a.date.compareTo(b.date));
        state = state.copyWith(status: PlanStatus.ready, plans: sorted);
      },
    );
  }

  /// Default reminder time for a day: 8:00 AM.
  DateTime _defaultReminderAt(DateTime date) =>
      DateTime(date.year, date.month, date.day, 8);

  Future<bool> createPlan({
    required String outfitId,
    required DateTime date,
    required String outfitName,
    bool reminderEnabled = true,
    DateTime? reminderAt,
  }) async {
    final result = await ref.read(createPlanUsecaseProvider)(
      outfitId: outfitId,
      date: date,
      reminderEnabled: reminderEnabled,
      reminderAt: reminderAt ?? (reminderEnabled ? _defaultReminderAt(date) : null),
    );
    return result.fold(
      (failure) {
        state = state.copyWith(status: PlanStatus.error, error: failure.message);
        return false;
      },
      (plan) async {
        await _syncReminder(plan, outfitName);
        await load();
        return true;
      },
    );
  }

  /// Flip a plan's reminder on/off and (un)schedule its notification.
  Future<void> toggleReminder(PlanEntity plan, String outfitName) async {
    final enabled = !plan.reminderEnabled;
    // Optimistic UI.
    _replace(plan.copyWith(reminderEnabled: enabled));

    final reminderAt = plan.reminderAt ?? _defaultReminderAt(plan.date);
    final result = await ref.read(updatePlanUsecaseProvider)(
      planId: plan.id!,
      reminderEnabled: enabled,
      reminderAt: enabled ? reminderAt : null,
    );
    result.fold(
      (failure) {
        _replace(plan); // revert
        state = state.copyWith(error: failure.message);
      },
      (updated) => _syncReminder(updated, outfitName),
    );
  }

  /// Move a plan to a different day (also shifts its reminder to that day).
  Future<bool> movePlan(PlanEntity plan, DateTime newDate, String outfitName) async {
    final reminderAt = plan.reminderEnabled ? _defaultReminderAt(newDate) : null;
    final result = await ref.read(updatePlanUsecaseProvider)(
      planId: plan.id!,
      date: newDate,
      reminderAt: reminderAt,
    );
    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (updated) async {
        await _syncReminder(updated, outfitName);
        await load();
        return true;
      },
    );
  }

  Future<void> markWorn(PlanEntity plan) async {
    _replace(plan.copyWith(worn: true));
    await _notifications.cancelPlanReminder(plan.id!);
    final result = await ref.read(updatePlanUsecaseProvider)(planId: plan.id!, worn: true);
    result.fold((failure) => state = state.copyWith(error: failure.message), (_) {});
  }

  Future<bool> delete(PlanEntity plan) async {
    final result = await ref.read(deletePlanUsecaseProvider)(plan.id!);
    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (_) async {
        await _notifications.cancelPlanReminder(plan.id!);
        state = state.copyWith(plans: state.plans.where((p) => p.id != plan.id).toList());
        return true;
      },
    );
  }

  void _replace(PlanEntity plan) {
    state = state.copyWith(
      plans: state.plans.map((p) => p.id == plan.id ? plan : p).toList(),
    );
  }

  Future<void> _syncReminder(PlanEntity plan, String outfitName) async {
    if (plan.id == null) return;
    if (plan.reminderEnabled && plan.reminderAt != null) {
      await _notifications.schedulePlanReminder(
        planId: plan.id!,
        title: outfitName,
        body: "Today's planned outfit is ready to wear.",
        when: plan.reminderAt!,
      );
    } else {
      await _notifications.cancelPlanReminder(plan.id!);
    }
  }
}
