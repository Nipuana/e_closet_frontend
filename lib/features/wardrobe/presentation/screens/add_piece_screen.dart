import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../common/common.dart';
import '../../../../common/widgets/color_swatches.dart';
import '../../../../core/theme/theme.dart';
import '../../../catalog/presentation/screens/catalog_manager_screen.dart';
import '../../../catalog/presentation/view_model/catalog_view_model.dart';
import '../../../catalog/presentation/widgets/catalog_picker.dart';
import '../../domain/usecases/add_item_usecase.dart';
import '../view_model/add_piece_view_model.dart';
import '../view_model/wardrobe_view_model.dart';

/// Add a new wardrobe piece via a 3-step flow: Capture → Details → Review.
/// Categories and brands come from the backend (global presets + the user's
/// own), and new ones can be created inline.
class AddPieceScreen extends ConsumerStatefulWidget {
  const AddPieceScreen({super.key});

  @override
  ConsumerState<AddPieceScreen> createState() => _AddPieceScreenState();
}

class _AddPieceScreenState extends ConsumerState<AddPieceScreen> {
  static const _seasons = ['Spring', 'Summer', 'Autumn', 'Winter', 'All-season'];

  int _step = 0;
  String? _imagePath;
  String? _category;
  String? _brand;
  String? _season;

  final Set<String> _colors = {};

  final _name = TextEditingController();
  final _price = TextEditingController();
  final _material = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(catalogViewModelProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _material.dispose();
    super.dispose();
  }

  /// Ask whether to shoot a new photo or pick an existing one, then capture.
  Future<void> _pickImage() async {
    final source = await _chooseImageSource();
    if (source == null) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 85);
    if (file != null && mounted) setState(() => _imagePath = file.path);
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
              decoration: BoxDecoration(
                color: palette.border,
                borderRadius: AppRadius.pill,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            ListTile(
              leading: Icon(Icons.camera_alt_outlined, color: palette.accent),
              title: Text('Take a photo',
                  style: AppTypography.labelLarge.copyWith(color: palette.textPrimary)),
              subtitle: Text('Open the camera now',
                  style: AppTypography.captionSmall.copyWith(color: palette.textTertiary)),
              onTap: () => Navigator.pop(sheetCtx, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: palette.accent),
              title: Text('Choose from gallery',
                  style: AppTypography.labelLarge.copyWith(color: palette.textPrimary)),
              subtitle: Text('Pick an existing photo',
                  style: AppTypography.captionSmall.copyWith(color: palette.textTertiary)),
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

  bool get _canContinue {
    if (_step == 0) return true; // photo is optional
    if (_step == 1) return _name.text.trim().isNotEmpty && _category != null;
    return true;
  }

  void _onPrimary() {
    if (_step < 2) {
      setState(() => _step += 1);
    } else {
      _submit();
    }
  }

  void _onBack() {
    if (_step > 0) {
      setState(() => _step -= 1);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _submit() async {
    final params = AddItemParams(
      imagePath: _imagePath,
      category: _category!,
      name: _name.text.trim(),
      brand: _brand,
      material: _material.text.trim().isEmpty ? null : _material.text.trim(),
      colors: _colors.toList(),
      season: _season,
      price: double.tryParse(_price.text.trim()),
    );

    final ok = await ref.read(addPieceViewModelProvider.notifier).submit(params);
    if (!mounted) return;
    if (ok) {
      ref.read(wardrobeViewModelProvider.notifier).loadAllItems();
      ref.read(wardrobeViewModelProvider.notifier).loadDashboard();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Piece added to your wardrobe')));
    } else {
      final err = ref.read(addPieceViewModelProvider).error;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err ?? 'Could not add piece')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final submitting =
        ref.watch(addPieceViewModelProvider).status == AddPieceStatus.submitting;
    const labels = ['Capture', 'Details', 'Review'];

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: Icon(_step == 0 ? Icons.close : Icons.arrow_back_ios_new,
              size: AppSpacing.iconSm, color: palette.textPrimary),
          onPressed: _onBack,
        ),
        title: Text('Add a piece',
            style: AppTypography.headingMedium.copyWith(color: palette.textPrimary)),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: AppSpacing.paddingLg,
              child: Row(
                children: [
                  for (int i = 0; i < 3; i++) ...[
                    _StepDot(index: i, label: labels[i], step: _step),
                    if (i < 2)
                      Expanded(
                        child: Container(
                          height: 1,
                          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.space2),
                          color: i < _step ? palette.accent : palette.border,
                        ),
                      ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.paddingHorizontalLg,
                child: _stepBody(palette),
              ),
            ),
            Padding(
              padding: AppSpacing.paddingLg,
              child: AppButton(
                text: _step < 2 ? (_step == 0 ? 'Continue' : 'Review') : 'Add to wardrobe',
                onPressed: _canContinue && !submitting ? _onPrimary : null,
                isLoading: submitting,
                isFullWidth: true,
                size: ButtonSize.large,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepBody(AppPalette palette) {
    switch (_step) {
      case 0:
        return _captureStep(palette);
      case 1:
        return _detailsStep(palette);
      default:
        return _reviewStep(palette);
    }
  }

  Widget _captureStep(AppPalette palette) {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 360,
            width: double.infinity,
            decoration: BoxDecoration(
              color: palette.surfaceAlt,
              borderRadius: AppRadius.lg,
              border: Border.all(color: palette.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: _imagePath == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined, size: 36, color: palette.textTertiary),
                      const SizedBox(height: AppSpacing.space3),
                      Text('Add a photo (optional)',
                          style: AppTypography.labelLarge.copyWith(color: palette.textPrimary)),
                      const SizedBox(height: AppSpacing.space1),
                      Text('Tap to shoot with the camera or pick from your gallery — or skip and add one later',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(color: palette.textTertiary)),
                    ],
                  )
                : Image.file(File(_imagePath!), fit: BoxFit.cover),
          ),
        ),
        if (_imagePath != null) ...[
          const SizedBox(height: AppSpacing.space3),
          TextButton(
            onPressed: _pickImage,
            child: Text('Choose a different photo',
                style: AppTypography.labelMedium.copyWith(color: palette.accentStrong)),
          ),
        ],
      ],
    );
  }

  Widget _detailsStep(AppPalette palette) {
    final catalog = ref.watch(catalogViewModelProvider);
    final loadingCatalog = catalog.status == CatalogStatus.loading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextInput(
          label: 'PIECE NAME',
          hint: 'e.g. White Oxford Shirt',
          controller: _name,
          onChanged: (_) => setState(() {}),
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
            Expanded(child: AppTextInput(label: 'MATERIAL', hint: 'e.g. Cotton', controller: _material)),
          ],
        ),
        const SizedBox(height: AppSpacing.space4),
        _fieldLabel(palette, 'COLOURS'),
        const SizedBox(height: AppSpacing.space1),
        Text('Pick one or more — multi-colour pieces can have several.',
            style: AppTypography.captionSmall.copyWith(color: palette.textTertiary)),
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
    );
  }

  Widget _reviewStep(AppPalette palette) {
    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                child: Text(k,
                    style: AppTypography.captionSmall.copyWith(
                        color: palette.textTertiary, letterSpacing: 1.0)),
              ),
              Expanded(
                child: Text(v.isEmpty ? '—' : v,
                    style: AppTypography.bodyMedium.copyWith(color: palette.textPrimary)),
              ),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_imagePath != null)
          ClipRRect(
            borderRadius: AppRadius.lg,
            child: Image.file(File(_imagePath!), height: 220, width: double.infinity, fit: BoxFit.cover),
          ),
        const SizedBox(height: AppSpacing.space4),
        row('NAME', _name.text.trim()),
        row('CATEGORY', _category ?? ''),
        row('BRAND', _brand ?? ''),
        row('PRICE', _price.text.trim().isEmpty ? '' : '\$${_price.text.trim()}'),
        row('MATERIAL', _material.text.trim()),
        row('COLOURS', _colors.join(', ')),
        row('SEASON', _season ?? ''),
      ],
    );
  }

  Widget _fieldLabel(AppPalette palette, String text) => Text(
        text,
        style: AppTypography.labelSmall.copyWith(
            color: palette.textSecondary, fontWeight: FontWeight.w600, letterSpacing: 1.0),
      );

}

class _StepDot extends StatelessWidget {
  final int index;
  final int step;
  final String label;
  const _StepDot({required this.index, required this.step, required this.label});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final done = index < step;
    final active = index == step;
    final filled = done || active;
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: filled ? palette.textPrimary : palette.surface,
            shape: BoxShape.circle,
            border: Border.all(color: filled ? palette.textPrimary : palette.border),
          ),
          alignment: Alignment.center,
          child: done
              ? Icon(Icons.check, size: 14, color: palette.background)
              : Text('${index + 1}',
                  style: AppTypography.captionSmall.copyWith(
                      color: filled ? palette.background : palette.textTertiary)),
        ),
        const SizedBox(width: AppSpacing.space2),
        Text(label,
            style: AppTypography.labelSmall.copyWith(
                color: active ? palette.textPrimary : palette.textTertiary)),
      ],
    );
  }
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
