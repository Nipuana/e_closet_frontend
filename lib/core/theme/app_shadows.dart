import 'package:flutter/material.dart';

class AppShadows {
  // ─────────────────────────────────────────────
  // Light Mode Shadows
  // ─────────────────────────────────────────────
  // Shadow Small: 0 1px 3px rgba(26,26,24,0.06), 0 1px 2px rgba(26,26,24,0.04)
  static const BoxShadow shadowSm = BoxShadow(
    color: Color.fromRGBO(26, 26, 24, 0.06),
    offset: Offset(0, 1),
    blurRadius: 3,
    spreadRadius: 0,
  );

  // Shadow Medium: 0 4px 16px rgba(26,26,24,0.08), 0 2px 6px rgba(26,26,24,0.04)
  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color.fromRGBO(26, 26, 24, 0.08),
      offset: Offset(0, 4),
      blurRadius: 16,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color.fromRGBO(26, 26, 24, 0.04),
      offset: Offset(0, 2),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];

  // Shadow Large: 0 12px 40px rgba(26,26,24,0.12), 0 4px 12px rgba(26,26,24,0.06)
  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color.fromRGBO(26, 26, 24, 0.12),
      offset: Offset(0, 12),
      blurRadius: 40,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color.fromRGBO(26, 26, 24, 0.06),
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  // Shadow XL (Maximum elevation): 0 24px 64px rgba(26,26,24,0.16)
  static const BoxShadow shadowXl = BoxShadow(
    color: Color.fromRGBO(26, 26, 24, 0.16),
    offset: Offset(0, 24),
    blurRadius: 64,
    spreadRadius: 0,
  );

  // ─────────────────────────────────────────────
  // Dark Mode Shadows
  // ─────────────────────────────────────────────
  // Shadow Small: 0 1px 3px rgba(0,0,0,0.3)
  static const BoxShadow darkShadowSm = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.3),
    offset: Offset(0, 1),
    blurRadius: 3,
    spreadRadius: 0,
  );

  // Shadow Medium: 0 4px 16px rgba(0,0,0,0.4)
  static const BoxShadow darkShadowMd = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.4),
    offset: Offset(0, 4),
    blurRadius: 16,
    spreadRadius: 0,
  );

  // Shadow Large: 0 12px 40px rgba(0,0,0,0.5)
  static const BoxShadow darkShadowLg = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.5),
    offset: Offset(0, 12),
    blurRadius: 40,
    spreadRadius: 0,
  );

  // ─────────────────────────────────────────────
  // Component-Specific Shadows
  // ─────────────────────────────────────────────
  // Card Elevation
  static const List<BoxShadow> cardShadow = shadowMd;

  // Button Elevation
  static const List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: Color.fromRGBO(191, 161, 121, 0.2),
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  // Modal/Popover Elevation
  static const List<BoxShadow> modalShadow = shadowLg;

  // ─────────────────────────────────────────────
  // Focus Ring Shadow (for focus states)
  // ─────────────────────────────────────────────
  static const List<BoxShadow> focusShadow = [
    BoxShadow(
      color: Color.fromRGBO(191, 161, 121, 0.12),
      offset: Offset(0, 0),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];
}
