import 'package:flutter/material.dart';

class AeroNimbusTheme {
  // ---- Core palette matching the cosmic theme from images ----
  static const background = Color(0xFF0B0B10); // Dark cosmic background
  static const foreground = Color(0xFFFFFFFF); // --foreground
  static const card = Color(0x1AFFFFFF);       // Semi-transparent cards
  static const popover = Color(0xFF2A1F3D);    // --popover
  static const primary = Color(0xFF4B0082);    // --primary (Deep Cosmic Purple)
  static const secondary = Color(0xFF10B981);  // --secondary (Emerald/Teal)
  static const accent = Color(0xFFFACC15);     // --accent (Golden Yellow)
  static const destructive = Color(0xFFDC2626); // --destructive (Crimson)
  static const border = Color(0x33FFFFFF);     // rgba(255,255,255,0.2)
  static const inputBg = Color(0x0DFFFFFF);    // --input-background
  static const switchTrack = Color(0x3310B981); // --switch-background
  static const ring = Color(0xFF06B6D4);       // Icy Cyan
  
  // Additional cosmic colors
  static const cosmicPurple = Color(0xFF7C3AED); // Purple gradient
  static const cosmicIndigo = Color(0xFF1E1B4B); // Dark indigo
  static const cosmicGold = Color(0xFFFACC15);   // Golden accent
  static const cosmicTeal = Color(0xFF06B6D4);   // Teal accent

  // Charts
  static const chart1 = Color(0xFFFACC15);
  static const chart2 = Color(0xFF10B981);
  static const chart3 = Color(0xFF06B6D4);
  static const chart4 = Color(0xFF4B0082);
  static const chart5 = Color(0xFFDC2626);

  // Radii
  static const radius = 14.0; // --radius: 0.875rem ≈ 14px
  static const radiusSm = radius - 4;
  static const radiusMd = radius - 2;
  static const radiusLg = radius;
  static const radiusXl = radius + 4;

  static ThemeData dark() {
    final base = ThemeData.dark();

    return base.copyWith(
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: foreground,
        secondary: secondary,
        onSecondary: foreground,
        surface: background,
        onSurface: foreground,
        error: destructive,
        onError: foreground,
        // use tertiary for accent
        tertiary: accent,
        onTertiary: Color(0xFF1A1625),
      ),

      // Borders / dividers
      dividerColor: border,

      // Cards & sheets mirror --card / --popover
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: popover,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: border),
        ),
      ),

      popupMenuTheme: const PopupMenuThemeData(
        color: popover,
      ),

      // Inputs (text fields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: const TextStyle(color: Color(0x66FFFFFF)), // ~0.4 opacity
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: border),
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: ring, width: 1.2),
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: border),
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: foreground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          side: const BorderSide(color: Color(0x33FFFFFF)), // ~0.2 opacity
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),

      // Switches & sliders
      switchTheme: const SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(secondary),
        trackColor: WidgetStatePropertyAll(switchTrack),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: secondary,
        inactiveTrackColor: Color(0x33FFFFFF),
        thumbColor: secondary,
        overlayColor: Color(0x3310B981),
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0x1A000000),
        elevation: 0,
        foregroundColor: foreground,
      ),

      // Chips / badges helper via ChipTheme
      chipTheme: ChipThemeData(
        backgroundColor: inputBg,
        selectedColor: Color(0x3310B981), // secondary /20
        labelStyle: const TextStyle(color: foreground),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          side: const BorderSide(color: border),
        ),
      ),

      // Typography approximating CSS base
      textTheme: base.textTheme
          .apply(
            bodyColor: foreground,
            displayColor: foreground,
          )
          .copyWith(
            headlineLarge: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
            headlineMedium: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            titleLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            bodyLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
            labelLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
    );
  }
}
