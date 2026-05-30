import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../common/widgets/color_swatches.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/theme/theme.dart';
import '../../../closet/domain/entities/wardrobe_layout_entity.dart';
import '../../../closet/presentation/closet_modules.dart';
import '../../../closet/presentation/screens/closet_view_screen.dart';
import '../../../closet/presentation/view_model/wardrobe_list_view_model.dart';
import '../../domain/entities/wardrobe_item_entity.dart';
import '../view_model/item_detail_view_model.dart';
import '../view_model/wardrobe_view_model.dart';
import 'edit_piece_screen.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  final WardrobeItemEntity item;
  const ItemDetailScreen({super.key, required this.item});

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(itemDetailProvider.notifier)
        ..seed(widget.item)
        ..refresh();
      // Load the user's closets so we can show where this piece is stored.
      ref.read(wardrobeListViewModelProvider.notifier).load();
    });
  }

  /// Find the closet + compartment that stores [itemId], if any.
  ({WardrobeLayoutEntity layout, int r, int c})? _findStorage(String itemId) {
    final layouts = ref.watch(wardrobeListViewModelProvider).wardrobes;
    for (final layout in layouts) {
      for (final entry in layout.placements.entries) {
        if (entry.value.contains(itemId)) {
          final parts = entry.key.split(',');
          final r = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
          final c = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
          return (layout: layout, r: r, c: c);
        }
      }
    }
    return null;
  }

  String _img(String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '${ApiEndpoints.serverAddress}$url';
  }

  void _syncWardrobe() =>
      ref.read(wardrobeViewModelProvider.notifier).loadAllItems();

  void _openOptions(WardrobeItemEntity item) {
    final palette = context.palette;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.topOnly),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.space2),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: palette.border, borderRadius: BorderRadius.circular(99)),
            ),
            const SizedBox(height: AppSpacing.space3),
            _OptionTile(icon: Icons.checkroom_outlined, label: 'Add to an outfit',
                onTap: () { Navigator.pop(sheetCtx); _comingSoon('Outfit builder'); }),
            _OptionTile(icon: Icons.edit_outlined, label: 'Edit details',
                onTap: () { Navigator.pop(sheetCtx); _editDetails(item); }),
            _OptionTile(icon: Icons.ios_share_outlined, label: 'Share piece',
                onTap: () { Navigator.pop(sheetCtx); _comingSoon('Sharing'); }),
            _OptionTile(icon: Icons.delete_outline, label: 'Remove from wardrobe',
                danger: true,
                onTap: () { Navigator.pop(sheetCtx); _confirmRemove(item); }),
            const SizedBox(height: AppSpacing.space4),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRemove(WardrobeItemEntity item) async {
    final palette = context.palette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: palette.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lg),
        title: Text('Remove ${item.displayName}?',
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

    final ok = await ref.read(itemDetailProvider.notifier).delete();
    if (!mounted) return;
    if (ok) {
      _syncWardrobe();
      ref.read(wardrobeViewModelProvider.notifier).loadDashboard();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Piece removed')));
    } else {
      final err = ref.read(itemDetailProvider).error;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err ?? 'Could not remove piece')));
    }
  }

  void _comingSoon(String label) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text('$label is coming soon')));

  Future<void> _editDetails(WardrobeItemEntity item) async {
    final outcome = await showEditPieceSheet(context, item: item);
    if (!mounted || outcome == null) return;

    if (outcome == EditPieceOutcome.deleted) {
      // The piece no longer exists — refresh the wardrobe and close this screen.
      _syncWardrobe();
      ref.read(wardrobeViewModelProvider.notifier).loadDashboard();
      Navigator.of(context).pop();
    } else {
      ref.read(itemDetailProvider.notifier).refresh();
      _syncWardrobe();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final item = ref.watch(itemDetailProvider).item ?? widget.item;

    final cpw = (item.purchasePrice != null && item.usageCount > 0)
        ? item.purchasePrice! / item.usageCount
        : null;

    final storage = _findStorage(item.itemId);

    return Scaffold(
      backgroundColor: palette.background,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Image + overlay actions
          Stack(
            children: [
              SizedBox(
                height: 420,
                width: double.infinity,
                child: _img(item.imageUrl).isEmpty
                    ? Container(color: palette.surfaceAlt,
                        child: Icon(Icons.checkroom_outlined, size: 64, color: palette.textTertiary))
                    : CachedNetworkImage(imageUrl: _img(item.imageUrl), fit: BoxFit.cover),
              ),
              SafeArea(
                child: Padding(
                  padding: AppSpacing.paddingMd,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CircleButton(icon: Icons.arrow_back_ios_new, onTap: () => Navigator.pop(context)),
                      Row(
                        children: [
                          _CircleButton(
                            icon: item.isFavorite ? Icons.favorite : Icons.favorite_border,
                            iconColor: item.isFavorite ? AppColors.danger : null,
                            onTap: () async {
                              await ref.read(itemDetailProvider.notifier).toggleFavorite();
                              _syncWardrobe();
                            },
                          ),
                          const SizedBox(width: AppSpacing.space2),
                          _CircleButton(icon: Icons.more_horiz, onTap: () => _openOptions(item)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: AppSpacing.paddingLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.displayName,
                    style: AppTypography.headingLarge.copyWith(color: palette.textPrimary)),
                if (item.brand != null && item.brand!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(item.brand!,
                      style: AppTypography.bodyLarge.copyWith(color: palette.textSecondary)),
                ],
                const SizedBox(height: AppSpacing.space3),
                Wrap(
                  spacing: AppSpacing.space2,
                  runSpacing: AppSpacing.space2,
                  children: [
                    _Tag(item.category),
                    if (item.season != null && item.season!.isNotEmpty) _Tag(item.season!),
                    _Tag('${item.usageCount} wears'),
                  ],
                ),
                const SizedBox(height: AppSpacing.space5),
                _CostPerWearCard(price: item.purchasePrice, cpw: cpw, wears: item.usageCount),
                const SizedBox(height: AppSpacing.space5),
                _DetailRow(label: 'MATERIAL', value: item.material),
                _ColorsRow(colors: item.colors, palette: item.colorPalette),
                _DetailRow(label: 'SEASON', value: item.season),
                _DetailRow(
                  label: 'ADDED',
                  value: item.createdAt != null
                      ? DateFormat('MMMM d, y').format(item.createdAt!)
                      : null,
                ),
                _DetailRow(label: 'TIMES WORN', value: '${item.usageCount}'),
                const SizedBox(height: AppSpacing.space5),
                _StorageCard(
                  storage: storage,
                  onView: storage == null
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ClosetViewScreen(
                                layout: storage.layout,
                                focusRow: storage.r,
                                focusCol: storage.c,
                              ),
                            ),
                          ),
                ),
                const SizedBox(height: AppSpacing.space5),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(itemDetailProvider.notifier).markWorn();
                      _syncWardrobe();
                    },
                    icon: const Icon(Icons.check_circle_outline, size: AppSpacing.iconSm),
                    label: const Text('Mark as worn today'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: palette.textPrimary,
                      side: BorderSide(color: palette.border),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      shape: const RoundedRectangleBorder(borderRadius: AppRadius.pill),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: palette.surface, shape: BoxShape.circle),
        child: Icon(icon, size: AppSpacing.iconSm, color: iconColor ?? palette.textPrimary),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag(this.label);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3, vertical: AppSpacing.space1),
      decoration: BoxDecoration(color: palette.surfaceAlt, borderRadius: AppRadius.pill),
      child: Text(label, style: AppTypography.captionSmall.copyWith(color: palette.textSecondary)),
    );
  }
}

class _CostPerWearCard extends StatelessWidget {
  final double? price;
  final double? cpw;
  final int wears;
  const _CostPerWearCard({required this.price, required this.cpw, required this.wears});

  ({String label, double fill}) get _value {
    if (cpw == null) return (label: 'Wear it to start tracking value', fill: 0.05);
    if (cpw! < 10) return (label: 'Excellent value', fill: 0.92);
    if (cpw! < 25) return (label: 'Good value', fill: 0.66);
    if (cpw! < 50) return (label: 'Building value', fill: 0.4);
    return (label: 'Worn rarely', fill: 0.2);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final v = _value;
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.lg,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('COST PER WEAR',
                  style: AppTypography.captionSmall.copyWith(
                      color: palette.textTertiary, letterSpacing: 1.0)),
              Text(cpw != null ? '\$${cpw!.toStringAsFixed(2)}' : '—',
                  style: AppTypography.headingMedium.copyWith(color: palette.accentStrong)),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: v.fill,
              minHeight: 8,
              backgroundColor: palette.surfaceAlt,
              valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(v.label, style: AppTypography.bodyMedium.copyWith(color: palette.textSecondary)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String? value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: AppTypography.captionSmall.copyWith(
                    color: palette.textTertiary, letterSpacing: 1.0)),
          ),
          Expanded(
            child: Text((value == null || value!.isEmpty) ? '—' : value!,
                style: AppTypography.bodyLarge.copyWith(color: palette.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class _ColorsRow extends StatelessWidget {
  final List<String> colors; // user-picked names
  final List<String> palette; // auto-extracted hex
  const _ColorsRow({required this.colors, required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final swatches = colors.isNotEmpty ? colors : palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text('COLOURS',
                style: AppTypography.captionSmall.copyWith(
                    color: p.textTertiary, letterSpacing: 1.0)),
          ),
          Expanded(
            child: swatches.isEmpty
                ? Text('—', style: AppTypography.bodyLarge.copyWith(color: p.textPrimary))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final c in swatches)
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: colorForName(c),
                                shape: BoxShape.circle,
                                border: Border.all(color: p.border),
                              ),
                            ),
                        ],
                      ),
                      if (colors.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.space2),
                        Text(colors.join(' · '),
                            style: AppTypography.bodyMedium.copyWith(color: p.textSecondary)),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _StorageCard extends StatelessWidget {
  final ({WardrobeLayoutEntity layout, int r, int c})? storage;
  final VoidCallback? onView;
  const _StorageCard({required this.storage, this.onView});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final s = storage;

    if (s == null) {
      return Container(
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: AppRadius.lg,
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            Icon(Icons.door_sliding_outlined, size: AppSpacing.iconSm, color: palette.textTertiary),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Text('Not placed in a closet yet',
                  style: AppTypography.bodyMedium.copyWith(color: palette.textSecondary)),
            ),
          ],
        ),
      );
    }

    final module = moduleById(s.layout.cellAt(s.r, s.c).moduleId);
    return GestureDetector(
      onTap: onView,
      child: Container(
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: AppRadius.lg,
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: palette.surfaceAlt, borderRadius: AppRadius.md),
              child: Icon(module?.icon ?? Icons.inventory_2_outlined,
                  size: AppSpacing.iconSm, color: palette.accent),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('STORED IN',
                      style: AppTypography.captionSmall
                          .copyWith(color: palette.textTertiary, letterSpacing: 1.0)),
                  Text(
                    '${s.layout.name} · ${module?.label ?? 'Compartment'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelLarge.copyWith(color: palette.textPrimary),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text('View',
                    style: AppTypography.labelSmall.copyWith(color: palette.accentStrong)),
                Icon(Icons.chevron_right, color: palette.textTertiary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;
  final VoidCallback onTap;
  const _OptionTile({required this.icon, required this.label, this.danger = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = danger ? AppColors.danger : palette.textPrimary;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color, size: AppSpacing.iconSm),
      title: Text(label, style: AppTypography.labelLarge.copyWith(color: color)),
    );
  }
}
