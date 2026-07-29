import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../common/common.dart';
import '../../../../core/theme/theme.dart';
import '../../../wardrobe/domain/entities/wardrobe_item_entity.dart';
import '../../../wardrobe/presentation/state/wardrobe_state.dart';
import '../../../wardrobe/presentation/view_model/wardrobe_view_model.dart';
import '../../domain/entities/outfit_entity.dart';
import '../../domain/usecases/outfit_usecases.dart';
import '../view_model/outfit_list_view_model.dart';
import '../widgets/outfit_visuals.dart';

/// Assemble (or edit) an ensemble: pick wardrobe pieces, name it, and save.
/// Pass [initial] to edit an existing outfit; omit it to build a new one.
class AssembleScreen extends ConsumerStatefulWidget {
  final OutfitEntity? initial;
  const AssembleScreen({super.key, this.initial});

  @override
  ConsumerState<AssembleScreen> createState() => _AssembleScreenState();
}

class _AssembleScreenState extends ConsumerState<AssembleScreen> {
  late final TextEditingController _nameController;
  final List<String> _selectedIds = [];
  String _category = 'All';
  bool _saving = false;

  bool get _isEditing => widget.initial?.id != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    if (widget.initial != null) _selectedIds.addAll(widget.initial!.items);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wardrobeViewModelProvider.notifier).loadAllItems();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Has the user changed the ensemble (name or pieces) since it opened?
  /// Compared against [widget.initial] so an untouched screen closes silently.
  bool get _hasUnsavedChanges {
    final initialName = widget.initial?.name ?? '';
    final initialItems = (widget.initial?.items ?? const <String>[]).toSet();
    if (_nameController.text.trim() != initialName.trim()) return true;
    final current = _selectedIds.toSet();
    return current.length != initialItems.length || !current.containsAll(initialItems);
  }

  /// Leaves the screen, confirming first when there are unsaved changes.
  Future<void> _handleClose() =>
      guardedPop(context, hasUnsavedChanges: _hasUnsavedChanges);

  void _toggle(String itemId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedIds.contains(itemId)) {
        _selectedIds.remove(itemId);
      } else {
        _selectedIds.add(itemId);
      }
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _snack('Give your ensemble a name');
      return;
    }
    if (_selectedIds.isEmpty) {
      _snack('Add at least one piece');
      return;
    }
    setState(() => _saving = true);

    final result = _isEditing
        ? await ref.read(updateOutfitUsecaseProvider)(
            outfitId: widget.initial!.id!,
            name: name,
            items: _selectedIds,
          )
        : await ref.read(createOutfitUsecaseProvider)(name: name, items: _selectedIds);

    if (!mounted) return;
    setState(() => _saving = false);

    result.fold(
      (failure) => _snack(failure.message),
      (_) {
        // Refresh the Lookbook list and bubble success up to the caller.
        ref.read(outfitListViewModelProvider.notifier).load();
        Navigator.of(context).pop(true);
      },
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final wardrobe = ref.watch(wardrobeViewModelProvider);
    final allItems = wardrobe.allItems;
    final byId = {for (final i in allItems) i.itemId: i};
    final selectedItems =
        _selectedIds.map((id) => byId[id]).whereType<WardrobeItemEntity>().toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleClose();
      },
      child: Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: AppSpacing.iconSm, color: palette.textPrimary),
          onPressed: _handleClose,
        ),
        title: Text(_isEditing ? 'Edit ensemble' : 'Build an ensemble',
            style: AppTypography.headingMedium.copyWith(color: palette.textPrimary)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(palette.accentStrong),
                    ),
                  )
                : Text('Save',
                    style: AppTypography.labelLarge.copyWith(color: palette.accentStrong)),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _body(context, wardrobe, allItems, selectedItems),
      ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WardrobeState wardrobe,
    List<WardrobeItemEntity> allItems,
    List<WardrobeItemEntity> selectedItems,
  ) {
    final palette = context.palette;

    if (wardrobe.allStatus == WardrobeStatus.loading ||
        wardrobe.allStatus == WardrobeStatus.initial) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
          strokeWidth: 2.5,
        ),
      );
    }

    if (wardrobe.allStatus == WardrobeStatus.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Couldn't load your wardrobe",
                style: AppTypography.bodyMedium.copyWith(color: palette.textSecondary)),
            const SizedBox(height: AppSpacing.space2),
            TextButton(
              onPressed: () => ref.read(wardrobeViewModelProvider.notifier).loadAllItems(),
              child: Text('Retry',
                  style: AppTypography.labelSmall.copyWith(color: palette.accentStrong)),
            ),
          ],
        ),
      );
    }

    if (allItems.isEmpty) {
      return Center(
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Text(
            'Add some pieces to your wardrobe first, then come back to assemble them.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(color: palette.textTertiary),
          ),
        ),
      );
    }

    // Category chips: "All" + the distinct categories present in the wardrobe.
    final categories = <String>['All', ...{for (final i in allItems) i.category}..removeWhere((c) => c.isEmpty)];
    final visibleItems =
        _category == 'All' ? allItems : allItems.where((i) => i.category == _category).toList();

    return Column(
      children: [
        _SelectionHeader(
          nameController: _nameController,
          selectedItems: selectedItems,
          onRemove: _toggle,
        ),
        const SizedBox(height: AppSpacing.space2),
        _CategoryBar(
          categories: categories,
          selected: _category,
          onSelected: (c) => setState(() => _category = c),
        ),
        const SizedBox(height: AppSpacing.space2),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.space5, AppSpacing.space2, AppSpacing.space5, AppSpacing.space10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: AppSpacing.space3,
              crossAxisSpacing: AppSpacing.space3,
              childAspectRatio: 0.78,
            ),
            itemCount: visibleItems.length,
            itemBuilder: (context, i) {
              final item = visibleItems[i];
              final selected = _selectedIds.contains(item.itemId);
              return _PickerTile(
                item: item,
                selected: selected,
                onTap: () => _toggle(item.itemId),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Selected pieces preview, name field and running total at the top.
class _SelectionHeader extends StatelessWidget {
  final TextEditingController nameController;
  final List<WardrobeItemEntity> selectedItems;
  final void Function(String itemId) onRemove;

  const _SelectionHeader({
    required this.nameController,
    required this.selectedItems,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final total = selectedItems.fold<double>(0, (sum, i) => sum + (i.purchasePrice ?? 0));
    final priceLabel = NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(total);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.space5, AppSpacing.space3, AppSpacing.space5, AppSpacing.space4),
      decoration: BoxDecoration(color: palette.surfaceAlt),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 84,
            child: selectedItems.isEmpty
                ? Center(
                    child: Text('Tap pieces below to add them',
                        style: AppTypography.bodyMedium.copyWith(color: palette.textTertiary)),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: selectedItems.length,
                    separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.space3),
                    itemBuilder: (context, i) {
                      final item = selectedItems[i];
                      return _SelectedChip(item: item, onRemove: () => onRemove(item.itemId));
                    },
                  ),
          ),
          const SizedBox(height: AppSpacing.space3),
          TextField(
            controller: nameController,
            style: AppTypography.headingSmall.copyWith(color: palette.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Name your ensemble',
              hintStyle: AppTypography.headingSmall.copyWith(color: palette.textTertiary),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${selectedItems.length} ${selectedItems.length == 1 ? 'piece' : 'pieces'}',
                style: AppTypography.bodySmall.copyWith(color: palette.textSecondary),
              ),
              if (total > 0)
                Text(priceLabel,
                    style: AppTypography.labelMedium.copyWith(color: palette.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectedChip extends StatelessWidget {
  final WardrobeItemEntity item;
  final VoidCallback onRemove;
  const _SelectedChip({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      width: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: AppRadius.md,
            child: SizedBox(width: 64, height: 84, child: OutfitItemCell(item: item)),
          ),
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: palette.textPrimary,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.surface, width: 1.5),
                ),
                child: Icon(Icons.close, size: 12, color: palette.background),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final void Function(String) onSelected;

  const _CategoryBar({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space5),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.space2),
        itemBuilder: (context, i) {
          final c = categories[i];
          final isSel = c == selected;
          return GestureDetector(
            onTap: () => onSelected(c),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSel ? palette.textPrimary : palette.surface,
                borderRadius: AppRadius.pill,
                border: Border.all(color: isSel ? palette.textPrimary : palette.border),
              ),
              child: Text(
                c,
                style: AppTypography.labelSmall.copyWith(
                  color: isSel ? palette.background : palette.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final WardrobeItemEntity item;
  final bool selected;
  final VoidCallback onTap;

  const _PickerTile({required this.item, required this.selected, required this.onTap});

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
                      top: AppSpacing.space2,
                      right: AppSpacing.space2,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(color: palette.accent, shape: BoxShape.circle),
                        child: const Icon(Icons.check, size: 15, color: AppColors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            item.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.captionSmall.copyWith(color: palette.textPrimary),
          ),
        ],
      ),
    );
  }
}
