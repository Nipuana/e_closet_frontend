import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/wardrobe_layout_entity.dart';
import '../closet_presets.dart';
import 'wardrobe_designer_screen.dart';

/// Shown when the user taps "New wardrobe". Offers "Make your own" (a blank
/// wardrobe) first, then a grid of starter presets that show how they look.
class WardrobePresetPickerScreen extends StatelessWidget {
  const WardrobePresetPickerScreen({super.key});

  Future<void> _open(BuildContext context, WardrobeLayoutEntity? initial) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => WardrobeDesignerScreen(initial: initial)),
    );
    // Bubble the "saved" result up to the list so it reloads.
    if (saved == true && context.mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

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
        title: Text('Choose a wardrobe',
            style: AppTypography.headingMedium.copyWith(color: palette.textPrimary)),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: GridView.count(
          crossAxisCount: 2,
          padding: AppSpacing.paddingLg,
          mainAxisSpacing: AppSpacing.space4,
          crossAxisSpacing: AppSpacing.space4,
          childAspectRatio: 0.82,
          children: [
            _MakeYourOwnCard(onTap: () => _open(context, null)),
            for (final preset in kClosetPresets)
              _PresetCard(
                preset: preset,
                onTap: () {
                  HapticFeedback.selectionClick();
                  _open(context, preset.toEntity());
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  final Widget preview;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool dashed;

  const _CardShell({
    required this.preview,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.dashed = false,
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
          border: Border.all(
            color: dashed ? palette.accent : palette.border,
            width: dashed ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: palette.surfaceAlt,
                padding: const EdgeInsets.all(AppSpacing.space3),
                child: preview,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.space3, AppSpacing.space2, AppSpacing.space3, AppSpacing.space3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelLarge.copyWith(color: palette.textPrimary)),
                  if (subtitle != null)
                    Text(subtitle!,
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

class _MakeYourOwnCard extends StatelessWidget {
  final VoidCallback onTap;
  const _MakeYourOwnCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return _CardShell(
      onTap: onTap,
      dashed: true,
      title: 'Make your own',
      subtitle: 'Start from an empty grid',
      preview: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, size: AppSpacing.iconXl, color: palette.accent),
          ],
        ),
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  final ClosetPreset preset;
  final VoidCallback onTap;
  const _PresetCard({required this.preset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final entity = preset.toEntity();
    return _CardShell(
      onTap: onTap,
      title: preset.name,
      subtitle: '${preset.finish} · ${entity.cols}×${entity.rows}',
      preview: WardrobeThumbnail(layout: entity),
    );
  }
}
