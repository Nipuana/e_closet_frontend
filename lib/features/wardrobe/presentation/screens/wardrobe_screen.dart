import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/wardrobe_item_entity.dart';
import '../state/wardrobe_state.dart';
import '../view_model/wardrobe_view_model.dart';
import 'edit_piece_screen.dart';
import 'item_detail_screen.dart';

/// Wardrobe tab — the full collection grid with search and category filters.
class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  String _query = '';
  String _category = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wardrobeViewModelProvider.notifier).loadAllItems();
    });
  }

  List<String> _categories(List<WardrobeItemEntity> items) {
    final set = <String>{for (final i in items) i.category};
    return ['All', ...set.toList()..sort()];
  }

  List<WardrobeItemEntity> _filtered(List<WardrobeItemEntity> items) {
    final q = _query.trim().toLowerCase();
    return items.where((i) {
      if (_category != 'All' && i.category != _category) return false;
      if (q.isEmpty) return true;
      final haystack = [
        i.displayName,
        i.category,
        i.brand ?? '',
        i.color ?? '',
        ...i.tags,
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  void _comingSoon(String label) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$label is coming soon')));
  }

  /// Long-press an item to slide up the editor sheet for its details.
  Future<void> _editItem(WardrobeItemEntity item) async {
    final outcome = await showEditPieceSheet(context, item: item);
    if (outcome != null && mounted) {
      // Both a save and a delete change the grid, so reload either way.
      ref.read(wardrobeViewModelProvider.notifier).loadAllItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final state = ref.watch(wardrobeViewModelProvider);
    final categories = _categories(state.allItems);
    final filtered = _filtered(state.allItems);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${state.allItems.length} PIECES',
                          style: AppTypography.labelSmall.copyWith(
                            color: palette.textTertiary,
                            letterSpacing: 1.6,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space1),
                        Text(
                          'Wardrobe',
                          style: AppTypography.headingXlarge
                              .copyWith(color: palette.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  _RoundIconButton(
                    icon: Icons.tune,
                    onTap: () => _comingSoon('Filters'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            // Search
            Padding(
              padding: AppSpacing.paddingHorizontalLg,
              child: _SearchField(
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            // Category chips
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: AppSpacing.paddingHorizontalLg,
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.space2),
                itemBuilder: (context, i) {
                  final c = categories[i];
                  return _CategoryChip(
                    label: c,
                    selected: c == _category,
                    onTap: () => setState(() => _category = c),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            // Count + sort
            Padding(
              padding: AppSpacing.paddingHorizontalLg,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${filtered.length} pieces',
                    style: AppTypography.bodyMedium.copyWith(color: palette.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () => _comingSoon('Sort'),
                    child: Row(
                      children: [
                        Icon(Icons.sort, size: AppSpacing.iconXs, color: palette.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Sort',
                          style: AppTypography.labelSmall.copyWith(color: palette.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            // Grid / states
            Expanded(child: _body(state, filtered, palette)),
          ],
        ),
      ),
    );
  }

  Widget _body(
    WardrobeState state,
    List<WardrobeItemEntity> filtered,
    AppPalette palette,
  ) {
    if (state.allStatus == WardrobeStatus.loading ||
        state.allStatus == WardrobeStatus.initial) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
          strokeWidth: 2.5,
        ),
      );
    }
    if (state.allStatus == WardrobeStatus.error) {
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
    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: AppSpacing.paddingHorizontalLg,
          child: Text(
            state.allItems.isEmpty
                ? 'Your wardrobe is empty. Tap + to add your first piece.'
                : 'No pieces match your search.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(color: palette.textTertiary),
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: palette.accent,
      onRefresh: () => ref.read(wardrobeViewModelProvider.notifier).loadAllItems(),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.space6),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.space4,
          mainAxisSpacing: AppSpacing.space5,
          childAspectRatio: 0.62,
        ),
        itemCount: filtered.length,
        itemBuilder: (context, i) => _WardrobeGridCard(
          item: filtered[i],
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ItemDetailScreen(item: filtered[i])),
            );
            if (mounted) ref.read(wardrobeViewModelProvider.notifier).loadAllItems();
          },
          onLongPress: () => _editItem(filtered[i]),
          onFavorite: () => ref
              .read(wardrobeViewModelProvider.notifier)
              .toggleFavorite(filtered[i]),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: palette.surface,
          shape: BoxShape.circle,
          border: Border.all(color: palette.border),
        ),
        child: Icon(icon, size: AppSpacing.iconSm, color: palette.textPrimary),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchField({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return TextField(
      onChanged: onChanged,
      style: AppTypography.bodyMedium.copyWith(color: palette.textPrimary),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Search pieces, colors, tags',
        hintStyle: AppTypography.bodyMedium.copyWith(color: palette.textTertiary),
        prefixIcon: Icon(Icons.search, size: AppSpacing.iconSm, color: palette.textTertiary),
        filled: true,
        fillColor: palette.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
        border: OutlineInputBorder(
          borderRadius: AppRadius.pill,
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.pill,
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.pill,
          borderSide: BorderSide(color: palette.accent, width: 1.5),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
        alignment: Alignment.center,
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

class _WardrobeGridCard extends StatelessWidget {
  final WardrobeItemEntity item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onFavorite;

  const _WardrobeGridCard({
    required this.item,
    required this.onTap,
    required this.onLongPress,
    required this.onFavorite,
  });

  String get _imageUrl {
    final url = item.imageUrl;
    if (url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '${ApiEndpoints.serverAddress}$url';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: AppRadius.lg,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: palette.surfaceAlt,
                    child: _imageUrl.isEmpty
                        ? Icon(Icons.checkroom_outlined, color: palette.textTertiary)
                        : CachedNetworkImage(
                            imageUrl: _imageUrl,
                            fit: BoxFit.cover,
                            // Decode to roughly the on-screen thumbnail size
                            // instead of the full camera resolution — far less
                            // memory and no decode jank while the grid loads.
                            memCacheWidth: 500,
                            placeholder: (_, _) => const SizedBox(),
                            errorWidget: (_, _, _) =>
                                Icon(Icons.checkroom_outlined, color: palette.textTertiary),
                          ),
                  ),
                  Positioned(
                    top: AppSpacing.space2,
                    right: AppSpacing.space2,
                    child: GestureDetector(
                      onTap: onFavorite,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(color: palette.surface, shape: BoxShape.circle),
                        child: Icon(
                          item.isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: AppSpacing.iconXs,
                          color: item.isFavorite ? AppColors.danger : palette.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMedium.copyWith(color: palette.textPrimary),
                ),
              ),
              if (item.purchasePrice != null)
                Text(
                  '\$${item.purchasePrice!.toStringAsFixed(0)}',
                  style: AppTypography.labelMedium.copyWith(color: palette.textPrimary),
                ),
            ],
          ),
          if (item.brand != null && item.brand!.isNotEmpty)
            Text(
              item.brand!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.captionSmall.copyWith(color: palette.textTertiary),
            ),
        ],
      ),
    );
  }
}
