import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../theme/theme_config.dart';

/// Provider for managing app theme and background configuration
/// Handles theme selection, persistence, and dark mode toggle
class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'selected_theme';
  static const String _darkModeKey = 'dark_mode';

  ThemeConfig _currentThemeConfig = ThemeConfig.midnightPurple;
  bool _isDarkMode = false;

  ThemeConfig get currentThemeConfig => _currentThemeConfig;
  bool get isDarkMode => _isDarkMode;

  /// Get current Flutter ThemeData based on theme config and dark mode
  ThemeData get currentTheme {
    return AppTheme.getTheme(_currentThemeConfig, isDark: _isDarkMode);
  }

  /// Get background configuration for ThemedBackground widget
  BackgroundConfig get backgroundConfig {
    return _currentThemeConfig.getBackgroundConfig(_isDarkMode);
  }

  ThemeProvider() {
    _loadThemeFromPreferences();
  }

  /// Load saved theme from SharedPreferences on app start
  Future<void> _loadThemeFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load theme
      final themeId = prefs.getString(_themeKey) ?? ThemeConfig.midnightPurple.id;
      _currentThemeConfig = ThemeConfig.allThemes.firstWhere(
        (theme) => theme.id == themeId,
        orElse: () => ThemeConfig.midnightPurple,
      );
      
      // Load dark mode
      _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
      
      notifyListeners();
    } catch (e) {
      print('Error loading theme preferences: $e');
    }
  }

  /// Change theme and save to preferences
  Future<void> setTheme(ThemeConfig theme) async {
    _currentThemeConfig = theme;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, theme.id);
    } catch (e) {
      print('Error saving theme preference: $e');
    }
  }

  /// Toggle dark mode and save to preferences
  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_darkModeKey, _isDarkMode);
    } catch (e) {
      print('Error saving dark mode preference: $e');
    }
  }

  /// Set dark mode explicitly
  Future<void> setDarkMode(bool isDark) async {
    if (_isDarkMode == isDark) return;
    
    _isDarkMode = isDark;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_darkModeKey, _isDarkMode);
    } catch (e) {
      print('Error saving dark mode preference: $e');
    }
  }
}
