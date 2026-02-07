import 'package:flutter/material.dart';

/// Color utility for adaptive text colors based on background luminance
class ColorUtils {
  /// Calculate luminance of a color (0.0 = black, 1.0 = white)
  static double calculateLuminance(Color color) {
    return color.computeLuminance();
  }

  /// Get adaptive text color based on background
  /// Returns white for dark backgrounds, dark gray for light backgrounds
  static Color getAdaptiveTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? const Color(0xFF1A237E) : Colors.white;
  }

  /// Get adaptive green color for income/positive values
  /// Returns darker green for light backgrounds, brighter green for dark backgrounds
  static Color getAdaptiveGreen(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    
    if (luminance > 0.5) {
      // Light background - use dark green for contrast
      return const Color(0xFF1B5E20); // Dark green
    } else {
      // Dark background - use bright green
      return const Color(0xFF66BB6A); // Bright green
    }
  }

  /// Get adaptive red color for expense/negative values
  /// Returns darker red for light backgrounds, brighter red for dark backgrounds
  static Color getAdaptiveRed(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    
    if (luminance > 0.5) {
      // Light background - use dark red for contrast
      return const Color(0xFFB71C1C); // Dark red
    } else {
      // Dark background - use bright red
      return const Color(0xFFEF5350); // Bright red
    }
  }

  /// Darken a color by a percentage (0.0 - 1.0)
  static Color darken(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final darkened = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darkened.toColor();
  }

  /// Lighten a color by a percentage (0.0 - 1.0)
  static Color lighten(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightened = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return lightened.toColor();
  }

  /// Get contrasting color (opposite of given color)
  static Color getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  /// Check if a color is considered "light" (luminance > 0.5)
  static bool isLightColor(Color color) {
    return color.computeLuminance() > 0.5;
  }

  /// Check if a color is considered "dark" (luminance <= 0.5)
  static bool isDarkColor(Color color) {
    return color.computeLuminance() <= 0.5;
  }
}
