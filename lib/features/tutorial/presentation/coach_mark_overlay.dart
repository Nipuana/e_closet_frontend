import 'package:flutter/material.dart';

import '../../../common/common.dart';
import '../../../core/theme/theme.dart';

/// A single stop in the coach-mark tour: a target widget (via [targetKey]) that
/// gets spotlighted, plus the copy shown in the accompanying tooltip card.
class CoachMarkStep {
  final GlobalKey targetKey;
  final String title;
  final String description;

  /// Spotlight shape — a circle suits round targets like the "+" button.
  final bool circle;

  const CoachMarkStep({
    required this.targetKey,
    required this.title,
    required this.description,
    this.circle = false,
  });
}

/// Presents [steps] as a full-screen guided tour: a dimmed scrim with a
/// cut-out around each target and a tooltip that advances on tap or "Next".
/// [onFinish] runs once the tour completes or is skipped.
void showCoachMarks(
  BuildContext context,
  List<CoachMarkStep> steps, {
  VoidCallback? onFinish,
}) {
  if (steps.isEmpty) {
    onFinish?.call();
    return;
  }

  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _CoachMarkView(
      steps: steps,
      onFinish: () {
        entry.remove();
        onFinish?.call();
      },
    ),
  );
  overlay.insert(entry);
}

class _CoachMarkView extends StatefulWidget {
  final List<CoachMarkStep> steps;
  final VoidCallback onFinish;

  const _CoachMarkView({required this.steps, required this.onFinish});

  @override
  State<_CoachMarkView> createState() => _CoachMarkViewState();
}

class _CoachMarkViewState extends State<_CoachMarkView> {
  int _index = 0;

  void _next() {
    if (_index < widget.steps.length - 1) {
      setState(() => _index++);
    } else {
      widget.onFinish();
    }
  }

  Rect? _rectFor(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final size = MediaQuery.of(context).size;
    final step = widget.steps[_index];
    final isLast = _index == widget.steps.length - 1;

    final target = _rectFor(step.targetKey);
    final hole = target?.inflate(AppSpacing.space2);
    // Place the card opposite the target so it never covers the highlight.
    final placeBelow = hole == null ? true : hole.center.dy < size.height / 2;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Scrim + spotlight. Tapping anywhere (including the highlight)
          // advances the tour rather than hitting the real UI beneath.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _next,
              child: CustomPaint(
                painter: _SpotlightPainter(
                  hole: hole,
                  circle: step.circle,
                  scrim: Colors.black.withValues(alpha: 0.72),
                  ring: palette.accentStrong,
                ),
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.space5,
            right: AppSpacing.space5,
            top: placeBelow
                ? (hole?.bottom ?? size.height * 0.4) + AppSpacing.space4
                : null,
            bottom: placeBelow
                // Only reached when hole is non-null (placeBelow defaults true otherwise).
                ? null
                : (size.height - hole.top) + AppSpacing.space4,
            child: _card(palette, step, isLast),
          ),
        ],
      ),
    );
  }

  Widget _card(AppPalette palette, CoachMarkStep step, bool isLast) {
    // Absorb taps so pressing the card body doesn't fall through to the scrim.
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space5),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: palette.border),
          boxShadow: AppShadows.shadowLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_index + 1} of ${widget.steps.length}',
              style: AppTypography.captionSmall
                  .copyWith(color: palette.textTertiary, letterSpacing: 1.4),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              step.title,
              style: AppTypography.headingSmall.copyWith(color: palette.textPrimary),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              step.description,
              style: AppTypography.bodyMedium.copyWith(color: palette.textSecondary),
            ),
            const SizedBox(height: AppSpacing.space4),
            Row(
              children: [
                if (!isLast)
                  TextButton(
                    onPressed: widget.onFinish,
                    child: Text(
                      'Skip',
                      style: AppTypography.labelMedium.copyWith(color: palette.textTertiary),
                    ),
                  ),
                const Spacer(),
                AppButton(
                  text: isLast ? 'Got it' : 'Next',
                  onPressed: _next,
                  size: ButtonSize.small,
                  trailingIcon: isLast ? Icons.check : Icons.arrow_forward,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect? hole;
  final bool circle;
  final Color scrim;
  final Color ring;

  _SpotlightPainter({
    required this.hole,
    required this.circle,
    required this.scrim,
    required this.ring,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final full = Path()..addRect(Offset.zero & size);

    if (hole == null) {
      canvas.drawPath(full, Paint()..color = scrim);
      return;
    }

    final holePath = circle
        ? (Path()..addOval(hole!))
        : (Path()..addRRect(RRect.fromRectAndRadius(hole!, const Radius.circular(16))));

    canvas.drawPath(
      Path.combine(PathOperation.difference, full, holePath),
      Paint()..color = scrim,
    );
    canvas.drawPath(
      holePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = ring,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.hole != hole || old.circle != circle || old.scrim != scrim || old.ring != ring;
}
