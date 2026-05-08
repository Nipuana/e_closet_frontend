import 'package:flutter/widgets.dart';

class AppSpacing {
  // ─────────────────────────────────────────────
  // Design System — Spacing Scale
  // Editorial rhythm: xs·14 · sm·22 · md·24 · lg·26 · xl·40
  // These named tokens are the canonical scale; all padding / gap / margin
  // helpers below are derived from them so the system stays consistent.
  // ─────────────────────────────────────────────
  static const double xs = 14.0;
  static const double sm = 22.0;
  static const double md = 24.0;
  static const double lg = 26.0;
  static const double xl = 40.0;
  static const double xxl = 56.0;  // extension beyond the core scale
  static const double xxxl = 64.0; // extension beyond the core scale

  // ─────────────────────────────────────────────
  // Primitive 8px-ish grid (kept for fine-grained, non-semantic spacing)
  // ─────────────────────────────────────────────
  static const double space1 = 4.0;
  static const double space2 = 8.0;
  static const double space3 = 12.0;
  static const double space4 = 16.0;
  static const double space5 = 20.0;
  static const double space6 = 24.0;
  static const double space8 = 32.0;
  static const double space10 = 40.0;
  static const double space12 = 48.0;
  static const double space16 = 64.0;
  static const double space20 = 80.0;
  static const double space24 = 96.0;

  // ─────────────────────────────────────────────
  // Icon Sizes
  // ─────────────────────────────────────────────
  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  // ─────────────────────────────────────────────
  // Button Heights
  // ─────────────────────────────────────────────
  static const double buttonHeightSm = 32.0;
  static const double buttonHeightMd = 44.0;
  static const double buttonHeightLg = 52.0;

  // ─────────────────────────────────────────────
  // Input Heights
  // ─────────────────────────────────────────────
  static const double inputHeightSm = 36.0;
  static const double inputHeightMd = 44.0;
  static const double inputHeightLg = 52.0;

  // ─────────────────────────────────────────────
  // Border Radius Sizes — Design System (sm·2 · md·12 · lg·24 · pill·48)
  // ─────────────────────────────────────────────
  static const double radiusSm = 2.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 24.0;
  static const double radiusXl = 24.0;
  static const double radiusPill = 48.0;
  static const double radiusFull = 9999.0;
  static const double radiusCircle = 9999.0;

  // ─────────────────────────────────────────────
  // NUMERIC Padding Values (for symmetric/directional padding)
  // ─────────────────────────────────────────────
  static const double paddingXsValue = xs;
  static const double paddingSmValue = sm;
  static const double paddingMdValue = md;
  static const double paddingLgValue = lg;
  static const double paddingXlValue = xl;
  static const double paddingXxlValue = xxl;

  // ─────────────────────────────────────────────
  // Padding (All Sides)
  // ─────────────────────────────────────────────
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);
  static const EdgeInsets paddingXxl = EdgeInsets.all(xxl);

  // ─────────────────────────────────────────────
  // Padding (Horizontal)
  // ─────────────────────────────────────────────
  static const EdgeInsets paddingHorizontalXs = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets paddingHorizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets paddingHorizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHorizontalLg = EdgeInsets.symmetric(horizontal: lg);

  // ─────────────────────────────────────────────
  // Padding (Vertical)
  // ─────────────────────────────────────────────
  static const EdgeInsets paddingVerticalXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets paddingVerticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets paddingVerticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets paddingVerticalLg = EdgeInsets.symmetric(vertical: lg);

  // ─────────────────────────────────────────────
  // Margin (All Sides)
  // ─────────────────────────────────────────────
  static const EdgeInsets marginXs = EdgeInsets.all(xs);
  static const EdgeInsets marginSm = EdgeInsets.all(sm);
  static const EdgeInsets marginMd = EdgeInsets.all(md);
  static const EdgeInsets marginLg = EdgeInsets.all(lg);
  static const EdgeInsets marginXl = EdgeInsets.all(xl);

  // ─────────────────────────────────────────────
  // Margin (Only Top)
  // ─────────────────────────────────────────────
  static const EdgeInsets marginTopXs = EdgeInsets.only(top: xs);
  static const EdgeInsets marginTopSm = EdgeInsets.only(top: sm);
  static const EdgeInsets marginTopMd = EdgeInsets.only(top: md);
  static const EdgeInsets marginTopLg = EdgeInsets.only(top: lg);
  static const EdgeInsets marginTopXl = EdgeInsets.only(top: xl);

  // ─────────────────────────────────────────────
  // Margin (Only Bottom)
  // ─────────────────────────────────────────────
  static const EdgeInsets marginBottomXs = EdgeInsets.only(bottom: xs);
  static const EdgeInsets marginBottomSm = EdgeInsets.only(bottom: sm);
  static const EdgeInsets marginBottomMd = EdgeInsets.only(bottom: md);
  static const EdgeInsets marginBottomLg = EdgeInsets.only(bottom: lg);
  static const EdgeInsets marginBottomXl = EdgeInsets.only(bottom: xl);

  // ─────────────────────────────────────────────
  // Gaps (SizedBox - Vertical)
  // ─────────────────────────────────────────────
  static const SizedBox gapXs = SizedBox(height: xs);
  static const SizedBox gapSm = SizedBox(height: sm);
  static const SizedBox gapMd = SizedBox(height: md);
  static const SizedBox gapLg = SizedBox(height: lg);
  static const SizedBox gapXl = SizedBox(height: xl);
  static const SizedBox gapXxl = SizedBox(height: xxl);

  // ─────────────────────────────────────────────
  // Gaps (SizedBox - Horizontal)
  // ─────────────────────────────────────────────
  static const SizedBox gapHorizontalXs = SizedBox(width: xs);
  static const SizedBox gapHorizontalSm = SizedBox(width: sm);
  static const SizedBox gapHorizontalMd = SizedBox(width: md);
  static const SizedBox gapHorizontalLg = SizedBox(width: lg);
  static const SizedBox gapHorizontalXl = SizedBox(width: xl);
}
