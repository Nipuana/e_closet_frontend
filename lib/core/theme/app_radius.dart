import 'package:flutter/widgets.dart';

class AppRadius {
  // ─────────────────────────────────────────────
  // Border Radius Constants
  // ─────────────────────────────────────────────
  static const double radiusSm = 2.0;   // Small (hairline detailing)
  static const double radiusMd = 12.0;  // Medium (inputs, chips)
  static const double radiusLg = 24.0;  // Large (cards, modals, tiles)
  static const double radiusXl = 24.0;  // Extra large (featured)
  static const double radiusPill = 48.0; // Pill (buttons, floating nav)
  static const double radiusFull = 9999.0; // Circular (avatars, dots)

  // ─────────────────────────────────────────────
  // BorderRadius Objects
  // ─────────────────────────────────────────────
  static const BorderRadius sm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius md = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(radiusPill));
  static const BorderRadius full = BorderRadius.all(Radius.circular(radiusFull));

  // ─────────────────────────────────────────────
  // Only Specific Corners
  // ─────────────────────────────────────────────
  static const BorderRadius topOnly = BorderRadius.only(
    topLeft: Radius.circular(radiusLg),
    topRight: Radius.circular(radiusLg),
  );

  static const BorderRadius bottomOnly = BorderRadius.only(
    bottomLeft: Radius.circular(radiusLg),
    bottomRight: Radius.circular(radiusLg),
  );
}
