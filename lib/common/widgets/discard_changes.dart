import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';

/// Shows a "leave without saving?" confirmation dialog used to guard accidental
/// exits from add/edit screens. Returns `true` when the user chooses to leave
/// and lose their changes, `false` (the default) when they want to stay.
///
/// Wire it into a screen's [PopScope] and its back/close buttons so that
/// leaving with unsaved edits always prompts first — see [guardedPop].
Future<bool> confirmDiscardChanges(
  BuildContext context, {
  String title = 'Discard changes?',
  String message = 'You have unsaved changes. Leave without saving them?',
  String stayLabel = 'Keep editing',
  String leaveLabel = 'Discard',
}) async {
  final palette = context.palette;
  final leave = await showDialog<bool>(
    context: context,
    builder: (dCtx) => AlertDialog(
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.lg),
      title: Text(title,
          style: AppTypography.headingSmall.copyWith(color: palette.textPrimary)),
      content: Text(message,
          style: AppTypography.bodyMedium.copyWith(color: palette.textSecondary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dCtx, false),
          child: Text(stayLabel,
              style: AppTypography.labelMedium.copyWith(color: palette.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dCtx, true),
          child: Text(leaveLabel,
              style: AppTypography.labelMedium.copyWith(color: palette.accentStrong)),
        ),
      ],
    ),
  );
  return leave ?? false;
}

/// Pops the current route, first confirming with [confirmDiscardChanges] when
/// [hasUnsavedChanges] is true. Safe to call from a back/close button or a
/// [PopScope] callback. Pass [result] to return a value to the previous route.
///
/// Use with a `PopScope(canPop: false, onPopInvokedWithResult: ...)` so the
/// system back gesture routes through the same guard.
Future<void> guardedPop(
  BuildContext context, {
  required bool hasUnsavedChanges,
  Object? result,
  String title = 'Discard changes?',
  String message = 'You have unsaved changes. Leave without saving them?',
  String stayLabel = 'Keep editing',
  String leaveLabel = 'Discard',
}) async {
  if (hasUnsavedChanges) {
    final leave = await confirmDiscardChanges(
      context,
      title: title,
      message: message,
      stayLabel: stayLabel,
      leaveLabel: leaveLabel,
    );
    if (!leave) return;
  }
  if (context.mounted) Navigator.of(context).pop(result);
}
