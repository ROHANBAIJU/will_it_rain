import 'package:flutter/material.dart';

class AeroNimbusTheme {
  // ---- Core palette inspired by Google Weather redesign ----
  // Friendly purple-lavender theme with clean, approachable design
  
  static const background = Color(0xFFF5F3FF); // Very light lavender background
  static const backgroundDark = Color(0xFF6B5BA6); // Deep purple for hero sections
  static const foreground = Color(0xFF2D2D2D); // Dark charcoal for text
  static const foregroundLight = Color(0xFFFFFFFF); // White for dark backgrounds
  
  static const card = Color(0xFFFFFFFF);       // Clean white cards
  static const cardElevated = Color(0xFFF8F7FC); // Subtle purple tint for elevated cards
  static const popover = Color(0xFFFFFFFF);    // White popovers
  
  static const primary = Color(0xFF7C6BAD);    // Medium purple (main brand color)
  static const primaryDark = Color(0xFF5E4D8B); // Darker purple for hover/active
  static const primaryLight = Color(0xFFE8E4F3); // Very light purple for backgrounds
  
  static const secondary = Color(0xFF10B981);  // Emerald/Teal (keep for success states)
  static const accent = Color(0xFFFDB022);     // Warm yellow-orange
  static const accentOrange = Color(0xFFFF9F43); // Soft orange
  static const destructive = Color(0xFFEF4444); // Soft red
  
  static const border = Color(0xFFE5E5E5);     // Light gray borders
  static const borderPurple = Color(0xFFD4CDED); // Light purple borders
  static const inputBg = Color(0xFFF9F9F9);    // Very light gray inputs
  static const switchTrack = Color(0xFFE8E4F3); // Light purple switch
  static const ring = Color(0xFF7C6BAD);       // Medium purple focus ring
  
  // Additional friendly colors
  static const purpleGradientStart = Color(0xFF6B5BA6); // Deep indigo-purple
  static const purpleGradientEnd = Color(0xFF8B7AB8);   // Soft lavender-purple
  static const lavender = Color(0xFFE8E4F3);   // Very light lavender
  static const sunYellow = Color(0xFFFDB022);  // Warm sun color
  static const moonYellow = Color(0xFFFFE17B); // Soft moon glow

  // Charts - softer, friendlier palette
  static const chart1 = Color(0xFF7C6BAD); // Primary purple
  static const chart2 = Color(0xFFFDB022); // Warm yellow
  static const chart3 = Color(0xFF10B981); // Emerald
  static const chart4 = Color(0xFFFF9F43); // Soft orange
  static const chart5 = Color(0xFF60A5FA); // Sky blue

  // Radii - more rounded for friendly feel
  static const radius = 16.0; // Increased roundness
  static const radiusSm = 12.0;
  static const radiusMd = 14.0;
  static const radiusLg = 16.0;
  static const radiusXl = 20.0;

  static ThemeData light() {
    final base = ThemeData.light();

    return base.copyWith(
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: foregroundLight,
        secondary: secondary,
        onSecondary: foregroundLight,
        surface: card,
        onSurface: foreground,
        error: destructive,
        onError: foregroundLight,
        tertiary: accent,
        onTertiary: foreground,
        surfaceTint: Colors.transparent, // Removes material 3 tint
      ),

      // Borders / dividers
      dividerColor: border,

      // Cards & sheets - clean white with subtle shadows
      cardTheme: CardThemeData(
        color: card,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        margin: EdgeInsets.zero,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: popover,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: popover,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),

      // Inputs (text fields) - clean with subtle borders
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: foreground.withOpacity(0.4)),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: border),
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: primary, width: 2),
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: border),
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),

      // Buttons - rounded and friendly
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: foregroundLight,
          elevation: 2,
          shadowColor: primary.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: borderPurple, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),

      // Switches & sliders - purple theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.grey.shade400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryLight;
          return Colors.grey.shade300;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: primaryLight,
        thumbColor: primary,
        overlayColor: primary.withOpacity(0.2),
      ),

      // AppBar - clean with subtle shadow
      appBarTheme: AppBarTheme(
        backgroundColor: card,
        elevation: 0,
        foregroundColor: foreground,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.05),
      ),

      // Chips / badges - purple tinted
      chipTheme: ChipThemeData(
        backgroundColor: primaryLight,
        selectedColor: primary,
        labelStyle: TextStyle(color: foreground),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),

      // Typography - clean and readable
      textTheme: base.textTheme
          .apply(
            bodyColor: foreground,
            displayColor: foreground,
          )
          .copyWith(
            headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: foreground),
            headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: foreground),
            titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: foreground),
            bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: foreground),
            bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: foreground),
            labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: foreground),
          ),
    );
  }
  
  // Keep dark theme for reference, but use light as default
  static ThemeData dark() => light();
}
