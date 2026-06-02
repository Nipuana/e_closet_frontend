import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../wardrobe/domain/entities/wardrobe_item_entity.dart';
import '../../../wardrobe/presentation/view_model/wardrobe_view_model.dart';
import '../../domain/entities/outfit_entity.dart';
import '../view_model/outfit_list_view_model.dart';
import '../widgets/outfit_visuals.dart';
import 'assemble_screen.dart';

/// The Lookbook — every ensemble the user has assembled. Open one to edit it,
/// delete one, or assemble a new one.
class LookbookScreen extends ConsumerStatefulWidget {
  /// When shown as a bottom-nav tab, hide the back button and use a tab title.
  final bool showBackButton;
  final String title;

  const LookbookScreen({
    super.key,
    this.showBackButton = true,
    this.title = 'Lookbook',
  });

  @override
  ConsumerState<LookbookScreen> createState() => _LookbookScreenState();
}

class _LookbookScreenState extends ConsumerState<LookbookScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(outfitListViewModelProvider.notifier).load();
      ref.read(wardrobeViewModelProvider.notifier).loadAllItems();
    });
  }

  Future<void> _assemble([OutfitEntity? existing]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AssembleScreen(initial: existing)),
    );
    if (saved == true && mounted) {
      ref.read(outfitListViewModelProvider.notifier).load();
    }
  }

  Future<void> _confirmDelete(OutfitEntity outfit) async {
    final palette = context.palette;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: palette.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lg),
        title: Text('Delete “${outfit.name}”?',
            style: AppTypography.headingSmall.copyWith(color: palette.textPrimary)),
        content: Text('This ensemble and any plans using it will be removed.',
            style: AppTypography.bodyMedium.copyWith(color: palette.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text('Cancel',
                style: AppTypography.labelMedium.copyWith(color: palette.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text('Delete',
                style: AppTypography.labelMedium.copyWith(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true || outfit.id == null) return;
    HapticFeedback.mediumImpact();
    final success = await ref.read(outfitListViewModelProvider.notifier).delete(outfit.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Ensemble deleted' : 'Could not delete — try again')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final state = ref.watch(outfitListViewModelProvider);
    final byId = {
      for (final i in ref.watch(wardrobeViewModelProvider).allItems) i.itemId: i,
    };

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        automaticallyImplyLeading: false,
        leading: widget.showBackButton
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new,
                    size: AppSpacing.iconSm, color: palette.textPrimary),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(widget.title,
            style: AppTypography.headingMedium.copyWith(color: palette.textPrimary)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: palette.textPrimary),
            onPressed: () => _assemble(),
          ),
        ],
      ),
      body: SafeArea(top: false, child: _body(context, state, byId)),
    );
  }

  Widget _body(
    BuildContext context,
    OutfitListState state,
    Map<String, WardrobeItemEntity> byId,
  ) {
    final palette = context.palette;

    switch (state.status) {
      case OutfitListStatus.initial:
      case OutfitListStatus.loading:
        return Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
            strokeWidth: 2.5,
          ),
        );
      case OutfitListStatus.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Couldn't load your Lookbook",
                  style: AppTypography.bodyMedium.copyWith(color: palette.textSecondary)),
              const SizedBox(height: AppSpacing.space2),
              TextButton(
                onPressed: () => ref.read(outfitListViewModelProvider.notifier).load(),
                child: Text('Retry',
                    style: AppTypography.labelSmall.copyWith(color: palette.accentStrong)),
              ),
            ],
          ),
        );
      case OutfitListStatus.ready:
        if (state.outfits.isEmpty) {
          return Center(
            child: Padding(
              padding: AppSpacing.paddingLg,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_outlined,
                      size: AppSpacing.iconXl, color: palette.textTertiary),
                  const SizedBox(height: AppSpacing.space4),
                  Text('No ensembles yet',
                      style: AppTypography.headingSmall.copyWith(color: palette.textPrimary)),
                  const SizedBox(height: AppSpacing.space2),
                  Text('Assemble your first outfit to start your Lookbook.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(color: palette.textSecondary)),
                ],
              ),
            ),
          );
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.space5, AppSpacing.space2, AppSpacing.space5, AppSpacing.space2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${state.outfits.length} saved ${state.outfits.length == 1 ? 'ensemble' : 'ensembles'}, ready to wear.',
                  style: AppTypography.bodyMedium.copyWith(color: palette.textSecondary),
                ),
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.space5, AppSpacing.space2, AppSpacing.space5, AppSpacing.space10),
                mainAxisSpacing: AppSpacing.space4,
                crossAxisSpacing: AppSpacing.space4,
                childAspectRatio: 0.74,
                children: [
                  for (final outfit in state.outfits)
                    OutfitCard(
                      outfit: outfit,
                      items: outfit.items
                          .map((id) => byId[id])
                          .whereType<WardrobeItemEntity>()
                          .toList(),
                      onTap: () => _assemble(outfit),
                      onDelete: () => _confirmDelete(outfit),
                    ),
                ],
              ),
            ),
          ],
        );
    }
  }
}

/// Reusable ensemble card — collage preview, name and piece count. Used in the
/// Lookbook and (read-only) elsewhere.
class OutfitCard extends StatelessWidget {
  final OutfitEntity outfit;
  final List<WardrobeItemEntity> items;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const OutfitCard({
    super.key,
    required this.outfit,
    required this.items,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: AppRadius.lg,
          border: Border.all(color: palette.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: OutfitThumbnail(items: items)),
                  if (onDelete != null)
                    Positioned(
                      top: AppSpacing.space1,
                      right: AppSpacing.space1,
                      child: Material(
                        color: palette.surface.withValues(alpha: 0.9),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onDelete,
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.space2),
                            child: Icon(Icons.delete_outline,
                                size: AppSpacing.iconSm, color: palette.textTertiary),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.space3, AppSpacing.space2, AppSpacing.space3, AppSpacing.space3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(outfit.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelLarge.copyWith(color: palette.textPrimary)),
                  Text(
                    '${outfit.pieceCount} ${outfit.pieceCount == 1 ? 'piece' : 'pieces'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.captionSmall.copyWith(color: palette.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
