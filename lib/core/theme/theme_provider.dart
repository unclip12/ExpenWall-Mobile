import 'package:flutter/material.dart';
import 'liquid_theme.dart';

/// Theme Provider for managing app theme state
class ThemeProvider extends ChangeNotifier {
  LiquidTheme _currentTheme = oceanWaveTheme;
  bool _isDarkMode = false;

  LiquidTheme get currentTheme => _currentTheme;
  bool get isDarkMode => _isDarkMode;
  ThemeData get themeData => _currentTheme.buildTheme(_isDarkMode);

  /// Switch between themes
  void setTheme(LiquidTheme theme) {
    _currentTheme = theme;
    notifyListeners();
  }

  /// Toggle dark/light mode
  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  /// Set dark mode explicitly
  void setDarkMode(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }
}
