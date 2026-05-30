import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../view_model/catalog_view_model.dart';

/// Section where users manage their wardrobe taxonomy — global presets are
/// shown for reference, and users can add their own categories and brands.
class CatalogManagerScreen extends ConsumerStatefulWidget {
  const CatalogManagerScreen({super.key});

  @override
  ConsumerState<CatalogManagerScreen> createState() => _CatalogManagerScreenState();
}

class _CatalogManagerScreenState extends ConsumerState<CatalogManagerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(catalogViewModelProvider.notifier).load();
    });
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

  Future<void> _addCategory() async {
    final name = await _promptNew('category', 'e.g. Knitwear');
    if (name == null || name.isEmpty) return;
    await ref.read(catalogViewModelProvider.notifier).addCategory(name);
  }

  Future<void> _addBrand() async {
    final name = await _promptNew('brand', 'e.g. Atelier Noor');
    if (name == null || name.isEmpty) return;
    await ref.read(catalogViewModelProvider.notifier).addBrand(name);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final catalog = ref.watch(catalogViewModelProvider);

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
        title: Text('Categories & Brands',
            style: AppTypography.headingMedium.copyWith(color: palette.textPrimary)),
        centerTitle: true,
      ),
      body: catalog.status == CatalogStatus.loading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
                strokeWidth: 2.5,
              ),
            )
          : ListView(
              padding: AppSpacing.paddingLg,
              children: [
                _section(
                  palette,
                  title: 'Categories',
                  subtitle: 'Presets plus any you create. Used when adding pieces.',
                  chips: [
                    for (final c in catalog.categories)
                      _Pill(label: c.name, custom: c.isCustom),
                  ],
                  onAdd: _addCategory,
                ),
                const SizedBox(height: AppSpacing.space8),
                _section(
                  palette,
                  title: 'Brands',
                  subtitle: 'Presets plus your own labels.',
                  chips: [
                    for (final b in catalog.brands)
                      _Pill(label: b.name, custom: b.isCustom),
                  ],
                  onAdd: _addBrand,
                ),
              ],
            ),
    );
  }

  Widget _section(
    AppPalette palette, {
    required String title,
    required String subtitle,
    required List<Widget> chips,
    required VoidCallback onAdd,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTypography.headingMedium.copyWith(color: palette.textPrimary)),
            GestureDetector(
              onTap: onAdd,
              child: Row(
                children: [
                  Icon(Icons.add, size: AppSpacing.iconXs, color: palette.accentStrong),
                  const SizedBox(width: 2),
                  Text('Add',
                      style: AppTypography.labelSmall.copyWith(color: palette.accentStrong)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(subtitle, style: AppTypography.bodyMedium.copyWith(color: palette.textTertiary)),
        const SizedBox(height: AppSpacing.space4),
        if (chips.isEmpty)
          Text('None yet — tap Add to create one.',
              style: AppTypography.bodyMedium.copyWith(color: palette.textTertiary))
        else
          Wrap(spacing: AppSpacing.space2, runSpacing: AppSpacing.space2, children: chips),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool custom;
  const _Pill({required this.label, required this.custom});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4, vertical: AppSpacing.space2),
      decoration: BoxDecoration(
        color: custom ? palette.surfaceAlt : palette.surface,
        borderRadius: AppRadius.pill,
        border: Border.all(color: custom ? palette.accent : palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (custom) ...[
            Icon(Icons.person_outline, size: 12, color: palette.accentStrong),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: AppTypography.labelSmall.copyWith(color: palette.textSecondary)),
        ],
      ),
    );
  }
}
