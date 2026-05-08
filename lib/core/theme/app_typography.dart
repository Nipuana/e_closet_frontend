import 'package:flutter/material.dart';

class AppTypography {
  // ─────────────────────────────────────────────
  // Font Families
  // ─────────────────────────────────────────────
  // Bundled as local .ttf assets (see pubspec.yaml) so the elegant serif
  // display and clean sans body render fully offline — no network fetch.
  static const String fontDisplay = 'Cormorant Garamond';
  static const String fontBody = 'DM Sans';

  // ─────────────────────────────────────────────
  // Font Sizes (px)
  // ─────────────────────────────────────────────
  static const double sizeXs = 11.0;   // Extra small
  static const double sizeSm = 13.0;   // Small
  static const double sizeBase = 15.0; // Base/Default
  static const double sizeMd = 17.0;   // Medium
  static const double sizeLg = 20.0;   // Large (H3, subheadings)
  static const double sizeXl = 26.0;   // Extra Large (H2)
  static const double size2xl = 34.0;  // 2XL (H2 display)
  static const double size3xl = 44.0;  // 3XL (H1)
  static const double size4xl = 58.0;  // 4XL (Hero text)

  // ─────────────────────────────────────────────
  // Font Weights
  // ─────────────────────────────────────────────
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;

  // ─────────────────────────────────────────────
  // Line Heights
  // ─────────────────────────────────────────────
  static const double lineHeightTight = 1.1;
  static const double lineHeightSnug = 1.3;
  static const double lineHeightBase = 1.5;
  static const double lineHeightLoose = 1.75;

  // ─────────────────────────────────────────────
  // Predefined Text Styles - Display & Heading
  // ─────────────────────────────────────────────
  static final TextStyle displayXl = TextStyle(
    fontFamily: fontDisplay,
    fontSize: size4xl,
    fontWeight: light,
    height: lineHeightTight,
    letterSpacing: -0.02,
  );

  static final TextStyle displayLg = TextStyle(
    fontFamily: fontDisplay,
    fontSize: size3xl,
    fontWeight: light,
    height: lineHeightTight,
    letterSpacing: -0.01,
  );

  static final TextStyle headingXlarge = TextStyle(
    fontFamily: fontDisplay,
    fontSize: size2xl,
    fontWeight: light,
    height: lineHeightSnug,
  );

  static final TextStyle headingLarge = TextStyle(
    fontFamily: fontDisplay,
    fontSize: sizeXl,
    fontWeight: light,
    height: lineHeightSnug,
  );

  static final TextStyle headingMedium = TextStyle(
    fontFamily: fontBody,
    fontSize: sizeLg,
    fontWeight: medium,
    height: lineHeightSnug,
  );

  static final TextStyle headingSmall = TextStyle(
    fontFamily: fontBody,
    fontSize: sizeMd,
    fontWeight: medium,
    height: lineHeightBase,
  );

  // ─────────────────────────────────────────────
  // Predefined Text Styles - Body
  // ─────────────────────────────────────────────
  static final TextStyle bodyLarge = TextStyle(
    fontFamily: fontBody,
    fontSize: sizeBase,
    fontWeight: regular,
    height: lineHeightBase,
  );

  static final TextStyle bodyMedium = TextStyle(
    fontFamily: fontBody,
    fontSize: sizeSm,
    fontWeight: regular,
    height: lineHeightBase,
  );

  static final TextStyle bodySmall = TextStyle(
    fontFamily: fontBody,
    fontSize: sizeXs,
    fontWeight: regular,
    height: lineHeightBase,
  );

  // ─────────────────────────────────────────────
  // Predefined Text Styles - Labels & Captions
  // ─────────────────────────────────────────────
  static final TextStyle labelLarge = TextStyle(
    fontFamily: fontBody,
    fontSize: sizeMd,
    fontWeight: medium,
    height: lineHeightBase,
  );

  static final TextStyle labelMedium = TextStyle(
    fontFamily: fontBody,
    fontSize: sizeBase,
    fontWeight: medium,
    height: lineHeightBase,
  );

  static final TextStyle labelSmall = TextStyle(
    fontFamily: fontBody,
    fontSize: sizeSm,
    fontWeight: medium,
    height: lineHeightBase,
    letterSpacing: 0.08,
  );

  static final TextStyle captionSmall = TextStyle(
    fontFamily: fontBody,
    fontSize: sizeXs,
    fontWeight: regular,
    height: lineHeightBase,
    letterSpacing: 0.05,
  );

  static final TextStyle caption = TextStyle(
    fontFamily: fontBody,
    fontSize: sizeSm,
    fontWeight: regular,
    height: lineHeightBase,
  );

  // ─────────────────────────────────────────────
  // Predefined Text Styles - Legacy Aliases
  // ─────────────────────────────────────────────
  static final TextStyle displayMedium = displayLg;
  static final TextStyle bodySm = bodySmall;
  static final TextStyle bodyMd = bodyMedium;
  static final TextStyle bodyLg = bodyLarge;
}
