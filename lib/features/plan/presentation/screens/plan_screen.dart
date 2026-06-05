import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../outfit/presentation/view_model/outfit_list_view_model.dart';
import '../../../wardrobe/presentation/view_model/wardrobe_view_model.dart';
import '../../domain/entities/plan_entity.dart';
import '../view_model/plan_view_model.dart';
import '../widgets/assign_plan_sheet.dart';
import '../widgets/outfit_lookup.dart';
import '../widgets/plan_tile.dart';
import 'plan_list_screen.dart';

/// The Plan tab — a month calendar of scheduled outfits, the selected day's
/// plans, and quick access to the full list view.
class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

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

  void _stepMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
    });
  }

  Future<void> _assign() async {
    final created = await showAssignPlanSheet(context, initialDate: _selectedDay);
    if (created == true) _refresh();
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

    final daysWithPlans = <DateTime>{for (final p in state.plans) p.day};
    final dayPlans = state.plansOn(_selectedDay);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: palette.accent,
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.space6),
            children: [
              _Header(
                onList: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PlanListScreen()),
                ),
                onAdd: _assign,
              ),
              _MonthBar(
                month: _focusedMonth,
                onPrev: () => _stepMonth(-1),
                onNext: () => _stepMonth(1),
              ),
              const SizedBox(height: AppSpacing.space2),
              _MonthCalendar(
                month: _focusedMonth,
                selectedDay: _selectedDay,
                daysWithPlans: daysWithPlans,
                onSelect: (d) => setState(() => _selectedDay = d),
              ),
              const SizedBox(height: AppSpacing.space5),
              _DaySection(
                day: _selectedDay,
                plans: dayPlans,
                lookup: lookup,
                onAdd: _assign,
                onReminderChanged: (plan) => ref
                    .read(planViewModelProvider.notifier)
                    .toggleReminder(plan, lookup.name(plan.outfitId)),
                onMove: (plan) => _move(plan, lookup),
                onMarkWorn: (plan) => ref.read(planViewModelProvider.notifier).markWorn(plan),
                onDelete: _delete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onList;
  final VoidCallback onAdd;
  const _Header({required this.onList, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.space5, AppSpacing.space4, AppSpacing.space4, AppSpacing.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PLAN AHEAD',
                    style: AppTypography.labelSmall
                        .copyWith(color: palette.textTertiary, letterSpacing: 1.6)),
                const SizedBox(height: AppSpacing.space1),
                Text('Your week',
                    style: AppTypography.headingXlarge.copyWith(color: palette.textPrimary)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.view_agenda_outlined, color: palette.textPrimary),
            tooltip: 'List view',
            onPressed: onList,
          ),
          IconButton(
            icon: Icon(Icons.add, color: palette.textPrimary),
            tooltip: 'Plan an outfit',
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _MonthBar extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  const _MonthBar({required this.month, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space5),
      child: Row(
        children: [
          Text(DateFormat('MMMM yyyy').format(month),
              style: AppTypography.headingMedium.copyWith(color: palette.textPrimary)),
          const Spacer(),
          _RoundIcon(icon: Icons.chevron_left, onTap: onPrev),
          const SizedBox(width: AppSpacing.space2),
          _RoundIcon(icon: Icons.chevron_right, onTap: onNext),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: palette.surface,
          shape: BoxShape.circle,
          border: Border.all(color: palette.border),
        ),
        child: Icon(icon, size: AppSpacing.iconSm, color: palette.textPrimary),
      ),
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  final DateTime month;
  final DateTime selectedDay;
  final Set<DateTime> daysWithPlans;
  final ValueChanged<DateTime> onSelect;

  const _MonthCalendar({
    required this.month,
    required this.selectedDay,
    required this.daysWithPlans,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Monday-first grid: weekday is 1 (Mon) … 7 (Sun).
    final leadingBlanks = firstOfMonth.weekday - 1;
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);

    final cells = <Widget>[];
    for (var i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var d = 1; d <= daysInMonth; d++) {
      final day = DateTime(month.year, month.month, d);
      final isSelected = day == DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
      final isToday = day == todayDay;
      final hasPlan = daysWithPlans.contains(day);
      cells.add(_DayCell(
        day: d,
        isSelected: isSelected,
        isToday: isToday,
        hasPlan: hasPlan,
        onTap: () => onSelect(day),
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space5),
      child: Column(
        children: [
          Row(
            children: [
              for (final label in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                Expanded(
                  child: Center(
                    child: Text(label,
                        style: AppTypography.captionSmall.copyWith(color: palette.textTertiary)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1,
            children: cells,
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isSelected;
  final bool isToday;
  final bool hasPlan;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.hasPlan,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final Color textColor;
    if (isSelected) {
      textColor = palette.background;
    } else if (isToday) {
      textColor = palette.accentStrong;
    } else {
      textColor = palette.textPrimary;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isSelected ? palette.textPrimary : Colors.transparent,
            shape: BoxShape.circle,
            border: isToday && !isSelected
                ? Border.all(color: palette.accentStrong, width: 1)
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text('$day',
                  style: AppTypography.bodyMedium.copyWith(
                    color: textColor,
                    fontWeight: isToday || isSelected ? FontWeight.w600 : FontWeight.w400,
                  )),
              if (hasPlan)
                Positioned(
                  bottom: 5,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isSelected ? palette.background : palette.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  final DateTime day;
  final List<PlanEntity> plans;
  final OutfitLookup lookup;
  final VoidCallback onAdd;
  final ValueChanged<PlanEntity> onReminderChanged;
  final ValueChanged<PlanEntity> onMove;
  final ValueChanged<PlanEntity> onMarkWorn;
  final ValueChanged<PlanEntity> onDelete;

  const _DaySection({
    required this.day,
    required this.plans,
    required this.lookup,
    required this.onAdd,
    required this.onReminderChanged,
    required this.onMove,
    required this.onMarkWorn,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isToday = day == DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final label = isToday ? 'Today' : DateFormat('EEEE, MMM d').format(day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTypography.headingMedium.copyWith(color: palette.textPrimary)),
              GestureDetector(
                onTap: onAdd,
                child: Text('Add',
                    style: AppTypography.labelSmall.copyWith(color: palette.accentStrong)),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
        if (plans.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space5),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.space5),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: AppRadius.lg,
                border: Border.all(color: palette.border),
              ),
              child: Column(
                children: [
                  Icon(Icons.checkroom_outlined, color: palette.textTertiary, size: AppSpacing.iconLg),
                  const SizedBox(height: AppSpacing.space2),
                  Text('Nothing planned',
                      style: AppTypography.labelLarge.copyWith(color: palette.textPrimary)),
                  const SizedBox(height: 2),
                  Text('Tap “Add” to plan an outfit for this day.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(color: palette.textSecondary)),
                ],
              ),
            ),
          )
        else
          ...plans.map(
            (plan) => Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.space5, 0, AppSpacing.space5, AppSpacing.space3),
              child: PlanTile(
                plan: plan,
                lookup: lookup,
                showDate: false,
                onReminderChanged: (_) => onReminderChanged(plan),
                onMove: () => onMove(plan),
                onMarkWorn: () => onMarkWorn(plan),
                onDelete: () => onDelete(plan),
              ),
            ),
          ),
      ],
    );
  }
}
