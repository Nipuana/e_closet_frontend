import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../common/common.dart';
import '../../../../common/widgets/color_swatches.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/theme/theme.dart';
import '../../../catalog/presentation/screens/catalog_manager_screen.dart';
import '../../../catalog/presentation/view_model/catalog_view_model.dart';
import '../../../catalog/presentation/widgets/catalog_picker.dart';
import '../../domain/entities/wardrobe_item_entity.dart';
import '../view_model/edit_piece_view_model.dart';

/// The way an [EditPieceSheet] closed, so callers can react appropriately —
/// e.g. a detail screen pops itself when the piece was deleted.
enum EditPieceOutcome { saved, deleted }

/// Opens the "edit piece" editor as a bottom sheet that slides up from the
/// bottom of the screen. The user can drag it back down (via the handle) to
/// dismiss it, so there's no need to hunt for a back button. Returns
/// [EditPieceOutcome.saved] when saved, [EditPieceOutcome.deleted] when the
/// piece was removed, or `null` when dismissed with no change.
Future<EditPieceOutcome?> showEditPieceSheet(BuildContext context, {required WardrobeItemEntity item}) {
  return showModalBottomSheet<EditPieceOutcome>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    // We drive the drag-to-dismiss ourselves (see [EditPieceSheet]) for a low,
    // "a little nudge closes it" threshold, so the native drag is off.
    enableDrag: false,
    // Slightly slower, eased in/out so the slide up and down feel smooth.
    sheetAnimationStyle: AnimationStyle(
      duration: const Duration(milliseconds: 360),
      reverseDuration: const Duration(milliseconds: 280),
    ),
    builder: (_) => EditPieceSheet(item: item),
  );
}

/// Edit an existing wardrobe piece — pre-filled from [item]. Any field can be
/// changed, including replacing the photo (camera or gallery). Category/brand
/// come from the catalog and new ones can be created inline. Pops `true` on a
/// successful save so the caller can refresh. Presented as a draggable sheet
/// via [showEditPieceSheet].
class EditPieceSheet extends ConsumerStatefulWidget {
  final WardrobeItemEntity item;
  const EditPieceSheet({super.key, required this.item});

  @override
  ConsumerState<EditPieceSheet> createState() => _EditPieceSheetState();
}

class _EditPieceSheetState extends ConsumerState<EditPieceSheet>
    with SingleTickerProviderStateMixin {
  static const _seasons = ['Spring', 'Summer', 'Autumn', 'Winter', 'All-season'];

  // A small downward drag (or a flick) dismisses the sheet; anything gentler
  // springs back. [_dragOffset] is how far the sheet is currently pulled down.
  static const double _dismissDragThreshold = 28;
  static const double _dismissFlingVelocity = 320;
  double _dragOffset = 0;
  late final AnimationController _settle =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
  Animation<double>? _settleAnim;

  String? _newImagePath; // freshly picked/captured photo
  late String? _category = widget.item.category;
  late String? _brand = widget.item.brand;
  late String? _season = widget.item.season;
  late final Set<String> _colors = {...widget.item.colors};

  late final _initialPrice =
      widget.item.purchasePrice != null ? widget.item.purchasePrice!.toStringAsFixed(0) : '';

  late final _name = TextEditingController(text: widget.item.name ?? '');
  late final _price = TextEditingController(text: _initialPrice);
  late final _material = TextEditingController(text: widget.item.material ?? '');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(catalogViewModelProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _settle.dispose();
    _name.dispose();
    _price.dispose();
    _material.dispose();
    super.dispose();
  }

  // --- Drag-to-dismiss on the sheet's grab area -----------------------------

  void _onDragStart(DragStartDetails _) => _settle.stop();

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dy).clamp(0.0, double.infinity);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dy;
    if (_dragOffset > _dismissDragThreshold || velocity > _dismissFlingVelocity) {
      // Close without confirming — dragging down is the deliberate "cancel"
      // gesture. The native exit animation carries it the rest of the way down.
      Navigator.of(context).pop();
      return;
    }
    // Not far enough: spring smoothly back into place.
    _settleAnim = Tween<double>(begin: _dragOffset, end: 0)
        .animate(CurvedAnimation(parent: _settle, curve: Curves.easeOut))
      ..addListener(() => setState(() => _dragOffset = _settleAnim!.value));
    _settle.forward(from: 0);
  }

  String? get _existingImageUrl {
    final url = widget.item.imageUrl;
    if (url.isEmpty) return null;
    if (url.startsWith('http')) return url;
    return '${ApiEndpoints.serverAddress}$url';
  }

  Future<void> _pickImage() async {
    final source = await _chooseImageSource();
    if (source == null) return;
    final file = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (file != null && mounted) setState(() => _newImagePath = file.path);
  }

  Future<ImageSource?> _chooseImageSource() {
    final palette = context.palette;
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.topOnly),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.space2),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: palette.border, borderRadius: AppRadius.pill),
            ),
            const SizedBox(height: AppSpacing.space2),
            ListTile(
              leading: Icon(Icons.camera_alt_outlined, color: palette.accent),
              title: Text('Take a photo',
                  style: AppTypography.labelLarge.copyWith(color: palette.textPrimary)),
              onTap: () => Navigator.pop(sheetCtx, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: palette.accent),
              title: Text('Choose from gallery',
                  style: AppTypography.labelLarge.copyWith(color: palette.textPrimary)),
              onTap: () => Navigator.pop(sheetCtx, ImageSource.gallery),
            ),
            const SizedBox(height: AppSpacing.space2),
          ],
        ),
      ),
    );
  }

  Future<String?> _promptNew(String title, String hint) {
    final controller = TextEditingController();
    final palette = context.palette;
    return showDialog<String>(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: palette.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lg),
        title: Text('New $title',
            style: AppTypography.headingSmall.copyWith(color: palette.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: AppTypography.bodyLarge.copyWith(color: palette.textPrimary),
          decoration: InputDecoration(hintText: hint),
          onSubmitted: (v) => Navigator.pop(dCtx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: Text('Cancel',
                style: AppTypography.labelMedium.copyWith(color: palette.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dCtx, controller.text.trim()),
            child: Text('Add',
                style: AppTypography.labelMedium.copyWith(color: palette.accentStrong)),
          ),
        ],
      ),
    );
  }

  Future<String?> _createCategory() async {
    final name = await _promptNew('category', 'e.g. Knitwear');
    if (name == null || name.isEmpty) return null;
    return ref.read(catalogViewModelProvider.notifier).addCategory(name);
  }

  Future<String?> _createBrand() async {
    final name = await _promptNew('brand', 'e.g. Atelier Noor');
    if (name == null || name.isEmpty) return null;
    return ref.read(catalogViewModelProvider.notifier).addBrand(name);
  }

  /// Has the user touched anything since the sheet opened? Compared field-by
  /// field against the original [item] so an untouched sheet closes silently.
  bool get _hasUnsavedChanges {
    final originalColors = widget.item.colors.toSet();
    return _newImagePath != null ||
        _category != widget.item.category ||
        _brand != widget.item.brand ||
        _season != widget.item.season ||
        _name.text.trim() != (widget.item.name ?? '') ||
        _material.text.trim() != (widget.item.material ?? '') ||
        _price.text.trim() != _initialPrice ||
        originalColors.length != _colors.length ||
        !originalColors.containsAll(_colors);
  }

  /// Guards accidental exits (back button / close). Returns true if the user
  /// confirms they want to leave without saving.
  Future<bool> _confirmDiscard() async {
    final palette = context.palette;
    final leave = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: palette.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lg),
        title: Text('Discard changes?',
            style: AppTypography.headingSmall.copyWith(color: palette.textPrimary)),
        content: Text('You have unsaved edits to this piece. Leave without saving them?',
            style: AppTypography.bodyMedium.copyWith(color: palette.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: Text('Keep editing',
                style: AppTypography.labelMedium.copyWith(color: palette.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dCtx, true),
            child: Text('Discard',
                style: AppTypography.labelMedium.copyWith(color: palette.accentStrong)),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  /// Runs when the sheet is asked to close (system back or the close button).
  /// Confirms first when there are unsaved edits, then pops.
  Future<void> _handleClose() async {
    if (_hasUnsavedChanges && !await _confirmDiscard()) return;
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _save() async {
    if (_category == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pick a category')));
      return;
    }
    final ok = await ref.read(editPieceViewModelProvider.notifier).save(
          itemId: widget.item.itemId,
          category: _category!,
          name: _name.text.trim(),
          subCategory: widget.item.subCategory,
          brand: _brand,
          material: _material.text.trim().isEmpty ? null : _material.text.trim(),
          color: widget.item.color,
          season: _season,
          colors: _colors.toList(),
          price: double.tryParse(_price.text.trim()),
          tags: widget.item.tags,
          imagePath: _newImagePath,
        );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(EditPieceOutcome.saved);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Piece updated')));
    } else {
      final err = ref.read(editPieceViewModelProvider).error;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err ?? 'Could not update piece')));
    }
  }

  Future<void> _confirmDelete() async {
    final palette = context.palette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: palette.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lg),
        title: Text('Remove ${widget.item.displayName}?',
            style: AppTypography.headingSmall.copyWith(color: palette.textPrimary)),
        content: Text("This permanently removes the piece from your wardrobe. This can't be undone.",
            style: AppTypography.bodyMedium.copyWith(color: palette.textSecondary)),
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

    final ok = await ref.read(editPieceViewModelProvider.notifier).delete(widget.item.itemId);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(EditPieceOutcome.deleted);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Piece removed')));
    } else {
      final err = ref.read(editPieceViewModelProvider).error;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err ?? 'Could not remove piece')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final catalog = ref.watch(catalogViewModelProvider);
    final loadingCatalog = catalog.status == CatalogStatus.loading;
    final status = ref.watch(editPieceViewModelProvider).status;
    final saving = status == EditPieceStatus.saving;
    final deleting = status == EditPieceStatus.deleting;
    final busy = saving || deleting;

    final media = MediaQuery.of(context);
    final viewInsets = media.viewInsets.bottom;
    // Fixed tall sheet — leaves the status bar visible and lets the form scroll.
    final sheetHeight = (media.size.height - media.padding.top) * 0.94;

    // Slide-up sheet. Drag the grab area down a little to dismiss; the close
    // button / system back route through [_handleClose] so unsaved edits prompt
    // a confirmation first (guards against a misclicked back button).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleClose();
      },
      child: Transform.translate(
        offset: Offset(0, _dragOffset),
        child: Container(
          height: sheetHeight,
          decoration: BoxDecoration(
            color: palette.background,
            borderRadius: AppRadius.topOnly,
          ),
          child: Column(
            children: [
              // Grab area: dragging anywhere on the handle or title dismisses.
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragStart: _onDragStart,
                onVerticalDragUpdate: _onDragUpdate,
                onVerticalDragEnd: _onDragEnd,
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.space3),
                    Container(
                      width: 36,
                      height: 4,
                      decoration:
                          BoxDecoration(color: palette.border, borderRadius: AppRadius.full),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.space5, AppSpacing.space3,
                          AppSpacing.space2, AppSpacing.space2),
                      child: Row(
                        children: [
                          Text('Edit piece',
                              style: AppTypography.headingMedium
                                  .copyWith(color: palette.textPrimary)),
                          const Spacer(),
                          IconButton(
                            icon: Icon(Icons.close, color: palette.textTertiary),
                            onPressed: _handleClose,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: AppSpacing.paddingLg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    _photo(palette),
                    const SizedBox(height: AppSpacing.space5),
                    AppTextInput(
                      label: 'PIECE NAME',
                      hint: 'e.g. White Oxford Shirt',
                      controller: _name,
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    CatalogPickerField(
                      label: 'CATEGORY',
                      noun: 'category',
                      value: _category,
                      options: catalog.categories.map((c) => c.name).toList(),
                      loading: loadingCatalog,
                      onSelected: (v) => setState(() => _category = v),
                      onAddNew: _createCategory,
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    CatalogPickerField(
                      label: 'BRAND',
                      noun: 'brand',
                      value: _brand,
                      options: catalog.brands.map((b) => b.name).toList(),
                      loading: loadingCatalog,
                      onSelected: (v) => setState(() => _brand = v),
                      onAddNew: _createBrand,
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextInput(
                            label: 'PRICE',
                            hint: 'e.g. 120',
                            controller: _price,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space4),
                        Expanded(
                          child: AppTextInput(
                              label: 'MATERIAL', hint: 'e.g. Cotton', controller: _material),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    _fieldLabel(palette, 'COLOURS'),
                    const SizedBox(height: AppSpacing.space3),
                    ColorMultiPicker(
                      selected: _colors,
                      onChanged: (next) => setState(() {
                        _colors
                          ..clear()
                          ..addAll(next);
                      }),
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    _fieldLabel(palette, 'SEASON'),
                    const SizedBox(height: AppSpacing.space2),
                    Wrap(
                      spacing: AppSpacing.space2,
                      runSpacing: AppSpacing.space2,
                      children: [
                        for (final s in _seasons)
                          _SelectChip(
                            label: s,
                            selected: _season == s,
                            onTap: () => setState(() => _season = _season == s ? null : s),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space5),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CatalogManagerScreen()),
                        ),
                        icon: Icon(Icons.tune, size: AppSpacing.iconXs, color: palette.accentStrong),
                        label: Text('Manage categories & brands',
                            style: AppTypography.labelSmall.copyWith(color: palette.accentStrong)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
                Padding(
                  padding: EdgeInsets.only(
                    left: AppSpacing.space5,
                    right: AppSpacing.space5,
                    top: AppSpacing.space3,
                    bottom: AppSpacing.space5 + viewInsets,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppButton(
                        text: 'Save changes',
                        onPressed: busy ? null : _save,
                        isLoading: saving,
                        isFullWidth: true,
                        size: ButtonSize.large,
                      ),
                      const SizedBox(height: AppSpacing.space2),
                      TextButton.icon(
                        onPressed: busy ? null : _confirmDelete,
                        icon: deleting
                            ? SizedBox(
                                width: AppSpacing.iconXs,
                                height: AppSpacing.iconXs,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.danger),
                              )
                            : const Icon(Icons.delete_outline,
                                size: AppSpacing.iconSm, color: AppColors.danger),
                        label: Text('Remove piece',
                            style: AppTypography.labelMedium.copyWith(color: AppColors.danger)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  Widget _photo(AppPalette palette) {
    final url = _existingImageUrl;
    Widget content;
    if (_newImagePath != null) {
      content = Image.file(File(_newImagePath!), fit: BoxFit.cover);
    } else if (url != null) {
      content = CachedNetworkImage(imageUrl: url, fit: BoxFit.cover);
    } else {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt_outlined, size: 36, color: palette.textTertiary),
          const SizedBox(height: AppSpacing.space2),
          Text('Add a photo',
              style: AppTypography.labelLarge.copyWith(color: palette.textPrimary)),
        ],
      );
    }

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          color: palette.surfaceAlt,
          borderRadius: AppRadius.lg,
          border: Border.all(color: palette.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            content,
            Positioned(
              right: AppSpacing.space3,
              bottom: AppSpacing.space3,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space3, vertical: AppSpacing.space2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: AppRadius.pill,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.edit_outlined, size: 14, color: Colors.white),
                    SizedBox(width: 6),
                    Text('Change photo', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(AppPalette palette, String text) => Text(
        text,
        style: AppTypography.labelSmall.copyWith(
            color: palette.textSecondary, fontWeight: FontWeight.w600, letterSpacing: 1.0),
      );
}

class _SelectChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SelectChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4, vertical: AppSpacing.space2),
        decoration: BoxDecoration(
          color: selected ? palette.textPrimary : palette.surface,
          borderRadius: AppRadius.pill,
          border: Border.all(color: selected ? palette.textPrimary : palette.border),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: selected ? palette.background : palette.textSecondary,
            fontWeight: selected ? AppTypography.semibold : AppTypography.regular,
          ),
        ),
      ),
    );
  }
}
