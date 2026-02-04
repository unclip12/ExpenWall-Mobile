import 'package:flutter/material.dart';

/// Premium Theme System for ExpenWall
/// 10 Carefully crafted themes with liquid glass aesthetics
class PremiumTheme {
  final String name;
  final String id;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color textColor;
  final List<Color> gradientColors;
  final List<Color> backgroundGradient;
  final bool isDark;

  const PremiumTheme({
    required this.name,
    required this.id,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.textColor,
    required this.gradientColors,
    required this.backgroundGradient,
    required this.isDark,
  });

  ThemeData toThemeData() {
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        onSecondary: Colors.white,
        tertiary: accentColor,
        onTertiary: Colors.white,
        error: Colors.red,
        onError: Colors.white,
        background: backgroundColor,
        onBackground: textColor,
        surface: surfaceColor,
        onSurface: textColor,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textColor,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: surfaceColor.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}

/// 10 Premium Themes
class PremiumThemes {
  static const midnightPurple = PremiumTheme(
    name: 'Midnight Purple',
    id: 'midnight_purple',
    primaryColor: Color(0xFF9333EA),
    secondaryColor: Color(0xFF7C3AED),
    accentColor: Color(0xFFA855F7),
    backgroundColor: Color(0xFF0F0A1E),
    surfaceColor: Color(0xFF1A1338),
    textColor: Color(0xFFF5F3FF),
    gradientColors: [Color(0xFF9333EA), Color(0xFF7C3AED), Color(0xFF6B21A8)],
    backgroundGradient: [Color(0xFF0F0A1E), Color(0xFF1E1033), Color(0xFF2D1B4E)],
    isDark: true,
  );

  static const oceanBlue = PremiumTheme(
    name: 'Ocean Blue',
    id: 'ocean_blue',
    primaryColor: Color(0xFF0EA5E9),
    secondaryColor: Color(0xFF0284C7),
    accentColor: Color(0xFF38BDF8),
    backgroundColor: Color(0xFF0A1929),
    surfaceColor: Color(0xFF132F4C),
    textColor: Color(0xFFE3F2FD),
    gradientColors: [Color(0xFF0EA5E9), Color(0xFF0284C7), Color(0xFF0369A1)],
    backgroundGradient: [Color(0xFF0A1929), Color(0xFF0C2744), Color(0xFF0F3460)],
    isDark: true,
  );

  static const forestEmerald = PremiumTheme(
    name: 'Forest Emerald',
    id: 'forest_emerald',
    primaryColor: Color(0xFF10B981),
    secondaryColor: Color(0xFF059669),
    accentColor: Color(0xFF34D399),
    backgroundColor: Color(0xFF0A1F1A),
    surfaceColor: Color(0xFF133B2E),
    textColor: Color(0xFFD1FAE5),
    gradientColors: [Color(0xFF10B981), Color(0xFF059669), Color(0xFF047857)],
    backgroundGradient: [Color(0xFF0A1F1A), Color(0xFF0F2E23), Color(0xFF143D2E)],
    isDark: true,
  );

  static const sunsetCoral = PremiumTheme(
    name: 'Sunset Coral',
    id: 'sunset_coral',
    primaryColor: Color(0xFFF97316),
    secondaryColor: Color(0xFFEA580C),
    accentColor: Color(0xFFFB923C),
    backgroundColor: Color(0xFF1F0A0A),
    surfaceColor: Color(0xFF3B1311),
    textColor: Color(0xFFFED7AA),
    gradientColors: [Color(0xFFF97316), Color(0xFFEA580C), Color(0xFFC2410C)],
    backgroundGradient: [Color(0xFF1F0A0A), Color(0xFF2E100E), Color(0xFF3D1612)],
    isDark: true,
  );

  static const cherryBlossom = PremiumTheme(
    name: 'Cherry Blossom',
    id: 'cherry_blossom',
    primaryColor: Color(0xFFEC4899),
    secondaryColor: Color(0xFFDB2777),
    accentColor: Color(0xFFF472B6),
    backgroundColor: Color(0xFFFFF5F7),
    surfaceColor: Color(0xFFFFF1F2),
    textColor: Color(0xFF4A1A2E),
    gradientColors: [Color(0xFFEC4899), Color(0xFFDB2777), Color(0xFFBE185D)],
    backgroundGradient: [Color(0xFFFFF5F7), Color(0xFFFFE4E9), Color(0xFFFFD4DC)],
    isDark: false,
  );

  static const deepOcean = PremiumTheme(
    name: 'Deep Ocean',
    id: 'deep_ocean',
    primaryColor: Color(0xFF0891B2),
    secondaryColor: Color(0xFF0E7490),
    accentColor: Color(0xFF06B6D4),
    backgroundColor: Color(0xFF042F3E),
    surfaceColor: Color(0xFF164E63),
    textColor: Color(0xFFCFFAFE),
    gradientColors: [Color(0xFF0891B2), Color(0xFF0E7490), Color(0xFF155E75)],
    backgroundGradient: [Color(0xFF042F3E), Color(0xFF083D4F), Color(0xFF0C4A60)],
    isDark: true,
  );

  static const goldenAmber = PremiumTheme(
    name: 'Golden Amber',
    id: 'golden_amber',
    primaryColor: Color(0xFFF59E0B),
    secondaryColor: Color(0xFFD97706),
    accentColor: Color(0xFFFBBF24),
    backgroundColor: Color(0xFFFFFBEB),
    surfaceColor: Color(0xFFFEF3C7),
    textColor: Color(0xFF78350F),
    gradientColors: [Color(0xFFF59E0B), Color(0xFFD97706), Color(0xFFB45309)],
    backgroundGradient: [Color(0xFFFFFBEB), Color(0xFFFEF3C7), Color(0xFFFDE68A)],
    isDark: false,
  );

  static const royalViolet = PremiumTheme(
    name: 'Royal Violet',
    id: 'royal_violet',
    primaryColor: Color(0xFF8B5CF6),
    secondaryColor: Color(0xFF7C3AED),
    accentColor: Color(0xFFA78BFA),
    backgroundColor: Color(0xFF1E1B4B),
    surfaceColor: Color(0xFF312E81),
    textColor: Color(0xFFEDE9FE),
    gradientColors: [Color(0xFF8B5CF6), Color(0xFF7C3AED), Color(0xFF6D28D9)],
    backgroundGradient: [Color(0xFF1E1B4B), Color(0xFF2E2761), Color(0xFF3E3378)],
    isDark: true,
  );

  static const roseGold = PremiumTheme(
    name: 'Rose Gold',
    id: 'rose_gold',
    primaryColor: Color(0xFFF43F5E),
    secondaryColor: Color(0xFFE11D48),
    accentColor: Color(0xFFFB7185),
    backgroundColor: Color(0xFFFFF1F2),
    surfaceColor: Color(0xFFFFE4E6),
    textColor: Color(0xFF4C0519),
    gradientColors: [Color(0xFFF43F5E), Color(0xFFE11D48), Color(0xFFBE123C)],
    backgroundGradient: [Color(0xFFFFF1F2), Color(0xFFFFE4E6), Color(0xFFFECDD3)],
    isDark: false,
  );

  static const arcticIce = PremiumTheme(
    name: 'Arctic Ice',
    id: 'arctic_ice',
    primaryColor: Color(0xFF06B6D4),
    secondaryColor: Color(0xFF0891B2),
    accentColor: Color(0xFF22D3EE),
    backgroundColor: Color(0xFFECFEFF),
    surfaceColor: Color(0xFFCFFAFE),
    textColor: Color(0xFF083344),
    gradientColors: [Color(0xFF06B6D4), Color(0xFF0891B2), Color(0xFF0E7490)],
    backgroundGradient: [Color(0xFFECFEFF), Color(0xFFCFFAFE), Color(0xFFA5F3FC)],
    isDark: false,
  );

  static List<PremiumTheme> get all => [
        midnightPurple,
        oceanBlue,
        forestEmerald,
        sunsetCoral,
        cherryBlossom,
        deepOcean,
        goldenAmber,
        royalViolet,
        roseGold,
        arcticIce,
      ];

  static PremiumTheme getById(String id) {
    return all.firstWhere(
      (theme) => theme.id == id,
      orElse: () => midnightPurple,
    );
  }
}
