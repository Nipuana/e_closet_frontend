import 'package:flutter/material.dart';

/// Paints a recognizable closet compartment for a module — a hanging rail with
/// garments, a stack of drawers, or shelves of folded clothes. The amount of
/// detail scales with the tile size, so a block spanning more tiles shows more
/// hangers / drawers / shelves.
class ClosetModulePainter extends CustomPainter {
  final String moduleId;
  final Color color; // contrasting "ink on the finish" colour

  const ClosetModulePainter({required this.moduleId, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final pad = (size.shortestSide * 0.08).clamp(2.0, 8.0);
    final r = Rect.fromLTWH(pad, pad, size.width - pad * 2, size.height - pad * 2);
    if (r.width <= 4 || r.height <= 4) return;

    // The recessed cabinet interior (reads as a closet "door"/frame).
    final frame = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color.withValues(alpha: 0.22);
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(3)),
      frame,
    );

    switch (moduleId) {
      case 'hang':
        _hang(canvas, r);
        break;
      case 'drawers':
        _drawers(canvas, r);
        break;
      case 'folded':
        _folded(canvas, r);
        break;
    }
  }

  void _hang(Canvas canvas, Rect r) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.85);
    final garment = Paint()..color = color.withValues(alpha: 0.26);
    final garmentStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color.withValues(alpha: 0.5);

    final rodY = r.top + r.height * 0.14;
    canvas.drawLine(Offset(r.left + 2, rodY), Offset(r.right - 2, rodY), line);

    final count = (r.width / 20).floor().clamp(1, 14);
    final spacing = r.width / count;
    final hw = spacing * 0.32; // half shoulder width
    final shoulderY = rodY + r.height * 0.12;
    final bottom = r.bottom - r.height * 0.05;

    for (int i = 0; i < count; i++) {
      final cx = r.left + spacing * (i + 0.5);
      final apex = Offset(cx, rodY - 2);
      final sl = Offset(cx - hw, shoulderY);
      final sr = Offset(cx + hw, shoulderY);
      // Hanger
      canvas.drawLine(apex, sl, line);
      canvas.drawLine(apex, sr, line);
      // Garment hanging below
      final path = Path()
        ..moveTo(sl.dx, sl.dy)
        ..lineTo(cx - hw * 1.55, bottom)
        ..lineTo(cx + hw * 1.55, bottom)
        ..lineTo(sr.dx, sr.dy)
        ..close();
      canvas.drawPath(path, garment);
      canvas.drawPath(path, garmentStroke);
    }
  }

  void _drawers(Canvas canvas, Rect r) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = color.withValues(alpha: 0.6);
    final fill = Paint()..color = color.withValues(alpha: 0.12);
    final handle = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.7);

    final count = (r.height / 22).floor().clamp(1, 8);
    const gap = 3.0;
    final dh = (r.height - gap * (count - 1)) / count;

    for (int i = 0; i < count; i++) {
      final top = r.top + i * (dh + gap);
      final dr = Rect.fromLTWH(r.left, top, r.width, dh);
      final rr = RRect.fromRectAndRadius(dr, const Radius.circular(2.5));
      canvas.drawRRect(rr, fill);
      canvas.drawRRect(rr, stroke);
      // Handle
      final hy = top + dh / 2;
      final hwidth = (r.width * 0.2).clamp(4.0, 28.0);
      canvas.drawLine(
        Offset(r.center.dx - hwidth, hy),
        Offset(r.center.dx + hwidth, hy),
        handle,
      );
    }
  }

  void _folded(Canvas canvas, Rect r) {
    final shelf = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = color.withValues(alpha: 0.6);
    final fold = Paint()..color = color.withValues(alpha: 0.22);
    final foldStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = color.withValues(alpha: 0.5);

    final rows = (r.height / 22).floor().clamp(1, 8);
    final rh = r.height / rows;
    final stacks = (r.width / 26).floor().clamp(1, 6);
    final sw = r.width / stacks;

    for (int i = 0; i < rows; i++) {
      final shelfY = r.top + (i + 1) * rh;
      canvas.drawLine(Offset(r.left, shelfY), Offset(r.right, shelfY), shelf);
      // Folded stacks resting on the shelf
      for (int j = 0; j < stacks; j++) {
        final cx = r.left + sw * (j + 0.5);
        for (int k = 0; k < 2; k++) {
          final h = (rh * 0.24).clamp(2.0, 8.0);
          final w = sw * 0.6;
          final top = shelfY - (k + 1) * (h + 1.5) - 1;
          if (top < r.top) break;
          final rect = Rect.fromCenter(center: Offset(cx, top + h / 2), width: w, height: h);
          final rr = RRect.fromRectAndRadius(rect, const Radius.circular(1.5));
          canvas.drawRRect(rr, fold);
          canvas.drawRRect(rr, foldStroke);
        }
      }
    }
  }

  @override
  bool shouldRepaint(ClosetModulePainter old) =>
      old.moduleId != moduleId || old.color != color;
}
