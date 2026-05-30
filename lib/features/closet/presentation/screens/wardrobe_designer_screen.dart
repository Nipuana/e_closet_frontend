import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/common.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/wardrobe_layout_entity.dart';
import '../closet_modules.dart';
import '../closet_tile_painter.dart';
import '../view_model/wardrobe_designer_view_model.dart';

const Map<String, Color> _finishColors = {
  'Natural': Color(0xFFBFA179),
  'Walnut': Color(0xFF6B4A33),
  'Bone': Color(0xFFE0D4BE),
  'Ink': Color(0xFF2A2A28),
  'Sage': Color(0xFF9CA98C),
};

/// Closet Planner — place cabinet modules (hanging rails, shelves, drawers…)
/// on a grid to mirror the user's real closet. Persisted via the closet backend
/// (finish + dimensions + zones).
class WardrobeDesignerScreen extends ConsumerStatefulWidget {
  /// The wardrobe to edit, or null to design a brand-new one.
  final WardrobeLayoutEntity? initial;

  const WardrobeDesignerScreen({super.key, this.initial});

  @override
  ConsumerState<WardrobeDesignerScreen> createState() => _WardrobeDesignerScreenState();
}

class _WardrobeDesignerScreenState extends ConsumerState<WardrobeDesignerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wardrobeDesignerViewModelProvider.notifier).init(widget.initial);
    });
  }

  /// Hold a block → pop up a focused resize editor over a scrim. The planner
  /// behind it is locked until the user saves or discards their changes.
  void _openResizeEditor(int r, int c) {
    HapticFeedback.mediumImpact();
    final snapshot = ref.read(wardrobeDesignerViewModelProvider).layout;
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Resize block',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (dialogCtx, anim, secondaryAnim) =>
          _ResizeEditor(anchorRow: r, anchorCol: c, original: snapshot),
      transitionBuilder: (dialogCtx, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(curved), child: child),
        );
      },
    );
  }

  Future<void> _save() async {
    final ok = await ref.read(wardrobeDesignerViewModelProvider.notifier).save();
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true); // back to the list, which reloads
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save — try again')),
      );
    }
  }

  /// Rename the closet plan via a small dialog.
  Future<void> _editName() async {
    final current = ref.read(wardrobeDesignerViewModelProvider).layout.name;
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => _RenameDialog(initialName: current),
    );
    if (!mounted) return;
    if (newName != null && newName.trim().isNotEmpty) {
      ref.read(wardrobeDesignerViewModelProvider.notifier).setName(newName);
    }
  }

  void _pickModule(int r, int c) {
    final palette = context.palette;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.topOnly),
      builder: (sheetCtx) => SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Place a module',
                  style: AppTypography.headingMedium.copyWith(color: palette.textPrimary)),
              const SizedBox(height: AppSpacing.space4),
              Wrap(
                spacing: AppSpacing.space3,
                runSpacing: AppSpacing.space3,
                children: [
                  for (final m in kClosetModules)
                    _ModuleTile(
                      label: m.label,
                      icon: m.icon,
                      onTap: () {
                        ref.read(wardrobeDesignerViewModelProvider.notifier).setCell(r, c, m.id);
                        Navigator.pop(sheetCtx);
                      },
                    ),
                  _ModuleTile(
                    label: 'Clear',
                    icon: Icons.close,
                    onTap: () {
                      ref.read(wardrobeDesignerViewModelProvider.notifier)
                          .setCell(r, c, kEmptyModule);
                      Navigator.pop(sheetCtx);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space4),
            ],
          ),
        ),
      ),
    );
  }

  /// Sheet for a placed module: replace it with another, or clear it.
  /// (Resizing across tiles is done by holding the block — see [_openResizeEditor].)
  void _editModule(int r, int c) {
    final palette = context.palette;
    final notifier = ref.read(wardrobeDesignerViewModelProvider.notifier);
    final info = ref.read(wardrobeDesignerViewModelProvider).layout.cellAt(r, c);
    if (!info.isAnchor) return;
    final module = moduleById(info.moduleId);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.topOnly),
      builder: (sheetCtx) => SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(module?.label ?? 'Module',
                  style: AppTypography.headingMedium.copyWith(color: palette.textPrimary)),
              const SizedBox(height: AppSpacing.space1),
              Text('Spanning ${info.colSpan} × ${info.rowSpan} tiles · hold the block to resize it',
                  style: AppTypography.bodySmall.copyWith(color: palette.textSecondary)),
              const SizedBox(height: AppSpacing.space4),

              Text('Change to',
                  style: AppTypography.labelSmall.copyWith(color: palette.textSecondary)),
              const SizedBox(height: AppSpacing.space3),
              Wrap(
                spacing: AppSpacing.space3,
                runSpacing: AppSpacing.space3,
                children: [
                  for (final m in kClosetModules)
                    _ModuleTile(
                      label: m.label,
                      icon: m.icon,
                      onTap: () {
                        // Keep the block's size; just swap the module.
                        notifier.changeModule(r, c, m.id);
                        Navigator.pop(sheetCtx);
                      },
                    ),
                  _ModuleTile(
                    label: 'Clear',
                    icon: Icons.close,
                    onTap: () {
                      notifier.changeModule(r, c, kEmptyModule);
                      Navigator.pop(sheetCtx);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space4),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final state = ref.watch(wardrobeDesignerViewModelProvider);
    final layout = state.layout;
    final finishColor = _finishColors[layout.finish] ?? AppColors.camel;
    final saving = state.status == DesignerStatus.saving;

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
        title: Text('Wardrobe Planner',
            style: AppTypography.headingMedium.copyWith(color: palette.textPrimary)),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: AppSpacing.paddingLg,
          children: [
            // Editable closet name
            GestureDetector(
              onTap: _editName,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space4, vertical: AppSpacing.space3),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: AppRadius.md,
                  border: Border.all(color: palette.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        layout.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.headingSmall
                            .copyWith(color: palette.textPrimary),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Icon(Icons.edit_outlined,
                        size: AppSpacing.iconSm, color: palette.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space4),

            Text(
              'Tap a cell to place a module, tap a block to change it, '
              'or hold a block to resize it across multiple tiles.',
              style: AppTypography.bodyMedium.copyWith(color: palette.textSecondary),
            ),
            const SizedBox(height: AppSpacing.space5),

            // Size controls
            Row(
              children: [
                Expanded(
                  child: _Stepper(
                    label: 'Columns',
                    value: layout.cols,
                    onMinus: () => ref.read(wardrobeDesignerViewModelProvider.notifier)
                        .setColumns(layout.cols - 1),
                    onPlus: () => ref.read(wardrobeDesignerViewModelProvider.notifier)
                        .setColumns(layout.cols + 1),
                  ),
                ),
                const SizedBox(width: AppSpacing.space4),
                Expanded(
                  child: _Stepper(
                    label: 'Rows',
                    value: layout.rows,
                    onMinus: () => ref.read(wardrobeDesignerViewModelProvider.notifier)
                        .setRows(layout.rows - 1),
                    onPlus: () => ref.read(wardrobeDesignerViewModelProvider.notifier)
                        .setRows(layout.rows + 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space5),

            // Grid canvas
            Container(
              padding: const EdgeInsets.all(AppSpacing.space3),
              decoration: BoxDecoration(
                color: palette.surfaceAlt,
                borderRadius: AppRadius.lg,
                border: Border.all(color: palette.border),
              ),
              child: _PlannerGrid(
                layout: layout,
                finishColor: finishColor,
                onTapEmpty: _pickModule,
                onTapAnchor: _editModule,
                onLongPressAnchor: _openResizeEditor,
              ),
            ),
            const SizedBox(height: AppSpacing.space6),

            // Finish
            Text('Finish', style: AppTypography.headingSmall.copyWith(color: palette.textPrimary)),
            const SizedBox(height: AppSpacing.space3),
            Wrap(
              spacing: AppSpacing.space4,
              runSpacing: AppSpacing.space3,
              children: [
                for (final entry in _finishColors.entries)
                  _FinishSwatch(
                    name: entry.key,
                    color: entry.value,
                    selected: layout.finish == entry.key,
                    onTap: () => ref.read(wardrobeDesignerViewModelProvider.notifier)
                        .setFinish(entry.key),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.space8),

            AppButton(
              text: 'Save plan',
              onPressed: saving ? null : _save,
              isLoading: saving,
              isFullWidth: true,
              size: ButtonSize.large,
            ),
          ],
        ),
      ),
    );
  }
}

/// Rename dialog that owns its own [TextEditingController] and disposes it in
/// [dispose] — after the route's exit transition — so the field is never using
/// a disposed controller mid-animation.
class _RenameDialog extends StatefulWidget {
  final String initialName;
  const _RenameDialog({required this.initialName});

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AlertDialog(
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.lg),
      title: Text('Name your closet',
          style: AppTypography.headingSmall.copyWith(color: palette.textPrimary)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 40,
        textCapitalization: TextCapitalization.words,
        style: AppTypography.bodyMedium.copyWith(color: palette.textPrimary),
        decoration: const InputDecoration(
          hintText: 'e.g. Master bedroom closet',
          counterText: '',
        ),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel',
              style: AppTypography.labelMedium.copyWith(color: palette.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text('Done',
              style: AppTypography.labelMedium.copyWith(color: palette.accent)),
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  final String moduleId;
  final Color finishColor;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final void Function(DragStartDetails)? onPanStart;
  final void Function(DragUpdateDetails)? onPanUpdate;
  final void Function(DragEndDetails)? onPanEnd;
  final bool selected;

  const _Cell({
    required this.moduleId,
    required this.finishColor,
    required this.onTap,
    this.onLongPress,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final module = moduleById(moduleId);
    final isEmpty = module == null;
    final onFinish = finishColor.computeLuminance() > 0.55 ? AppColors.ink : Colors.white;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: Stack(
        children: [
          // Animate fill/border so placing or replacing a module fades in.
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: isEmpty ? palette.surface : finishColor,
              borderRadius: AppRadius.md,
              border: Border.all(
                color: selected
                    ? palette.accent
                    : (isEmpty ? palette.border : Colors.black.withValues(alpha: 0.10)),
                width: selected ? 2.5 : 1,
              ),
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(4),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: FadeTransition(opacity: anim, child: child)),
              child: isEmpty
                  ? Icon(Icons.add,
                      key: const ValueKey('empty'),
                      size: AppSpacing.iconSm,
                      color: palette.textTertiary)
                  : CustomPaint(
                      key: ValueKey(module.id),
                      painter: ClosetModulePainter(moduleId: module.id, color: onFinish),
                      child: const SizedBox.expand(),
                    ),
            ),
          ),
          // Corner affordance hinting the block is draggable to resize.
          Positioned(
            right: 4,
            bottom: 4,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              scale: selected ? 1 : 0,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: palette.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.open_in_full, size: 11, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _Stepper({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3, vertical: AppSpacing.space2),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(color: palette.textSecondary),
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          _RoundBtn(icon: Icons.remove, onTap: onMinus),
          SizedBox(
            width: 26,
            child: Text('$value',
                textAlign: TextAlign.center,
                style: AppTypography.labelLarge.copyWith(color: palette.textPrimary)),
          ),
          _RoundBtn(icon: Icons.add, onTap: onPlus),
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _RoundBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(color: palette.surfaceAlt, shape: BoxShape.circle),
        child: Icon(icon, size: 16,
            color: enabled ? palette.textPrimary : palette.textTertiary),
      ),
    );
  }
}

/// A labelled +/- control for one span dimension; a null callback disables that
/// button (e.g. you can't shrink below 1 tile or extend past the grid edge).
class _SpanControl extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  const _SpanControl({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3, vertical: AppSpacing.space2),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(color: palette.textSecondary),
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          _RoundBtn(icon: Icons.remove, onTap: onMinus),
          SizedBox(
            width: 26,
            child: Text('$value',
                textAlign: TextAlign.center,
                style: AppTypography.labelLarge.copyWith(color: palette.textPrimary)),
          ),
          _RoundBtn(icon: Icons.add, onTap: onPlus),
        ],
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ModuleTile({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: palette.surfaceAlt,
                borderRadius: AppRadius.md,
                border: Border.all(color: palette.border),
              ),
              child: Icon(icon, color: palette.textPrimary, size: AppSpacing.iconMd),
            ),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.captionSmall.copyWith(color: palette.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _FinishSwatch extends StatelessWidget {
  final String name;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _FinishSwatch({
    required this.name,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? palette.accent : palette.border,
                width: selected ? 2.5 : 1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(name,
              style: AppTypography.captionSmall.copyWith(
                  color: selected ? palette.textPrimary : palette.textTertiary)),
        ],
      ),
    );
  }
}

/// Renders the closet grid: empty cells, placed modules (which may span
/// multiple tiles), and — for the [selected] anchor — a whole-block drag
/// surface to resize it. Reused inline in the planner and in [_ResizeEditor].
class _PlannerGrid extends StatefulWidget {
  final WardrobeLayoutEntity layout;
  final Color finishColor;
  final ({int r, int c})? selected;
  final void Function(int r, int c)? onTapEmpty;
  final void Function(int r, int c)? onTapAnchor;
  final void Function(int r, int c)? onLongPressAnchor;
  final void Function(int r, int c, int cols, int rows)? onResize;
  final void Function(int r, int c, int newR, int newC)? onMove;
  final VoidCallback? onResizeStart;
  final VoidCallback? onResizeEnd;

  const _PlannerGrid({
    required this.layout,
    required this.finishColor,
    this.selected,
    this.onTapEmpty,
    this.onTapAnchor,
    this.onLongPressAnchor,
    this.onResize,
    this.onMove,
    this.onResizeStart,
    this.onResizeEnd,
  });

  @override
  State<_PlannerGrid> createState() => _PlannerGridState();
}

class _PlannerGridState extends State<_PlannerGrid> {
  final GlobalKey _key = GlobalKey();

  /// True while the selected block is being dragged. Used to skip the position
  /// tween on that block so it tracks the finger crisply instead of lagging.
  bool _dragging = false;

  void _drag(int anchorR, int anchorC, Offset globalPos,
      double cellW, double cellH, double gap) {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(globalPos);
    // Snap the block's right/bottom edge to the cell boundary nearest the finger.
    final anchorLeft = anchorC * (cellW + gap);
    final anchorTop = anchorR * (cellH + gap);
    var cols = ((local.dx - anchorLeft + gap) / (cellW + gap)).round();
    var rows = ((local.dy - anchorTop + gap) / (cellH + gap)).round();
    if (cols < 1) cols = 1;
    if (rows < 1) rows = 1;
    final info = widget.layout.cellAt(anchorR, anchorC);
    if ((cols != info.colSpan || rows != info.rowSpan) &&
        widget.layout.canResizeTo(anchorR, anchorC, cols, rows)) {
      HapticFeedback.selectionClick(); // tick on each tile gained/released
    }
    widget.onResize?.call(anchorR, anchorC, cols, rows);
  }

  /// Drag the move grip → relocate the block so its centre follows the finger.
  void _move(int anchorR, int anchorC, Offset globalPos,
      double cellW, double cellH, double gap) {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(globalPos);
    final info = widget.layout.cellAt(anchorR, anchorC);
    final bw = cellW * info.colSpan + gap * (info.colSpan - 1);
    final bh = cellH * info.rowSpan + gap * (info.rowSpan - 1);
    // Place the block's top-left so the finger sits at its centre, then snap.
    var newC = ((local.dx - bw / 2) / (cellW + gap)).round();
    var newR = ((local.dy - bh / 2) / (cellH + gap)).round();
    newC = newC.clamp(0, widget.layout.cols - info.colSpan);
    newR = newR.clamp(0, widget.layout.rows - info.rowSpan);
    if (newR == anchorR && newC == anchorC) return;
    if (widget.layout.canMoveTo(anchorR, anchorC, newR, newC)) {
      HapticFeedback.selectionClick();
    }
    widget.onMove?.call(anchorR, anchorC, newR, newC);
  }

  @override
  Widget build(BuildContext context) {
    final layout = widget.layout;
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.space2;
        const aspect = 0.92; // cell width / height
        final cols = layout.cols;
        final rows = layout.rows;
        final cellW = (constraints.maxWidth - gap * (cols - 1)) / cols;
        final cellH = cellW / aspect;
        final totalH = cellH * rows + gap * (rows - 1);

        final tiles = <Widget>[];
        for (int r = 0; r < rows; r++) {
          for (int c = 0; c < cols; c++) {
            final info = layout.cellAt(r, c);
            if (info.covered) continue; // drawn by its anchor
            final left = c * (cellW + gap);
            final top = r * (cellH + gap);
            final w = cellW * info.colSpan + gap * (info.colSpan - 1);
            final h = cellH * info.rowSpan + gap * (info.rowSpan - 1);
            final selected = widget.selected?.r == r &&
                widget.selected?.c == c &&
                info.isAnchor;
            // The block being dragged snaps instantly to the finger; every other
            // change (steppers, placing, reflow) glides so growth is animated.
            final instant = selected && _dragging;
            tiles.add(AnimatedPositioned(
              duration: instant
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              left: left,
              top: top,
              width: w,
              height: h,
              child: _Cell(
                moduleId: info.moduleId,
                finishColor: widget.finishColor,
                selected: selected,
                // When selected the whole block is the drag surface.
                onPanStart: selected
                    ? (_) {
                        setState(() => _dragging = true);
                        widget.onResizeStart?.call();
                      }
                    : null,
                onPanUpdate: selected
                    ? (d) => _drag(r, c, d.globalPosition, cellW, cellH, gap)
                    : null,
                onPanEnd: selected
                    ? (_) {
                        setState(() => _dragging = false);
                        widget.onResizeEnd?.call();
                      }
                    : null,
                onTap: () {
                  if (info.isAnchor) {
                    widget.onTapAnchor?.call(r, c);
                  } else {
                    widget.onTapEmpty?.call(r, c);
                  }
                },
                onLongPress: info.isAnchor
                    ? () => widget.onLongPressAnchor?.call(r, c)
                    : null,
              ),
            ));
          }
        }

        // Move grip: a grab handle centred on the selected block. Dragging it
        // relocates the whole block; dragging elsewhere on the block resizes.
        final sel = widget.selected;
        if (sel != null && widget.onMove != null) {
          final info = layout.cellAt(sel.r, sel.c);
          if (info.isAnchor) {
            final bLeft = sel.c * (cellW + gap);
            final bTop = sel.r * (cellH + gap);
            final bw = cellW * info.colSpan + gap * (info.colSpan - 1);
            final bh = cellH * info.rowSpan + gap * (info.rowSpan - 1);
            tiles.add(Positioned(
              key: const ValueKey('move-grip'),
              left: bLeft + bw / 2 - 19,
              top: bTop + bh / 2 - 19,
              width: 38,
              height: 38,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (_) {
                  setState(() => _dragging = true);
                  widget.onResizeStart?.call();
                },
                onPanUpdate: (d) =>
                    _move(sel.r, sel.c, d.globalPosition, cellW, cellH, gap),
                onPanEnd: (_) {
                  setState(() => _dragging = false);
                  widget.onResizeEnd?.call();
                },
                child: Center(
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: context.palette.surface.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                      border: Border.all(color: context.palette.accent, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 5,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(Icons.open_with,
                        size: 18, color: context.palette.accent),
                  ),
                ),
              ),
            ));
          }
        }

        return SizedBox(
          key: _key,
          width: constraints.maxWidth,
          height: totalH,
          child: Stack(clipBehavior: Clip.none, children: tiles),
        );
      },
    );
  }
}

/// Focused modal shown when a block is held: the grid pops up over a scrim and
/// the planner behind it is locked. Drag the block (or use the steppers) to
/// resize it, then Save to keep the change or Discard to revert it.
class _ResizeEditor extends ConsumerStatefulWidget {
  final int anchorRow;
  final int anchorCol;
  final WardrobeLayoutEntity original;

  const _ResizeEditor({
    required this.anchorRow,
    required this.anchorCol,
    required this.original,
  });

  @override
  ConsumerState<_ResizeEditor> createState() => _ResizeEditorState();
}

class _ResizeEditorState extends ConsumerState<_ResizeEditor> {
  bool _dragging = false;

  // Anchor of the edited block; updates as it's moved around the grid.
  late int _r = widget.anchorRow;
  late int _c = widget.anchorCol;

  WardrobeDesignerViewModel get _notifier =>
      ref.read(wardrobeDesignerViewModelProvider.notifier);

  /// Bottom sheet to pick one of the modules (optionally a Clear action).
  Future<String?> _pickModuleSheet({required bool allowClear}) {
    final palette = context.palette;
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.topOnly),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Choose a tile',
                  style: AppTypography.headingMedium.copyWith(color: palette.textPrimary)),
              const SizedBox(height: AppSpacing.space4),
              Wrap(
                spacing: AppSpacing.space3,
                runSpacing: AppSpacing.space3,
                children: [
                  for (final m in kClosetModules)
                    _ModuleTile(
                      label: m.label,
                      icon: m.icon,
                      onTap: () => Navigator.pop(sheetCtx, m.id),
                    ),
                  if (allowClear)
                    _ModuleTile(
                      label: 'Clear',
                      icon: Icons.close,
                      onTap: () => Navigator.pop(sheetCtx, kEmptyModule),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.space4),
            ],
          ),
        ),
      ),
    );
  }

  /// Tap an empty cell → pick a module to place there, then edit it.
  Future<void> _addTile(int r, int c) async {
    final id = await _pickModuleSheet(allowClear: false);
    if (!mounted || id == null || id.isEmpty) return;
    _notifier.setCell(r, c, id);
    setState(() {
      _r = r;
      _c = c;
    });
  }

  /// Replace (or clear) the currently-edited tile, keeping its span.
  Future<void> _replaceTile() async {
    final id = await _pickModuleSheet(allowClear: true);
    if (!mounted || id == null) return;
    _notifier.changeModule(_r, _c, id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final notifier = ref.read(wardrobeDesignerViewModelProvider.notifier);
    final layout = ref.watch(wardrobeDesignerViewModelProvider).layout;
    final r = _r;
    final c = _c;
    final info = layout.cellAt(r, c);
    final finishColor = _finishColors[layout.finish] ?? AppColors.camel;
    final module = info.isAnchor ? moduleById(info.moduleId) : null;
    final canWider = layout.canResizeTo(r, c, info.colSpan + 1, info.rowSpan);
    final canTaller = layout.canResizeTo(r, c, info.colSpan, info.rowSpan + 1);

    return Dialog(
      backgroundColor: palette.surface,
      insetPadding: const EdgeInsets.all(AppSpacing.space5),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.lg),
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit ${module?.label ?? 'module'}',
                style: AppTypography.headingMedium.copyWith(color: palette.textPrimary)),
            const SizedBox(height: AppSpacing.space1),
            Text('Tap a tile to edit it or an empty cell to add one. Drag the ⤧ grip to move, edges or steppers to resize.',
                style: AppTypography.bodySmall.copyWith(color: palette.textSecondary)),
            const SizedBox(height: AppSpacing.space4),

            // Grid; only scrolls when a block isn't being actively dragged.
            Flexible(
              child: SingleChildScrollView(
                physics: _dragging ? const NeverScrollableScrollPhysics() : null,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  decoration: BoxDecoration(
                    color: palette.surfaceAlt,
                    borderRadius: AppRadius.lg,
                    border: Border.all(color: palette.border),
                  ),
                  child: _PlannerGrid(
                    layout: layout,
                    finishColor: finishColor,
                    selected: (r: r, c: c),
                    // Tap an empty cell to add; tap another block to switch.
                    onTapEmpty: _addTile,
                    onTapAnchor: (tr, tc) => setState(() {
                      _r = tr;
                      _c = tc;
                    }),
                    onResize: notifier.resizeTo,
                    onMove: (fromR, fromC, newR, newC) {
                      if (!layout.canMoveTo(fromR, fromC, newR, newC)) return;
                      notifier.moveBlock(fromR, fromC, newR, newC);
                      setState(() {
                        _r = newR;
                        _c = newC;
                      });
                    },
                    onResizeStart: () => setState(() => _dragging = true),
                    onResizeEnd: () => setState(() => _dragging = false),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space3),

            // Replace the currently-edited tile with a different module.
            if (info.isAnchor)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _replaceTile,
                  icon: Icon(Icons.swap_horiz,
                      size: AppSpacing.iconSm, color: palette.accent),
                  label: Text('Replace tile',
                      style: AppTypography.labelMedium.copyWith(color: palette.accent)),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.space3),

            Row(
              children: [
                Expanded(
                  child: _SpanControl(
                    label: 'Width',
                    value: info.colSpan,
                    onMinus: info.colSpan > 1 ? () => notifier.shrinkRight(r, c) : null,
                    onPlus: canWider ? () => notifier.extendRight(r, c) : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: _SpanControl(
                    label: 'Height',
                    value: info.rowSpan,
                    onMinus: info.rowSpan > 1 ? () => notifier.shrinkDown(r, c) : null,
                    onPlus: canTaller ? () => notifier.extendDown(r, c) : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space5),

            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Discard',
                    variant: ButtonVariant.secondary,
                    isFullWidth: true,
                    onPressed: () {
                      notifier.setLayout(widget.original);
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: AppButton(
                    text: 'Save',
                    isFullWidth: true,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
