import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/wardrobe_layout_entity.dart';
import '../closet_presets.dart';
import '../view_model/wardrobe_list_view_model.dart';
import 'closet_view_screen.dart';
import 'wardrobe_preset_picker_screen.dart';

/// The "Closet" tab — the user's built wardrobe(s). Tapping one opens the
/// closet so pieces can be placed into its compartments.
class ClosetTabScreen extends ConsumerStatefulWidget {
  const ClosetTabScreen({super.key});

  @override
  ConsumerState<ClosetTabScreen> createState() => _ClosetTabScreenState();
}

class _ClosetTabScreenState extends ConsumerState<ClosetTabScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wardrobeListViewModelProvider.notifier).load();
    });
  }

  Future<void> _create() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const WardrobePresetPickerScreen()),
    );
    if (saved == true && mounted) {
      ref.read(wardrobeListViewModelProvider.notifier).load();
    }
  }

  Future<void> _open(WardrobeLayoutEntity layout) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ClosetViewScreen(layout: layout)),
    );
    if (mounted) ref.read(wardrobeListViewModelProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final state = ref.watch(wardrobeListViewModelProvider);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        Text('YOUR CLOSET',
                            style: AppTypography.labelSmall.copyWith(
                                color: palette.textTertiary, letterSpacing: 1.6)),
                        const SizedBox(height: AppSpacing.space1),
                        Text('Closet',
                            style: AppTypography.headingXlarge
                                .copyWith(color: palette.textPrimary)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _create,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: palette.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: palette.border),
                      ),
                      child: Icon(Icons.add, size: AppSpacing.iconSm, color: palette.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            Expanded(child: _body(context, state)),
          ],
        ),
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
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Couldn't load your closet",
                  style: AppTypography.bodyMedium.copyWith(color: palette.textSecondary)),
              const SizedBox(height: AppSpacing.space2),
              TextButton(
                onPressed: () => ref.read(wardrobeListViewModelProvider.notifier).load(),
                child: Text('Retry',
                    style: AppTypography.labelSmall.copyWith(color: palette.accentStrong)),
              ),
            ],
          ),
        );
      case WardrobeListStatus.ready:
        if (state.wardrobes.isEmpty) {
          return Center(
            child: Padding(
              padding: AppSpacing.paddingLg,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.door_sliding_outlined,
                      size: AppSpacing.iconXl, color: palette.textTertiary),
                  const SizedBox(height: AppSpacing.space4),
                  Text('No closet yet',
                      style: AppTypography.headingSmall.copyWith(color: palette.textPrimary)),
                  const SizedBox(height: AppSpacing.space2),
                  Text('Design a wardrobe, then place your pieces into it.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(color: palette.textSecondary)),
                  const SizedBox(height: AppSpacing.space5),
                  GestureDetector(
                    onTap: _create,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space6, vertical: AppSpacing.space3),
                      decoration: BoxDecoration(
                        color: palette.textPrimary,
                        borderRadius: AppRadius.pill,
                      ),
                      child: Text('Design a closet',
                          style: AppTypography.labelMedium.copyWith(color: palette.background)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return GridView.count(
          crossAxisCount: 2,
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.space6),
          mainAxisSpacing: AppSpacing.space4,
          crossAxisSpacing: AppSpacing.space4,
          childAspectRatio: 0.82,
          children: [
            for (final w in state.wardrobes)
              _ClosetCard(layout: w, onTap: () => _open(w)),
          ],
        );
    }
  }
}

class _ClosetCard extends StatelessWidget {
  final WardrobeLayoutEntity layout;
  final VoidCallback onTap;
  const _ClosetCard({required this.layout, required this.onTap});

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
              child: Container(
                color: palette.surfaceAlt,
                padding: const EdgeInsets.all(AppSpacing.space3),
                child: WardrobeThumbnail(layout: layout),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.space3, AppSpacing.space2, AppSpacing.space3, AppSpacing.space3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(layout.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelLarge.copyWith(color: palette.textPrimary)),
                  Text('${layout.finish} · ${layout.cols}×${layout.rows}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.captionSmall.copyWith(color: palette.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
