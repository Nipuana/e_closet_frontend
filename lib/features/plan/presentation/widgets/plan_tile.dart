import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../outfit/presentation/widgets/outfit_visuals.dart';
import '../../domain/entities/plan_entity.dart';
import 'outfit_lookup.dart';

/// A single planned outfit row — thumbnail, name, date, a reminder toggle and
/// an overflow menu (move / mark worn / remove). Used in both the day view and
/// the full plan list.
class PlanTile extends StatelessWidget {
  final PlanEntity plan;
  final OutfitLookup lookup;
  final bool showDate;
  final ValueChanged<bool> onReminderChanged;
  final VoidCallback onMove;
  final VoidCallback onMarkWorn;
  final VoidCallback onDelete;

  const PlanTile({
    super.key,
    required this.plan,
    required this.lookup,
    required this.onReminderChanged,
    required this.onMove,
    required this.onMarkWorn,
    required this.onDelete,
    this.showDate = true,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final name = plan.title?.isNotEmpty == true ? plan.title! : lookup.name(plan.outfitId);
    final pieces = lookup.piecesOf(plan.outfitId);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.lg,
        border: Border.all(color: palette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: AppRadius.md,
            child: SizedBox(width: 56, height: 56, child: OutfitThumbnail(items: pieces)),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelLarge.copyWith(
                          color: palette.textPrimary,
                          decoration: plan.worn ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    if (plan.worn)
                      Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.space2),
                        child: Icon(Icons.check_circle, size: AppSpacing.iconSm, color: AppColors.success),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (showDate) DateFormat('EEE, MMM d').format(plan.date),
                    '${pieces.length} ${pieces.length == 1 ? 'piece' : 'pieces'}',
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(color: palette.textSecondary),
                ),
                const SizedBox(height: AppSpacing.space2),
                Row(
                  children: [
                    Icon(
                      plan.reminderEnabled
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_off_outlined,
                      size: AppSpacing.iconXs,
                      color: plan.reminderEnabled ? palette.accentStrong : palette.textTertiary,
                    ),
                    const SizedBox(width: AppSpacing.space1),
                    Expanded(
                      child: Text(
                        plan.reminderEnabled && plan.reminderAt != null
                            ? 'Reminder · ${DateFormat('h:mm a').format(plan.reminderAt!)}'
                            : 'Reminder off',
                        style: AppTypography.captionSmall.copyWith(color: palette.textTertiary),
                      ),
                    ),
                    SizedBox(
                      height: 28,
                      child: Switch.adaptive(
                        value: plan.reminderEnabled,
                        activeThumbColor: palette.accent,
                        onChanged: onReminderChanged,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _menu(context),
        ],
      ),
    );
  }

  Widget _menu(BuildContext context) {
    final palette = context.palette;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, size: AppSpacing.iconSm, color: palette.textTertiary),
      color: palette.surface,
      onSelected: (value) {
        switch (value) {
          case 'move':
            onMove();
          case 'worn':
            onMarkWorn();
          case 'delete':
            onDelete();
        }
      },
      itemBuilder: (context) => [
        _item('move', Icons.event_outlined, 'Move to another day', palette),
        if (!plan.worn) _item('worn', Icons.check_circle_outline, 'Mark as worn', palette),
        _item('delete', Icons.delete_outline, 'Remove from plan', palette, danger: true),
      ],
    );
  }

  PopupMenuItem<String> _item(
    String value,
    IconData icon,
    String label,
    AppPalette palette, {
    bool danger = false,
  }) {
    final color = danger ? AppColors.danger : palette.textPrimary;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: AppSpacing.iconSm, color: color),
          const SizedBox(width: AppSpacing.space3),
          Text(label, style: AppTypography.bodyMedium.copyWith(color: color)),
        ],
      ),
    );
  }
}
