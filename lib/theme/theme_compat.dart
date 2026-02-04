import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'theme_config.dart';

/// Backward compatibility extensions for old theme API
/// This allows existing code to work during v2.7.0 migration
class AppThemeCompat {
  // Old color constants
  static Color get primaryPurple => const Color(0xFF9333EA);
  
  // Old gradient constants
  static LinearGradient get purpleGradient => const LinearGradient(
    colors: [Color(0xFF9333EA), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get darkBackgroundGradient => const LinearGradient(
    colors: [Color(0xFF0A0E1A), Color(0xFF1E1B4B), Color(0xFF312E81)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static LinearGradient get lightBackgroundGradient => const LinearGradient(
    colors: [Color(0xFFFAF5FF), Color(0xFFF3E8FF), Color(0xFFE9D5FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

/// Extension for ThemeConfig compatibility
extension ThemeConfigCompat on ThemeConfig {
  Color get primaryColor => accentColors.first;
  Color get secondaryColor => accentColors.length > 1 ? accentColors[1] : accentColors.first;
  Color get accentColor => accentColors.last;
  String get description => name;
  
  BackgroundConfig getBackgroundConfig(bool isDark) {
    return isDark ? darkBackground : lightBackground;
  }
}
