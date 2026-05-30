import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../domain/entities/wardrobe_layout_entity.dart';
import 'closet_modules.dart';
import 'closet_tile_painter.dart';

/// A starter wardrobe layout the user can pick and then customise. Presets are
/// client-side templates only — they never appear in "My Wardrobes" until the
/// user saves one as their own.
class ClosetPreset {
  final String name;
  final String finish;
  final List<List<String>> zones; // grid of module ids

  ClosetPreset({required this.name, required this.finish, required this.zones});

  WardrobeLayoutEntity toEntity() => WardrobeLayoutEntity(
        // id stays null → saving creates a brand-new wardrobe for the user.
        name: name,
        finish: finish,
        cols: zones.isEmpty ? 0 : zones.first.length,
        rows: zones.length,
        grid: zones.map((row) => [...row]).toList(), // mutable copy
      );
}

const _h = 'hang';
const _f = 'folded';
const _d = 'drawers';

final List<ClosetPreset> kClosetPresets = [
  ClosetPreset(
    name: 'Reach-in',
    finish: 'Natural',
    zones: [
      [_h, _h, _h],
      [_h, _h, _h],
      [_d, _d, _d],
      [_f, _f, _f],
    ],
  ),
  ClosetPreset(
    name: 'Tall Hanging',
    finish: 'Walnut',
    zones: [
      [_h, _h],
      [_h, _h],
      [_h, _h],
      [_h, _h],
      [_d, _d],
    ],
  ),
  ClosetPreset(
    name: 'Dresser',
    finish: 'Sage',
    zones: [
      [_f, _f, _f, _f],
      [_d, _d, _d, _d],
      [_d, _d, _d, _d],
    ],
  ),
  ClosetPreset(
    name: 'Walk-in',
    finish: 'Ink',
    zones: [
      [_h, _h, _f, _h, _h],
      [_h, _h, _f, _h, _h],
      [_d, _d, _f, _d, _d],
      [_d, _d, _d, _d, _d],
    ],
  ),
  ClosetPreset(
    name: 'Capsule',
    finish: 'Bone',
    zones: [
      [_h, _h, _f],
      [_h, _h, _f],
      [_d, _d, _d],
    ],
  ),
];

/// A small, read-only render of a wardrobe layout — used as a preview thumbnail
/// in the preset grid and elsewhere.
class WardrobeThumbnail extends StatelessWidget {
  final WardrobeLayoutEntity layout;
  const WardrobeThumbnail({super.key, required this.layout});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final finishColor = kFinishColors[layout.finish] ?? AppColors.camel;
    final onFinish = finishColor.computeLuminance() > 0.55 ? AppColors.ink : Colors.white;
    final cols = layout.cols;
    final rows = layout.rows;
    if (cols == 0 || rows == 0) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 2.0;
        final cellW = (constraints.maxWidth - gap * (cols - 1)) / cols;
        final cellH = (constraints.maxHeight - gap * (rows - 1)) / rows;
        final tiles = <Widget>[];
        for (int r = 0; r < rows; r++) {
          for (int c = 0; c < cols; c++) {
            final info = layout.cellAt(r, c);
            if (info.covered) continue; // drawn by its anchor
            final left = c * (cellW + gap);
            final top = r * (cellH + gap);
            final w = cellW * info.colSpan + gap * (info.colSpan - 1);
            final h = cellH * info.rowSpan + gap * (info.rowSpan - 1);
            tiles.add(Positioned(
              left: left,
              top: top,
              width: w,
              height: h,
              child: Container(
                decoration: BoxDecoration(
                  color: info.isAnchor ? finishColor : palette.surface,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: info.isAnchor
                    ? CustomPaint(
                        painter: ClosetModulePainter(moduleId: info.moduleId, color: onFinish),
                        child: const SizedBox.expand(),
                      )
                    : null,
              ),
            ));
          }
        }
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Stack(children: tiles),
        );
      },
    );
  }
}
