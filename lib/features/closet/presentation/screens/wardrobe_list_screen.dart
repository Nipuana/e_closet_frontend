import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common/common.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/wardrobe_layout_entity.dart';
import '../closet_presets.dart';
import '../view_model/wardrobe_list_view_model.dart';
import 'wardrobe_designer_screen.dart';
import 'wardrobe_preset_picker_screen.dart';

/// Lists all of the user's wardrobes. From here they can open one to edit it,
/// delete one, or create a new wardrobe.
class WardrobeListScreen extends ConsumerStatefulWidget {
  const WardrobeListScreen({super.key});

  @override
  ConsumerState<WardrobeListScreen> createState() => _WardrobeListScreenState();
}

class _WardrobeListScreenState extends ConsumerState<WardrobeListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wardrobeListViewModelProvider.notifier).load();
    });
  }

  /// Edit an existing wardrobe.
  Future<void> _openDesigner(WardrobeLayoutEntity wardrobe) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => WardrobeDesignerScreen(initial: wardrobe)),
    );
    if (saved == true && mounted) {
      ref.read(wardrobeListViewModelProvider.notifier).load();
    }
  }

  /// Create a new wardrobe — first choose "Make your own" or a preset.
  Future<void> _newWardrobe() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const WardrobePresetPickerScreen()),
    );
    if (saved == true && mounted) {
      ref.read(wardrobeListViewModelProvider.notifier).load();
    }
  }

  Future<void> _confirmDelete(WardrobeLayoutEntity wardrobe) async {
    final palette = context.palette;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: palette.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lg),
        title: Text('Delete “${wardrobe.name}”?',
            style: AppTypography.headingSmall.copyWith(color: palette.textPrimary)),
        content: Text('This wardrobe and its layout will be removed.',
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
    if (ok != true || wardrobe.id == null) return;
    HapticFeedback.mediumImpact();
    final success = await ref.read(wardrobeListViewModelProvider.notifier).delete(wardrobe.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Wardrobe deleted' : 'Could not delete — try again')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final state = ref.watch(wardrobeListViewModelProvider);

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
        title: Text('My Wardrobes',
            style: AppTypography.headingMedium.copyWith(color: palette.textPrimary)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: palette.accent,
        foregroundColor: AppColors.white,
        onPressed: _newWardrobe,
        icon: const Icon(Icons.add),
        label: Text('New wardrobe',
            style: AppTypography.labelLarge.copyWith(color: AppColors.white)),
      ),
      body: SafeArea(
        top: false,
        child: _body(context, state),
      ),
    );
  }

  Widget _body(BuildContext context, WardrobeListState state) {
    final palette = context.palette;

    switch (state.status) {
      case WardrobeListStatus.initial:
      case WardrobeListStatus.loading:
        return Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
            strokeWidth: 2.5,
          ),
        );
      case WardrobeListStatus.error:
        return _Centered(
          icon: Icons.cloud_off_outlined,
          title: "Couldn't load your wardrobes",
          subtitle: state.error,
          actionLabel: 'Retry',
          onAction: () => ref.read(wardrobeListViewModelProvider.notifier).load(),
        );
      case WardrobeListStatus.ready:
        if (state.wardrobes.isEmpty) {
          return _Centered(
            icon: Icons.checkroom_outlined,
            title: 'No wardrobes yet',
            subtitle: 'Create your first wardrobe to start arranging it.',
            actionLabel: 'New wardrobe',
            onAction: _newWardrobe,
          );
        }
        return GridView.count(
          crossAxisCount: 2,
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.space5, AppSpacing.space4, AppSpacing.space5, AppSpacing.space10),
          mainAxisSpacing: AppSpacing.space4,
          crossAxisSpacing: AppSpacing.space4,
          childAspectRatio: 0.82,
          children: [
            for (final w in state.wardrobes)
              _WardrobeCard(
                wardrobe: w,
                onTap: () => _openDesigner(w),
                onDelete: () => _confirmDelete(w),
              ),
          ],
        );
    }
  }
}

class _WardrobeCard extends StatelessWidget {
  final WardrobeLayoutEntity wardrobe;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _WardrobeCard({
    required this.wardrobe,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final pieces = wardrobe.moduleCount;

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
                  Container(
                    color: palette.surfaceAlt,
                    padding: const EdgeInsets.all(AppSpacing.space3),
                    child: WardrobeThumbnail(layout: wardrobe),
                  ),
                  // Delete affordance overlaid on the preview.
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
                  Text(
                    wardrobe.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelLarge.copyWith(color: palette.textPrimary),
                  ),
                  Text(
                    '${wardrobe.finish} · ${wardrobe.cols}×${wardrobe.rows} · '
                    '$pieces ${pieces == 1 ? 'piece' : 'pieces'}',
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

class _Centered extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const _Centered({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSpacing.iconXl, color: palette.textTertiary),
            const SizedBox(height: AppSpacing.space4),
            Text(title,
                textAlign: TextAlign.center,
                style: AppTypography.headingSmall.copyWith(color: palette.textPrimary)),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.space2),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(color: palette.textSecondary)),
            ],
            const SizedBox(height: AppSpacing.space5),
            AppButton(text: actionLabel, onPressed: onAction),
          ],
        ),
      ),
    );
  }
}
