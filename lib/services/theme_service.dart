import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeType {
  midnightPurple,
  oceanBlue,
  forestGreen,
  sunsetOrange,
  cherryBlossom,
  midnightBlack,
  arcticWhite,
  lavenderDream,
  emeraldLuxury,
  goldenHour,
}

class ThemeService {
  static const String _themeKey = 'selected_theme';
  static const String _darkModeKey = 'dark_mode';
  
  // Get saved theme
  Future<AppThemeType> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? 0;
    return AppThemeType.values[themeIndex];
  }
  
  // Save theme
  Future<void> setTheme(AppThemeType theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, theme.index);
  }
  
  // Get dark mode preference
  Future<bool> isDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }
  
  // Set dark mode
  Future<void> setDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, isDark);
  }
  
  // Get theme data
  ThemeData getThemeData(AppThemeType themeType, bool isDark) {
    switch (themeType) {
      case AppThemeType.midnightPurple:
        return _midnightPurpleTheme(isDark);
      case AppThemeType.oceanBlue:
        return _oceanBlueTheme(isDark);
      case AppThemeType.forestGreen:
        return _forestGreenTheme(isDark);
      case AppThemeType.sunsetOrange:
        return _sunsetOrangeTheme(isDark);
      case AppThemeType.cherryBlossom:
        return _cherryBlossomTheme(isDark);
      case AppThemeType.midnightBlack:
        return _midnightBlackTheme(isDark);
      case AppThemeType.arcticWhite:
        return _arcticWhiteTheme(isDark);
      case AppThemeType.lavenderDream:
        return _lavenderDreamTheme(isDark);
      case AppThemeType.emeraldLuxury:
        return _emeraldLuxuryTheme(isDark);
      case AppThemeType.goldenHour:
        return _goldenHourTheme(isDark);
    }
  }
  
  // Get theme metadata
  static Map<AppThemeType, Map<String, dynamic>> themeMetadata = {
    AppThemeType.midnightPurple: {
      'name': 'Midnight Purple',
      'description': 'Rich purple gradients',
      'primaryColor': const Color(0xFF9333EA),
      'icon': Icons.nights_stay,
    },
    AppThemeType.oceanBlue: {
      'name': 'Ocean Blue',
      'description': 'Deep ocean vibes',
      'primaryColor': const Color(0xFF0EA5E9),
      'icon': Icons.water,
    },
    AppThemeType.forestGreen: {
      'name': 'Forest Green',
      'description': 'Nature inspired',
      'primaryColor': const Color(0xFF10B981),
      'icon': Icons.forest,
    },
    AppThemeType.sunsetOrange: {
      'name': 'Sunset Orange',
      'description': 'Warm sunset tones',
      'primaryColor': const Color(0xFFF97316),
      'icon': Icons.wb_sunny,
    },
    AppThemeType.cherryBlossom: {
      'name': 'Cherry Blossom',
      'description': 'Soft pink elegance',
      'primaryColor': const Color(0xFFEC4899),
      'icon': Icons.local_florist,
    },
    AppThemeType.midnightBlack: {
      'name': 'Midnight Black',
      'description': 'Pure OLED black',
      'primaryColor': const Color(0xFF6366F1),
      'icon': Icons.dark_mode,
    },
    AppThemeType.arcticWhite: {
      'name': 'Arctic White',
      'description': 'Clean minimalism',
      'primaryColor': const Color(0xFF8B5CF6),
      'icon': Icons.light_mode,
    },
    AppThemeType.lavenderDream: {
      'name': 'Lavender Dream',
      'description': 'Soft lavender hues',
      'primaryColor': const Color(0xFFA78BFA),
      'icon': Icons.auto_awesome,
    },
    AppThemeType.emeraldLuxury: {
      'name': 'Emerald Luxury',
      'description': 'Premium emerald',
      'primaryColor': const Color(0xFF059669),
      'icon': Icons.diamond,
    },
    AppThemeType.goldenHour: {
      'name': 'Golden Hour',
      'description': 'Warm golden glow',
      'primaryColor': const Color(0xFFF59E0B),
      'icon': Icons.wb_twilight,
    },
  };
  
  // Theme definitions
  
  ThemeData _midnightPurpleTheme(bool isDark) {
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF9333EA),
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      scaffoldBackgroundColor: isDark 
          ? const Color(0xFF0F0F1E)
          : const Color(0xFFF8F7FF),
      cardColor: isDark
          ? const Color(0xFF1A1A2E)
          : Colors.white,
      fontFamily: 'Inter',
    );
  }
  
  ThemeData _oceanBlueTheme(bool isDark) {
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0EA5E9),
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      scaffoldBackgroundColor: isDark 
          ? const Color(0xFF0A1929)
          : const Color(0xFFE0F2FE),
      cardColor: isDark
          ? const Color(0xFF1E3A5F)
          : Colors.white,
      fontFamily: 'Inter',
    );
  }
  
  ThemeData _forestGreenTheme(bool isDark) {
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF10B981),
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      scaffoldBackgroundColor: isDark 
          ? const Color(0xFF0A1F1A)
          : const Color(0xFFD1FAE5),
      cardColor: isDark
          ? const Color(0xFF1A3A2F)
          : Colors.white,
      fontFamily: 'Inter',
    );
  }
  
  ThemeData _sunsetOrangeTheme(bool isDark) {
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFF97316),
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      scaffoldBackgroundColor: isDark 
          ? const Color(0xFF1F1108)
          : const Color(0xFFFFEDD5),
      cardColor: isDark
          ? const Color(0xFF3A2410)
          : Colors.white,
      fontFamily: 'Inter',
    );
  }
  
  ThemeData _cherryBlossomTheme(bool isDark) {
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFEC4899),
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      scaffoldBackgroundColor: isDark 
          ? const Color(0xFF1F0A19)
          : const Color(0xFFFCE7F3),
      cardColor: isDark
          ? const Color(0xFF3A1A2F)
          : Colors.white,
      fontFamily: 'Inter',
    );
  }
  
  ThemeData _midnightBlackTheme(bool isDark) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6366F1),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: Colors.black,
      cardColor: const Color(0xFF0A0A0A),
      fontFamily: 'Inter',
    );
  }
  
  ThemeData _arcticWhiteTheme(bool isDark) {
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF8B5CF6),
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      scaffoldBackgroundColor: isDark 
          ? const Color(0xFF18181B)
          : Colors.white,
      cardColor: isDark
          ? const Color(0xFF27272A)
          : const Color(0xFFFAFAFA),
      fontFamily: 'Inter',
    );
  }
  
  ThemeData _lavenderDreamTheme(bool isDark) {
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFA78BFA),
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      scaffoldBackgroundColor: isDark 
          ? const Color(0xFF1A0F2E)
          : const Color(0xFFF3E8FF),
      cardColor: isDark
          ? const Color(0xFF2A1A4A)
          : Colors.white,
      fontFamily: 'Inter',
    );
  }
  
  ThemeData _emeraldLuxuryTheme(bool isDark) {
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF059669),
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      scaffoldBackgroundColor: isDark 
          ? const Color(0xFF0A1F1A)
          : const Color(0xFFD1FAE5),
      cardColor: isDark
          ? const Color(0xFF1A4D3A)
          : Colors.white,
      fontFamily: 'Inter',
    );
  }
  
  ThemeData _goldenHourTheme(bool isDark) {
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFF59E0B),
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      scaffoldBackgroundColor: isDark 
          ? const Color(0xFF1F1A0A)
          : const Color(0xFFFEF3C7),
      cardColor: isDark
          ? const Color(0xFF3A2F1A)
          : Colors.white,
      fontFamily: 'Inter',
    );
  }
}
