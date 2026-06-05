import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../outfit/presentation/view_model/outfit_list_view_model.dart';
import '../../../wardrobe/presentation/view_model/wardrobe_view_model.dart';
import '../../domain/entities/plan_entity.dart';
import '../view_model/plan_view_model.dart';
import '../widgets/assign_plan_sheet.dart';
import '../widgets/outfit_lookup.dart';
import '../widgets/plan_tile.dart';

/// A flat, chronological list of every planned outfit — split into Upcoming and
/// Past — for managing plans away from the calendar grid.
class PlanListScreen extends ConsumerStatefulWidget {
  const PlanListScreen({super.key});

  @override
  ConsumerState<PlanListScreen> createState() => _PlanListScreenState();
}

class _PlanListScreenState extends ConsumerState<PlanListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(planViewModelProvider.notifier).load(),
      ref.read(outfitListViewModelProvider.notifier).load(),
      ref.read(wardrobeViewModelProvider.notifier).loadAllItems(),
    ]);
  }

  Future<void> _move(PlanEntity plan, OutfitLookup lookup) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: plan.date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    await ref.read(planViewModelProvider.notifier).movePlan(plan, picked, lookup.name(plan.outfitId));
  }

  Future<void> _delete(PlanEntity plan) async {
    HapticFeedback.mediumImpact();
    final ok = await ref.read(planViewModelProvider.notifier).delete(plan);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Removed from plan' : 'Could not remove — try again')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final state = ref.watch(planViewModelProvider);
    final lookup = OutfitLookup(
      outfits: ref.watch(outfitListViewModelProvider).outfits,
      items: ref.watch(wardrobeViewModelProvider).allItems,
    );

    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    final upcoming = state.plans.where((p) => !p.day.isBefore(todayDay)).toList();
    final past = state.plans.where((p) => p.day.isBefore(todayDay)).toList().reversed.toList();

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: AppSpacing.iconSm, color: palette.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Planned outfits',
            style: AppTypography.headingMedium.copyWith(color: palette.textPrimary)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: palette.textPrimary),
            onPressed: () async {
              final created = await showAssignPlanSheet(context);
              if (created == true) _refresh();
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: palette.accent,
          onRefresh: _refresh,
          child: _list(context, state, lookup, upcoming, past),
        ),
      ),
    );
  }

  Widget _list(
    BuildContext context,
    PlanState state,
    OutfitLookup lookup,
    List<PlanEntity> upcoming,
    List<PlanEntity> past,
  ) {
    final palette = context.palette;

    if (state.status == PlanStatus.loading || state.status == PlanStatus.initial) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
          strokeWidth: 2.5,
        ),
      );
    }

    if (state.plans.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.event_note_outlined, size: AppSpacing.iconXl, color: palette.textTertiary),
          const SizedBox(height: AppSpacing.space4),
          Center(
            child: Text('Nothing planned yet',
                style: AppTypography.headingSmall.copyWith(color: palette.textPrimary)),
          ),
          const SizedBox(height: AppSpacing.space2),
          Center(
            child: Text('Tap + to schedule an ensemble.',
                style: AppTypography.bodyMedium.copyWith(color: palette.textSecondary)),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.space5, AppSpacing.space4, AppSpacing.space5, AppSpacing.space10),
      children: [
        if (upcoming.isNotEmpty) ...[
          _heading(context, 'Upcoming'),
          for (final plan in upcoming) ...[
            _tile(plan, lookup),
            const SizedBox(height: AppSpacing.space3),
          ],
        ],
        if (past.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space3),
          _heading(context, 'Past'),
          for (final plan in past) ...[
            _tile(plan, lookup),
            const SizedBox(height: AppSpacing.space3),
          ],
        ],
      ],
    );
  }

  Widget _heading(BuildContext context, String text) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space3),
      child: Text(text.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(color: palette.textTertiary, letterSpacing: 1.4)),
    );
  }

  Widget _tile(PlanEntity plan, OutfitLookup lookup) {
    return PlanTile(
      plan: plan,
      lookup: lookup,
      onReminderChanged: (_) =>
          ref.read(planViewModelProvider.notifier).toggleReminder(plan, lookup.name(plan.outfitId)),
      onMove: () => _move(plan, lookup),
      onMarkWorn: () => ref.read(planViewModelProvider.notifier).markWorn(plan),
      onDelete: () => _delete(plan),
    );
  }
}
