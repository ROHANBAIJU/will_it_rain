import 'package:flutter/material.dart';

/// A palette of 6 nice colors for data visualization
class Palette {
  static const List<Color> _colors = [
    Color(0xFF2563EB), // Primary Blue
    Color(0xFF10B981), // Emerald Green
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFF8B5CF6), // Purple
    Color(0xFF06B6D4), // Cyan
  ];

  /// Get all available colors
  static List<Color> get colors => List.unmodifiable(_colors);

  /// Get a color by index (wraps around if index exceeds available colors)
  static Color getColor(int index) {
    return _colors[index % _colors.length];
  }

  /// Get a color as an integer value by index
  static int getColorValue(int index) {
    return getColor(index).value;
  }

  /// Get the next color in the sequence
  static Color getNextColor(int currentIndex) {
    return getColor(currentIndex + 1);
  }

  /// Get the next color value as an integer
  static int getNextColorValue(int currentIndex) {
    return getNextColor(currentIndex).value;
  }

  /// Get a random color from the palette
  static Color getRandomColor() {
    final random = DateTime.now().millisecondsSinceEpoch;
    return getColor(random % _colors.length);
  }

  /// Get a random color value as an integer
  static int getRandomColorValue() {
    return getRandomColor().value;
  }

  /// Get colors for a specific number of items
  static List<Color> getColorsForCount(int count) {
    return List.generate(count, (index) => getColor(index));
  }

  /// Get color values as integers for a specific number of items
  static List<int> getColorValuesForCount(int count) {
    return List.generate(count, (index) => getColorValue(index));
  }

  /// Get a color that contrasts well with the given background color
  static Color getContrastingColor(Color backgroundColor) {
    // Calculate luminance to determine if we need light or dark text
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  /// Get a color that's similar to the given color but with different saturation
  static Color getSimilarColor(Color baseColor, {double saturationFactor = 0.8}) {
    final hsl = HSLColor.fromColor(baseColor);
    return hsl.withSaturation(hsl.saturation * saturationFactor).toColor();
  }

  /// Get a gradient from the palette
  static LinearGradient getGradient(int startIndex, int endIndex) {
    return LinearGradient(
      colors: [getColor(startIndex), getColor(endIndex)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Get a radial gradient from the palette
  static RadialGradient getRadialGradient(int centerIndex, int edgeIndex) {
    return RadialGradient(
      colors: [getColor(centerIndex), getColor(edgeIndex)],
      center: Alignment.center,
      radius: 1.0,
    );
  }

  /// Get color names for debugging/logging
  static String getColorName(int index) {
    const names = [
      'Primary Blue',
      'Emerald Green',
      'Amber',
      'Red',
      'Purple',
      'Cyan',
    ];
    return names[index % names.length];
  }

  /// Get color hex string
  static String getColorHex(int index) {
    return '#${getColor(index).value.toRadixString(16).substring(2).toUpperCase()}';
  }

  /// Check if a color is in the palette
  static bool isInPalette(Color color) {
    return _colors.any((c) => c.value == color.value);
  }

  /// Get the index of a color in the palette, or -1 if not found
  static int getColorIndex(Color color) {
    for (int i = 0; i < _colors.length; i++) {
      if (_colors[i].value == color.value) {
        return i;
      }
    }
    return -1;
  }
}


