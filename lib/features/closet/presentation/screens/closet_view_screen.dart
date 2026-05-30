import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../outfit/presentation/widgets/outfit_visuals.dart';
import '../../../wardrobe/domain/entities/wardrobe_item_entity.dart';
import '../../../wardrobe/presentation/view_model/wardrobe_view_model.dart';
import '../../domain/entities/wardrobe_layout_entity.dart';
import '../../domain/usecases/closet_usecases.dart';
import '../closet_modules.dart';
import 'wardrobe_designer_screen.dart';

/// An interactive view of a built closet: tap to swing the doors open, then tap
/// any compartment to place wardrobe pieces into it (hung, folded, or stored in
/// drawers). Placements persist on the layout.
class ClosetViewScreen extends ConsumerStatefulWidget {
  final WardrobeLayoutEntity layout;
  /// When opened from a piece in the clothes list, auto-open the doors and pop
  /// the compartment that stores that piece.
  final int? focusRow;
  final int? focusCol;

  const ClosetViewScreen({
    super.key,
    required this.layout,
    this.focusRow,
    this.focusCol,
  });

  @override
  ConsumerState<ClosetViewScreen> createState() => _ClosetViewScreenState();
}

class _ClosetViewScreenState extends ConsumerState<ClosetViewScreen>
    with SingleTickerProviderStateMixin {
  late WardrobeLayoutEntity _layout;
  late final AnimationController _doors;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _layout = widget.layout;
    _doors = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(wardrobeViewModelProvider.notifier).loadAllItems();
      _maybeFocusCompartment();
    });
  }

  /// Deep-link: open the doors and pop the compartment for [focusRow]/[focusCol].
  Future<void> _maybeFocusCompartment() async {
    final r = widget.focusRow, c = widget.focusCol;
    if (r == null || c == null || !mounted) return;
    final info = _layout.cellAt(r, c);
    final module = info.isAnchor ? moduleById(info.moduleId) : null;
    if (module == null) return;
    setState(() => _open = true);
    await _doors.forward();
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (mounted) _editCompartment(r, c, module);
  }

  @override
  void dispose() {
    _doors.dispose();
    super.dispose();
  }

  void _toggleDoors() {
    HapticFeedback.lightImpact();
    setState(() => _open = !_open);
    _open ? _doors.forward() : _doors.reverse();
  }

  Future<void> _persist(WardrobeLayoutEntity next) async {
    setState(() => _layout = next);
    final result = await ref.read(saveWardrobeLayoutUsecaseProvider)(next);
    if (!mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not save: ${failure.message}'))),
      (saved) {
        if (_layout.id == null && saved.id != null) {
          setState(() => _layout = _layout.copyWith(id: saved.id));
        }
      },
    );
  }

  /// Pop the tapped compartment to the front in a detailed, type-specific view.
  Future<void> _editCompartment(int r, int c, ClosetModuleDef module) async {
    HapticFeedback.selectionClick();
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: module.label,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 340),
      pageBuilder: (ctx, _, _) => _CompartmentDetail(
        r: r,
        c: c,
        module: module,
        initialLayout: _layout,
        allItems: ref.read(wardrobeViewModelProvider).allItems,
        onPersist: _persist,
      ),
      transitionBuilder: (ctx, anim, _, child) {
        final pop = Curves.easeOutBack.transform(anim.value);
        return Opacity(
          opacity: anim.value.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.5 + 0.5 * pop, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final byId = {
      for (final i in ref.watch(wardrobeViewModelProvider).allItems) i.itemId: i,
    };
    final finish = kFinishColors[_layout.finish] ?? AppColors.camel;

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
        title: Text(_layout.name,
            style: AppTypography.headingMedium.copyWith(color: palette.textPrimary)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.tune, size: AppSpacing.iconSm, color: palette.textPrimary),
            tooltip: 'Edit layout',
            onPressed: () async {
              final saved = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => WardrobeDesignerScreen(initial: _layout)),
              );
              if (saved == true && mounted) {
                ref.read(wardrobeViewModelProvider.notifier).loadAllItems();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.space2),
            Text(
              '${_layout.placedCount} pieces stored · ${_layout.moduleCount} compartments',
              style: AppTypography.bodyMedium.copyWith(color: palette.textSecondary),
            ),
            const SizedBox(height: AppSpacing.space4),
            Expanded(
              child: Center(
                child: Padding(
                  padding: AppSpacing.paddingLg,
                  child: AspectRatio(
                    aspectRatio: _layout.cols / (_layout.rows == 0 ? 1 : _layout.rows) * 0.92,
                    child: _Wardrobe(
                      layout: _layout,
                      byId: byId,
                      finish: finish,
                      doors: _doors,
                      open: _open,
                      onToggleDoors: _toggleDoors,
                      onTapCompartment: _editCompartment,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space5, top: AppSpacing.space2),
              child: TextButton.icon(
                onPressed: _toggleDoors,
                icon: Icon(_open ? Icons.door_front_door_outlined : Icons.door_sliding_outlined,
                    size: AppSpacing.iconSm, color: palette.accentStrong),
                label: Text(_open ? 'Close doors' : 'Open closet',
                    style: AppTypography.labelMedium.copyWith(color: palette.accentStrong)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The wardrobe body: an interior compartment grid behind two swinging doors.
class _Wardrobe extends StatelessWidget {
  final WardrobeLayoutEntity layout;
  final Map<String, WardrobeItemEntity> byId;
  final Color finish;
  final AnimationController doors;
  final bool open;
  final VoidCallback onToggleDoors;
  final void Function(int r, int c, ClosetModuleDef module) onTapCompartment;

  const _Wardrobe({
    required this.layout,
    required this.byId,
    required this.finish,
    required this.doors,
    required this.open,
    required this.onToggleDoors,
    required this.onTapCompartment,
  });

  @override
  Widget build(BuildContext context) {
    final frame = _shade(finish, 0.7);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: frame,
        borderRadius: AppRadius.md,
        boxShadow: AppShadows.shadowLg,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Interior (back panel + compartments).
            Container(
              color: _shade(finish, 0.5),
              child: _Interior(layout: layout, byId: byId, onTap: open ? onTapCompartment : null),
            ),
            // Doors.
            AnimatedBuilder(
              animation: doors,
              builder: (context, _) {
                final t = Curves.easeInOut.transform(doors.value);
                return IgnorePointer(
                  ignoring: open,
                  child: Opacity(
                    opacity: 1 - (t * 0.15),
                    child: Row(
                      children: [
                        Expanded(child: _Door(finish: finish, t: t, left: true)),
                        Expanded(child: _Door(finish: finish, t: t, left: false)),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Tap-to-open hit layer (only while closed).
            if (!open)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onToggleDoors,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Door extends StatelessWidget {
  final Color finish;
  final double t; // 0 closed, 1 open
  final bool left;
  const _Door({required this.finish, required this.t, required this.left});

  @override
  Widget build(BuildContext context) {
    final angle = t * (math.pi * 0.62); // swing ~110°
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0015)
      ..rotateY(left ? -angle : angle);
    final grain = _shade(finish, 0.92);
    return Transform(
      alignment: left ? Alignment.centerLeft : Alignment.centerRight,
      transform: matrix,
      child: Container(
        margin: EdgeInsets.only(left: left ? 0 : 1.5, right: left ? 1.5 : 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: left ? Alignment.centerLeft : Alignment.centerRight,
            end: left ? Alignment.centerRight : Alignment.centerLeft,
            colors: [_shade(finish, 0.78), grain],
          ),
          border: Border.all(color: _shade(finish, 0.6), width: 1.5),
        ),
        child: Align(
          alignment: left ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              width: 6,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFCBB68C),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The interior compartment grid (positions match the saved layout).
class _Interior extends StatelessWidget {
  final WardrobeLayoutEntity layout;
  final Map<String, WardrobeItemEntity> byId;
  final void Function(int r, int c, ClosetModuleDef module)? onTap;

  const _Interior({required this.layout, required this.byId, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cols = layout.cols, rows = layout.rows;
    if (cols == 0 || rows == 0) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 4.0;
        final cellW = (constraints.maxWidth - gap * (cols - 1)) / cols;
        final cellH = (constraints.maxHeight - gap * (rows - 1)) / rows;
        final tiles = <Widget>[];
        for (int r = 0; r < rows; r++) {
          for (int c = 0; c < cols; c++) {
            final info = layout.cellAt(r, c);
            if (info.covered || !info.isAnchor) continue;
            final module = moduleById(info.moduleId);
            if (module == null) continue;
            final left = c * (cellW + gap);
            final top = r * (cellH + gap);
            final w = cellW * info.colSpan + gap * (info.colSpan - 1);
            final h = cellH * info.rowSpan + gap * (info.rowSpan - 1);
            final items = layout
                .itemsAt(r, c)
                .map((id) => byId[id])
                .whereType<WardrobeItemEntity>()
                .toList();
            tiles.add(Positioned(
              left: left,
              top: top,
              width: w,
              height: h,
              child: _Compartment(
                module: module,
                items: items,
                onTap: onTap == null ? null : () => onTap!(r, c, module),
              ),
            ));
          }
        }
        return Stack(children: tiles);
      },
    );
  }
}

class _Compartment extends StatelessWidget {
  final ClosetModuleDef module;
  final List<WardrobeItemEntity> items;
  final VoidCallback? onTap;

  const _Compartment({required this.module, required this.items, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0x22000000),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0x33000000)),
        ),
        clipBehavior: Clip.antiAlias,
        child: _content(),
      ),
    );
  }

  Widget _content() {
    if (items.isEmpty) {
      return Center(
        child: Icon(module.icon, color: Colors.white.withValues(alpha: 0.45), size: 22),
      );
    }
    switch (module.id) {
      case 'hang':
        return _HangContent(items: items);
      case 'drawers':
        return _DrawerContent(items: items);
      default:
        return _FoldedContent(items: items);
    }
  }
}

class _HangContent extends StatelessWidget {
  final List<WardrobeItemEntity> items;
  const _HangContent({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(height: 3, color: const Color(0x55FFFFFF)), // rail
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(3, 2, 3, 3),
            child: Row(
              children: [
                for (final item in items.take(4))
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: OutfitItemCell(item: item),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FoldedContent extends StatelessWidget {
  final List<WardrobeItemEntity> items;
  const _FoldedContent({required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Column(
        children: [
          for (final item in items.take(3))
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: OutfitItemCell(item: item),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DrawerContent extends StatelessWidget {
  final List<WardrobeItemEntity> items;
  const _DrawerContent({required this.items});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0x33FFFFFF)),
        Center(
          child: Container(width: 26, height: 4, color: const Color(0x66000000)),
        ),
        Positioned(
          right: 3,
          top: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${items.length}',
                style: const TextStyle(color: Colors.white, fontSize: 10)),
          ),
        ),
      ],
    );
  }
}

// ── Popped-out compartment detail (front-and-centre, per module type) ───────
class _CompartmentDetail extends StatefulWidget {
  final int r;
  final int c;
  final ClosetModuleDef module;
  final WardrobeLayoutEntity initialLayout;
  final List<WardrobeItemEntity> allItems;
  final Future<void> Function(WardrobeLayoutEntity) onPersist;

  const _CompartmentDetail({
    required this.r,
    required this.c,
    required this.module,
    required this.initialLayout,
    required this.allItems,
    required this.onPersist,
  });

  @override
  State<_CompartmentDetail> createState() => _CompartmentDetailState();
}

class _CompartmentDetailState extends State<_CompartmentDetail> {
  late WardrobeLayoutEntity _layout = widget.initialLayout;

  Map<String, WardrobeItemEntity> get _byId =>
      {for (final i in widget.allItems) i.itemId: i};

  List<WardrobeItemEntity> get _items => _layout
      .itemsAt(widget.r, widget.c)
      .map((id) => _byId[id])
      .whereType<WardrobeItemEntity>()
      .toList();

  Future<void> _edit() async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlaceSheet(
        module: widget.module,
        allItems: widget.allItems,
        placedHere: _layout.itemsAt(widget.r, widget.c).toSet(),
        placedElsewhere: {
          for (final entry in _layout.placements.entries)
            if (entry.key != WardrobeLayoutEntity.placementKey(widget.r, widget.c))
              ...entry.value,
        },
      ),
    );
    if (result == null) return;
    final before = _layout.itemsAt(widget.r, widget.c).toSet();
    var next = _layout;
    for (final id in result.where((id) => !before.contains(id))) {
      next = next.withItemAt(widget.r, widget.c, id);
    }
    for (final id in before.where((id) => !result.contains(id))) {
      next = next.withoutItemAt(widget.r, widget.c, id);
    }
    setState(() => _layout = next);
    await widget.onPersist(next);
  }

  /// Remove a single piece from this compartment, after confirming. The piece
  /// stays in the wardrobe — only its placement in this location is cleared.
  Future<void> _confirmRemove(WardrobeItemEntity item) async {
    final palette = context.palette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: palette.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lg),
        title: Text('Remove piece?',
            style: AppTypography.headingSmall.copyWith(color: palette.textPrimary)),
        content: Text(
          'Remove “${item.displayName}” from this ${widget.module.label.toLowerCase()}? '
          'It stays in your wardrobe.',
          style: AppTypography.bodyMedium.copyWith(color: palette.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: Text('Cancel',
                style: AppTypography.labelMedium.copyWith(color: palette.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dCtx, true),
            child: Text('Remove',
                style: AppTypography.labelMedium.copyWith(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final next = _layout.withoutItemAt(widget.r, widget.c, item.itemId);
    setState(() => _layout = next);
    await widget.onPersist(next);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final finish = kFinishColors[_layout.finish] ?? AppColors.camel;
    final size = MediaQuery.of(context).size;
    final items = _items;

    return Center(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 460,
            maxHeight: size.height * 0.66,
          ),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: _shade(finish, 0.7),
                borderRadius: AppRadius.lg,
                boxShadow: AppShadows.shadowLg,
                border: Border.all(color: _shade(finish, 0.55), width: 2),
              ),
              padding: const EdgeInsets.all(AppSpacing.space3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(widget.module.icon, size: AppSpacing.iconSm, color: Colors.white),
                      const SizedBox(width: AppSpacing.space2),
                      Expanded(
                        child: Text(
                          '${widget.module.label} · ${items.length} ${items.length == 1 ? 'piece' : 'pieces'}',
                          style: AppTypography.labelLarge.copyWith(color: Colors.white),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.space2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1.5),
                          ),
                          child: const Icon(Icons.close, size: AppSpacing.iconSm, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  Flexible(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _shade(finish, 0.46),
                        borderRadius: AppRadius.md,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: items.isEmpty
                          ? _EmptyInterior(module: widget.module)
                          : _interior(items),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _edit,
                      icon: const Icon(Icons.edit_outlined, size: AppSpacing.iconSm),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.background,
                        foregroundColor: palette.textPrimary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
                        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pill),
                      ),
                      label: Text('Edit pieces',
                          style: AppTypography.labelMedium.copyWith(color: palette.textPrimary)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _interior(List<WardrobeItemEntity> items) {
    switch (widget.module.id) {
      case 'hang':
        return _HangDetail(items: items, onRemove: _confirmRemove);
      case 'drawers':
        return _DrawerDetail(items: items, onRemove: _confirmRemove);
      default:
        return _FoldedDetail(items: items, onRemove: _confirmRemove);
    }
  }
}

class _EmptyInterior extends StatelessWidget {
  final ClosetModuleDef module;
  const _EmptyInterior({required this.module});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(module.icon, color: Colors.white.withValues(alpha: 0.5), size: AppSpacing.iconXl),
          const SizedBox(height: AppSpacing.space3),
          Text('Empty — tap “Edit pieces” to fill it.',
              style: AppTypography.bodySmall.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }
}

const Color _metal = Color(0xFFCBCBCB);

/// Hanging rail with garments on hangers.
class _HangDetail extends StatelessWidget {
  final List<WardrobeItemEntity> items;
  final void Function(WardrobeItemEntity) onRemove;
  const _HangDetail({required this.items, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.space3, AppSpacing.space4, AppSpacing.space3, AppSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Rod.
          Container(
            height: 6,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF9A9A9A), _metal, Color(0xFF9A9A9A)]),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(top: AppSpacing.space1),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.space3),
              itemBuilder: (context, i) {
                return Column(
                  children: [
                    Container(width: 2.5, height: 18, color: _metal), // hanger neck
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 0.62,
                        child: ClipRRect(
                          borderRadius: AppRadius.sm,
                          child: _RemovableCell(
                            item: items[i],
                            onRemove: () => onRemove(items[i]),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Folded stacks on shelves.
class _FoldedDetail extends StatelessWidget {
  final List<WardrobeItemEntity> items;
  final void Function(WardrobeItemEntity) onRemove;
  const _FoldedDetail({required this.items, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.space3),
      itemCount: items.length,
      itemBuilder: (context, i) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.space2),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.18), width: 2)),
          ),
          child: AspectRatio(
            aspectRatio: 4.4, // wide, short → a folded stack
            child: ClipRRect(
              borderRadius: AppRadius.sm,
              child: _RemovableCell(item: items[i], onRemove: () => onRemove(items[i])),
            ),
          ),
        );
      },
    );
  }
}

/// An open drawer with accessories laid inside.
class _DrawerDetail extends StatelessWidget {
  final List<WardrobeItemEntity> items;
  final void Function(WardrobeItemEntity) onRemove;
  const _DrawerDetail({required this.items, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.space3),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0x33000000),
          borderRadius: AppRadius.sm,
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: const [
            BoxShadow(color: Color(0x55000000), blurRadius: 8, offset: Offset(0, 4)),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.space2),
        child: GridView.builder(
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: AppSpacing.space2,
            crossAxisSpacing: AppSpacing.space2,
            childAspectRatio: 1,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) => ClipRRect(
            borderRadius: AppRadius.sm,
            child: _RemovableCell(item: items[i], onRemove: () => onRemove(items[i])),
          ),
        ),
      ),
    );
  }
}

/// A piece cell with a tappable ✕ badge to remove it from the compartment.
class _RemovableCell extends StatelessWidget {
  final WardrobeItemEntity item;
  final VoidCallback onRemove;

  const _RemovableCell({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        OutfitItemCell(item: item),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1.5),
              ),
              child: const Icon(Icons.close, size: 20, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet to place / remove pieces in a compartment.
class _PlaceSheet extends StatefulWidget {
  final ClosetModuleDef module;
  final List<WardrobeItemEntity> allItems;
  final Set<String> placedHere;
  final Set<String> placedElsewhere;

  const _PlaceSheet({
    required this.module,
    required this.allItems,
    required this.placedHere,
    required this.placedElsewhere,
  });

  @override
  State<_PlaceSheet> createState() => _PlaceSheetState();
}

class _PlaceSheetState extends State<_PlaceSheet> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.placedHere};
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
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
                decoration: BoxDecoration(color: palette.border, borderRadius: AppRadius.full),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.space5, AppSpacing.space3, AppSpacing.space5, AppSpacing.space2),
                child: Row(
                  children: [
                    Icon(widget.module.icon, size: AppSpacing.iconSm, color: palette.accentStrong),
                    const SizedBox(width: AppSpacing.space2),
                    Expanded(
                      child: Text('Place in ${widget.module.label.toLowerCase()}',
                          style: AppTypography.headingMedium.copyWith(color: palette.textPrimary)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, _selected),
                      child: Text('Done',
                          style: AppTypography.labelLarge.copyWith(color: palette.accentStrong)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: widget.allItems.isEmpty
                    ? Center(
                        child: Padding(
                          padding: AppSpacing.paddingLg,
                          child: Text('No pieces in your wardrobe yet.',
                              style: AppTypography.bodyMedium.copyWith(color: palette.textTertiary)),
                        ),
                      )
                    : GridView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.space5, 0, AppSpacing.space5, AppSpacing.space8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: AppSpacing.space3,
                          crossAxisSpacing: AppSpacing.space3,
                          childAspectRatio: 0.76,
                        ),
                        itemCount: widget.allItems.length,
                        itemBuilder: (context, i) {
                          final item = widget.allItems[i];
                          final selected = _selected.contains(item.itemId);
                          final elsewhere =
                              !selected && widget.placedElsewhere.contains(item.itemId);
                          return _PickTile(
                            item: item,
                            selected: selected,
                            elsewhere: elsewhere,
                            onTap: () => setState(() {
                              if (selected) {
                                _selected.remove(item.itemId);
                              } else {
                                _selected.add(item.itemId);
                              }
                            }),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PickTile extends StatelessWidget {
  final WardrobeItemEntity item;
  final bool selected;
  final bool elsewhere;
  final VoidCallback onTap;

  const _PickTile({
    required this.item,
    required this.selected,
    required this.elsewhere,
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
                    child: OutfitItemCell(item: item),
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
                  if (elsewhere)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.45),
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: const Text('stored elsewhere',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 9)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(item.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.captionSmall.copyWith(color: palette.textPrimary)),
        ],
      ),
    );
  }
}

/// Darken a colour by factor f (<1).
Color _shade(Color base, double f) {
  return Color.fromARGB(
    base.a.round() == 0 ? 255 : (base.a * 255).round(),
    (base.r * 255 * f).round().clamp(0, 255),
    (base.g * 255 * f).round().clamp(0, 255),
    (base.b * 255 * f).round().clamp(0, 255),
  );
}
