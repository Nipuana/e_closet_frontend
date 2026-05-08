import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // ─────────────────────────────────────────────
  // Design System — Quiet Luxury Wardrobe palette
  // Warm neutrals, a single camel accent + terracotta/navy highlights.
  // These are the canonical brand tokens; everything below maps onto them.
  // ─────────────────────────────────────────────
  static const Color camel = Color(0xFFBFA179);      // primary · accent
  static const Color terracotta = Color(0xFF915A3C); // accent · highlight
  static const Color navy = Color(0xFF2E3640);       // accent · cool
  static const Color black = Color(0xFF111111);      // buttons · ink
  static const Color slate = Color(0xFF3A3A38);      // secondary text
  static const Color cream = Color(0xFFFBF9F6);      // surface · bg
  static const Color linen = Color(0xFFECE6DC);      // tonal fill
  static const Color mist = Color(0xFFE4E1DB);       // borders · dividers
  static const Color sand = Color(0xFFD8CDBA);       // muted · inactive

  // ─────────────────────────────────────────────
  // Brand Colors - Primary Palette
  // ─────────────────────────────────────────────
  static const Color bone = cream;                   // bg alias → cream
  static const Color white = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF1A1A18);         // on-surface · text
  static const Color charcoal = slate;               // → slate

  // ─────────────────────────────────────────────
  // Neutral Colors - Stone Scale (mapped onto the warm-neutral palette)
  // ─────────────────────────────────────────────
  static const Color stone50 = cream;                // #FBF9F6
  static const Color stone100 = linen;               // #ECE6DC tonal fill
  static const Color stone200 = mist;                // #E4E1DB borders
  static const Color stone300 = sand;                // #D8CDBA muted/inactive
  static const Color stone400 = Color(0xFF9C938A);   // warm grey (placeholder)
  static const Color stone500 = Color(0xFF6B635B);   // muted text
  static const Color stone600 = slate;               // #3A3A38
  static const Color stone700 = Color(0xFF2A2A28);
  static const Color stone800 = Color(0xFF1A1A18);   // ink
  static const Color stone900 = black;               // #111111

  // ─────────────────────────────────────────────
  // Accent Colors - Camel (legacy "taupe" names map to the camel accent)
  // ─────────────────────────────────────────────
  static const Color taupe = camel;                  // #BFA179
  static const Color taupeLight = Color(0xFFD8C3A8);
  static const Color taupeDark = terracotta;         // #915A3C

  // ─────────────────────────────────────────────
  // Semantic Colors - Success (Green)
  // ─────────────────────────────────────────────
  static const Color success = Color(0xFF5C7A6B);
  static const Color successBg = Color(0xFFEAF2EE);
  static const Color successDark = Color(0xFF3D5046);
  static const Color successLight = Color(0xFFF0F5F3);

  // ─────────────────────────────────────────────
  // Semantic Colors - Warning (Yellow/Gold)
  // ─────────────────────────────────────────────
  static const Color warning = Color(0xFFB8974A);
  static const Color warningBg = Color(0xFFFBF4E3);
  static const Color warningDark = Color(0xFF7A6630);
  static const Color warningLight = Color(0xFFFDF9F0);

  // ─────────────────────────────────────────────
  // Semantic Colors - Danger (Red)
  // ─────────────────────────────────────────────
  static const Color danger = Color(0xFFB25C5C);
  static const Color dangerBg = Color(0xFFF9EAEA);
  static const Color dangerDark = Color(0xFF7A3D3D);
  static const Color dangerLight = Color(0xFFFCF3F3);

  // ─────────────────────────────────────────────
  // Semantic Colors - Info (Blue)
  // ─────────────────────────────────────────────
  static const Color info = Color(0xFF4A6B8A);
  static const Color infoBg = Color(0xFFE8EFF6);
  static const Color infoDark = Color(0xFF2D4563);
  static const Color infoLight = Color(0xFFF2F6FB);

  // ─────────────────────────────────────────────
  // Semantic Aliases - Light Mode
  // ─────────────────────────────────────────────
  static const Color background = bone;
  static const Color foreground = stone800;
  static const Color card = white;
  static const Color cardForeground = stone800;
  static const Color popover = white;
  static const Color popoverForeground = stone800;
  static const Color primary = stone800;
  static const Color primaryForeground = white;
  static const Color secondary = linen;
  static const Color secondaryForeground = stone800;
  static const Color muted = linen;
  static const Color mutedForeground = stone500;
  static const Color accent = taupe;
  static const Color accentForeground = white;
  static const Color destructive = danger;
  static const Color destructiveForeground = white;
  static const Color border = stone200;
  static const Color input = stone200;
  static const Color inputBackground = white;
  static const Color switchBackground = stone300;
  static const Color ring = taupe;

  // ─────────────────────────────────────────────
  // Semantic Aliases - Dark Mode
  // ─────────────────────────────────────────────
  static const Color darkBackground = ink;
  static const Color darkForeground = Color(0xFFF0EDE8);
  static const Color darkCard = charcoal;
  static const Color darkCardForeground = Color(0xFFF0EDE8);
  static const Color darkPopover = charcoal;
  static const Color darkPopoverForeground = Color(0xFFF0EDE8);
  static const Color darkPrimary = Color(0xFFF0EDE8);
  static const Color darkPrimaryForeground = stone800;
  static const Color darkSecondary = Color(0xFF353533);
  static const Color darkSecondaryForeground = Color(0xFFF0EDE8);
  static const Color darkMuted = Color(0xFF404040);
  static const Color darkMutedForeground = stone400;
  static const Color darkAccent = taupe;
  static const Color darkAccentForeground = white;
  static const Color darkDestructive = danger;
  static const Color darkDestructiveForeground = white;
  static const Color darkBorder = Color(0xFF3A3A38);
  static const Color darkInput = Color(0xFF3A3A38);
  static const Color darkInputBackground = charcoal;
  static const Color darkSwitchBackground = stone600;
  static const Color darkRing = taupe;

  // ─────────────────────────────────────────────
  // Opacity & Transparency Variants
  // ─────────────────────────────────────────────
  static const Color white90 = Color.fromRGBO(255, 255, 255, 0.9);
  static const Color white80 = Color.fromRGBO(255, 255, 255, 0.8);
  static const Color white50 = Color.fromRGBO(255, 255, 255, 0.5);
  static const Color white30 = Color.fromRGBO(255, 255, 255, 0.3);
  static const Color white20 = Color.fromRGBO(255, 255, 255, 0.2);
  static const Color white10 = Color.fromRGBO(255, 255, 255, 0.1);

  static const Color black20 = Color.fromRGBO(0, 0, 0, 0.2);
  static const Color black10 = Color.fromRGBO(0, 0, 0, 0.1);
  static const Color black05 = Color.fromRGBO(0, 0, 0, 0.05);

  static const Color taupe50 = Color.fromRGBO(191, 161, 121, 0.5);
  static const Color taupe30 = Color.fromRGBO(191, 161, 121, 0.3);
  static const Color taupe12 = Color.fromRGBO(191, 161, 121, 0.12);

  // ─────────────────────────────────────────────
  // Gradients
  // ─────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [taupe, taupeDark],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [taupe, taupeLight],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bone, white],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, successDark],
  );

  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warning, warningDark],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [danger, dangerDark],
  );

  static const LinearGradient infoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [info, infoDark],
  );

  // ─────────────────────────────────────────────
  // Transparency
  // ─────────────────────────────────────────────
  static const Color transparent = Colors.transparent;

  // ─────────────────────────────────────────────
  // Overlay Colors
  // ─────────────────────────────────────────────
  static const Color overlay30 = Color.fromRGBO(0, 0, 0, 0.3);
  static const Color overlay50 = Color.fromRGBO(0, 0, 0, 0.5);
  static const Color overlay70 = Color.fromRGBO(0, 0, 0, 0.7);

  // ─────────────────────────────────────────────
  // Shadow Color Base
  // ─────────────────────────────────────────────
  static const Color shadowDefault = Color.fromRGBO(26, 26, 24, 0.08);
  static const Color shadowDark = Color.fromRGBO(0, 0, 0, 0.15);
  
  // ─────────────────────────────────────────────
  // Text Variants (for quick access)
  // ─────────────────────────────────────────────
  static const Color textPrimary = stone800;
  static const Color textSecondary = stone500;
  static const Color textTertiary = stone400;
  static const Color textDisabled = stone300;
  static const Color textInverse = white;
  static const Color textMuted = stone300;
  
  // ─────────────────────────────────────────────
  // Legacy aliases for backward compatibility
  // ─────────────────────────────────────────────
  static const Color bgPrimary = white;
  static const Color bgSecondary = stone50;
  static const Color bgTertiary = stone100;
  static const Color errorDefault = danger;
  static const Color errorLight = dangerLight;
  static const Color errorDark = dangerDark;
  static const Color successDefault = success;
  static const Color warningDefault = warning;
  static const Color infoDefault = info;
  
  // Button/Component state aliases
  static const Color primaryDefault = taupe;
  static const Color primaryDisabled = stone300;
  static const Color primaryHover = taupeDark;
  static const Color primaryActive = taupeDark;
  
  static const Color secondaryDefault = stone200;
  static const Color secondaryDisabled = stone100;
  static const Color secondaryHover = stone300;
  static const Color secondaryActive = stone400;
  
  static const Color destructiveDefault = danger;
  static const Color destructiveDisabled = Color.fromRGBO(178, 92, 92, 0.5);
  static const Color destructiveHover = dangerDark;
  static const Color destructiveActive = dangerDark;
  
  // Border/Focus states
  static const Color borderDefault = stone200;
  static const Color borderFocused = taupe;
  static const Color borderError = danger;
  static const Color borderSuccess = success;
}
