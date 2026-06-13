import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../common/common.dart';
import '../../../../core/theme/theme.dart';
import '../../../outfit/domain/entities/outfit_entity.dart';
import '../../../outfit/presentation/view_model/outfit_list_view_model.dart';
import '../../../outfit/presentation/widgets/outfit_visuals.dart';
import '../../../wardrobe/domain/entities/wardrobe_item_entity.dart';
import '../../../wardrobe/presentation/view_model/wardrobe_view_model.dart';
import '../view_model/plan_view_model.dart';

/// Opens the "plan an outfit" bottom sheet. Returns true if a plan was created.
Future<bool?> showAssignPlanSheet(
  BuildContext context, {
  DateTime? initialDate,
  String? initialOutfitId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AssignPlanSheet(
      initialDate: initialDate,
      initialOutfitId: initialOutfitId,
    ),
  );
}

class AssignPlanSheet extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  final String? initialOutfitId;

  const AssignPlanSheet({super.key, this.initialDate, this.initialOutfitId});

  @override
  ConsumerState<AssignPlanSheet> createState() => _AssignPlanSheetState();
}

class _AssignPlanSheetState extends ConsumerState<AssignPlanSheet> {
  late DateTime _date;
  String? _outfitId;
  bool _reminderEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateTime.now();
    _outfitId = widget.initialOutfitId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(outfitListViewModelProvider.notifier).load();
      ref.read(wardrobeViewModelProvider.notifier).loadAllItems();
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _reminderTime);
    if (picked != null) setState(() => _reminderTime = picked);
  }

  Future<void> _save(List<OutfitEntity> outfits) async {
    if (_outfitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose an ensemble to plan')),
      );
      return;
    }
    final outfit = outfits.firstWhere(
      (o) => o.id == _outfitId,
      orElse: () => const OutfitEntity(name: 'Outfit'),
    );
    setState(() => _saving = true);

    final reminderAt = _reminderEnabled
        ? DateTime(_date.year, _date.month, _date.day, _reminderTime.hour, _reminderTime.minute)
        : null;

    final ok = await ref.read(planViewModelProvider.notifier).createPlan(
          outfitId: _outfitId!,
          date: DateTime(_date.year, _date.month, _date.day),
          outfitName: outfit.name,
          reminderEnabled: _reminderEnabled,
          reminderAt: reminderAt,
        );

    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      HapticFeedback.mediumImpact();
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not plan this outfit — try again')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final outfits = ref.watch(outfitListViewModelProvider).outfits;
    final byId = {for (final i in ref.watch(wardrobeViewModelProvider).allItems) i.itemId: i};

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: palette.background,
            borderRadius: AppRadius.topOnly,
          ),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.space3),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: AppRadius.full,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.space5, AppSpacing.space3, AppSpacing.space5, AppSpacing.space2),
                child: Row(
                  children: [
                    Text('Plan an outfit',
                        style: AppTypography.headingMedium.copyWith(color: palette.textPrimary)),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: palette.textTertiary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.space5, 0, AppSpacing.space5, AppSpacing.space5),
                  children: [
                    _DateRow(date: _date, onTap: _pickDate),
                    const SizedBox(height: AppSpacing.space3),
                    _ReminderRow(
                      enabled: _reminderEnabled,
                      time: _reminderTime,
                      onToggle: (v) => setState(() => _reminderEnabled = v),
                      onPickTime: _pickTime,
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    Text('Choose an ensemble',
                        style: AppTypography.labelLarge.copyWith(color: palette.textPrimary)),
                    const SizedBox(height: AppSpacing.space3),
                    if (outfits.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space6),
                        child: Text(
                          'No ensembles yet. Assemble one first, then plan it here.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(color: palette.textTertiary),
                        ),
                      )
                    else
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: AppSpacing.space3,
                        crossAxisSpacing: AppSpacing.space3,
                        childAspectRatio: 0.7,
                        children: [
                          for (final outfit in outfits)
                            _OutfitChoice(
                              outfit: outfit,
                              items: outfit.items
                                  .map((id) => byId[id])
                                  .whereType<WardrobeItemEntity>()
                                  .toList(),
                              selected: outfit.id == _outfitId,
                              onTap: () => setState(() => _outfitId = outfit.id),
                            ),
                        ],
                      ),
                    const SizedBox(height: AppSpacing.space5),
                    AppButton(
                      text: 'Add to plan',
                      isFullWidth: true,
                      isLoading: _saving,
                      onPressed: () => _save(outfits),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DateRow extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;
  const _DateRow({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: AppRadius.md,
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            Icon(Icons.event_outlined, size: AppSpacing.iconSm, color: palette.accentStrong),
            const SizedBox(width: AppSpacing.space3),
            Text('Date', style: AppTypography.bodyMedium.copyWith(color: palette.textSecondary)),
            const Spacer(),
            Text(DateFormat('EEE, MMM d, yyyy').format(date),
                style: AppTypography.labelMedium.copyWith(color: palette.textPrimary)),
            const SizedBox(width: AppSpacing.space2),
            Icon(Icons.chevron_right, color: palette.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final bool enabled;
  final TimeOfDay time;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickTime;

  const _ReminderRow({
    required this.enabled,
    required this.time,
    required this.onToggle,
    required this.onPickTime,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4, vertical: AppSpacing.space2),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
            size: AppSpacing.iconSm,
            color: enabled ? palette.accentStrong : palette.textTertiary,
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reminder',
                    style: AppTypography.bodyMedium.copyWith(color: palette.textPrimary)),
                if (enabled)
                  GestureDetector(
                    onTap: onPickTime,
                    child: Text('at ${time.format(context)}',
                        style: AppTypography.captionSmall.copyWith(color: palette.accentStrong)),
                  ),
              ],
            ),
          ),
          Switch.adaptive(
            value: enabled,
            activeThumbColor: palette.accent,
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }
}

class _OutfitChoice extends StatelessWidget {
  final OutfitEntity outfit;
  final List<WardrobeItemEntity> items;
  final bool selected;
  final VoidCallback onTap;

  const _OutfitChoice({
    required this.outfit,
    required this.items,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: AppRadius.md,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selected ? palette.accent : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: AppRadius.md,
                    ),
                    child: OutfitThumbnail(items: items),
                  ),
                  if (selected)
                    Positioned(
                      top: AppSpacing.space1,
                      right: AppSpacing.space1,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(color: palette.accent, shape: BoxShape.circle),
                        child: const Icon(Icons.check, size: 14, color: AppColors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(outfit.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.captionSmall.copyWith(color: palette.textPrimary)),
        ],
      ),
    );
  }
}
