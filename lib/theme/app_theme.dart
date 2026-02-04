import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme_config.dart';

class AppTheme {
  // ========================================
  // 10 PREMIUM THEMES
  // ========================================

  /// Get theme by ID
  static ThemeConfig getTheme(String themeId) {
    switch (themeId) {
      case 'midnight_purple':
        return midnightPurple;
      case 'ocean_blue':
        return oceanBlue;
      case 'forest_emerald':
        return forestEmerald;
      case 'sunset_coral':
        return sunsetCoral;
      case 'cherry_blossom':
        return cherryBlossom;
      case 'deep_ocean':
        return deepOcean;
      case 'golden_amber':
        return goldenAmber;
      case 'royal_violet':
        return royalViolet;
      case 'arctic_ice':
        return arcticIce;
      case 'rose_gold':
        return roseGold;
      default:
        return midnightPurple;
    }
  }

  /// Get all available themes
  static List<ThemeConfig> get allThemes => [
        midnightPurple,
        oceanBlue,
        forestEmerald,
        sunsetCoral,
        cherryBlossom,
        deepOcean,
        goldenAmber,
        royalViolet,
        arcticIce,
        roseGold,
      ];

  // ========================================
  // THEME 1: MIDNIGHT PURPLE (DEFAULT)
  // ========================================
  static final ThemeConfig midnightPurple = ThemeConfig(
    id: 'midnight_purple',
    name: 'Midnight Purple',
    emoji: '🌌',
    lightTheme: _buildLightTheme(
      primary: const Color(0xFF9333EA),
      secondary: const Color(0xFF8B5CF6),
      accent: const Color(0xFF6366F1),
    ),
    darkTheme: _buildDarkTheme(
      primary: const Color(0xFF9333EA),
      secondary: const Color(0xFF8B5CF6),
      accent: const Color(0xFF6366F1),
    ),
    lightBackground: const BackgroundConfig(
      gradientColors: [Color(0xFFFAF5FF), Color(0xFFF3E8FF), Color(0xFFE9D5FF)],
      particleColors: [Color(0xFF9333EA), Color(0xFF8B5CF6), Color(0xFFC084FC)],
      particleType: ParticleType.cosmic,
    ),
    darkBackground: const BackgroundConfig(
      gradientColors: [Color(0xFF0A0E1A), Color(0xFF1E1B4B), Color(0xFF312E81)],
      particleColors: [Color(0xFF9333EA), Color(0xFF8B5CF6), Color(0xFFC084FC)],
      particleType: ParticleType.cosmic,
    ),
    accentColors: const [
      Color(0xFF9333EA),
      Color(0xFF8B5CF6),
      Color(0xFF6366F1),
      Color(0xFFC084FC),
    ],
  );

  // ========================================
  // THEME 2: OCEAN BLUE
  // ========================================
  static final ThemeConfig oceanBlue = ThemeConfig(
    id: 'ocean_blue',
    name: 'Ocean Blue',
    emoji: '🌊',
    lightTheme: _buildLightTheme(
      primary: const Color(0xFF0EA5E9),
      secondary: const Color(0xFF06B6D4),
      accent: const Color(0xFF3B82F6),
    ),
    darkTheme: _buildDarkTheme(
      primary: const Color(0xFF0EA5E9),
      secondary: const Color(0xFF06B6D4),
      accent: const Color(0xFF3B82F6),
    ),
    lightBackground: const BackgroundConfig(
      gradientColors: [Color(0xFFECFEFF), Color(0xFFCFFAFE), Color(0xFFA5F3FC)],
      particleColors: [Color(0xFF0EA5E9), Color(0xFF06B6D4), Color(0xFF22D3EE)],
      particleType: ParticleType.aquatic,
    ),
    darkBackground: const BackgroundConfig(
      gradientColors: [Color(0xFF082F49), Color(0xFF0C4A6E), Color(0xFF075985)],
      particleColors: [Color(0xFF0EA5E9), Color(0xFF06B6D4), Color(0xFF22D3EE)],
      particleType: ParticleType.aquatic,
    ),
    accentColors: const [
      Color(0xFF0EA5E9),
      Color(0xFF06B6D4),
      Color(0xFF3B82F6),
      Color(0xFF22D3EE),
    ],
  );

  // ========================================
  // THEME 3: FOREST EMERALD
  // ========================================
  static final ThemeConfig forestEmerald = ThemeConfig(
    id: 'forest_emerald',
    name: 'Forest Emerald',
    emoji: '🌲',
    lightTheme: _buildLightTheme(
      primary: const Color(0xFF10B981),
      secondary: const Color(0xFF059669),
      accent: const Color(0xFF14B8A6),
    ),
    darkTheme: _buildDarkTheme(
      primary: const Color(0xFF10B981),
      secondary: const Color(0xFF059669),
      accent: const Color(0xFF14B8A6),
    ),
    lightBackground: const BackgroundConfig(
      gradientColors: [Color(0xFFECFDF5), Color(0xFFD1FAE5), Color(0xFFA7F3D0)],
      particleColors: [Color(0xFF10B981), Color(0xFF059669), Color(0xFF34D399)],
      particleType: ParticleType.floral,
    ),
    darkBackground: const BackgroundConfig(
      gradientColors: [Color(0xFF022C22), Color(0xFF064E3B), Color(0xFF065F46)],
      particleColors: [Color(0xFF10B981), Color(0xFF059669), Color(0xFF34D399)],
      particleType: ParticleType.floral,
    ),
    accentColors: const [
      Color(0xFF10B981),
      Color(0xFF059669),
      Color(0xFF14B8A6),
      Color(0xFF34D399),
    ],
  );

  // ========================================
  // THEME 4: SUNSET CORAL
  // ========================================
  static final ThemeConfig sunsetCoral = ThemeConfig(
    id: 'sunset_coral',
    name: 'Sunset Coral',
    emoji: '🌅',
    lightTheme: _buildLightTheme(
      primary: const Color(0xFFF97316),
      secondary: const Color(0xFFEF4444),
      accent: const Color(0xFFF59E0B),
    ),
    darkTheme: _buildDarkTheme(
      primary: const Color(0xFFF97316),
      secondary: const Color(0xFFEF4444),
      accent: const Color(0xFFF59E0B),
    ),
    lightBackground: const BackgroundConfig(
      gradientColors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5), Color(0xFFFED7AA)],
      particleColors: [Color(0xFFF97316), Color(0xFFEF4444), Color(0xFFFB923C)],
      particleType: ParticleType.geometric,
    ),
    darkBackground: const BackgroundConfig(
      gradientColors: [Color(0xFF431407), Color(0xFF7C2D12), Color(0xFF9A3412)],
      particleColors: [Color(0xFFF97316), Color(0xFFEF4444), Color(0xFFFB923C)],
      particleType: ParticleType.geometric,
    ),
    accentColors: const [
      Color(0xFFF97316),
      Color(0xFFEF4444),
      Color(0xFFF59E0B),
      Color(0xFFFB923C),
    ],
  );

  // ========================================
  // THEME 5: CHERRY BLOSSOM
  // ========================================
  static final ThemeConfig cherryBlossom = ThemeConfig(
    id: 'cherry_blossom',
    name: 'Cherry Blossom',
    emoji: '🌸',
    lightTheme: _buildLightTheme(
      primary: const Color(0xFFEC4899),
      secondary: const Color(0xFFF472B6),
      accent: const Color(0xFFDB2777),
    ),
    darkTheme: _buildDarkTheme(
      primary: const Color(0xFFEC4899),
      secondary: const Color(0xFFF472B6),
      accent: const Color(0xFFDB2777),
    ),
    lightBackground: const BackgroundConfig(
      gradientColors: [Color(0xFFFDF2F8), Color(0xFFFCE7F3), Color(0xFFFBCFE8)],
      particleColors: [Color(0xFFEC4899), Color(0xFFF472B6), Color(0xFFF9A8D4)],
      particleType: ParticleType.floral,
    ),
    darkBackground: const BackgroundConfig(
      gradientColors: [Color(0xFF500724), Color(0xFF831843), Color(0xFF9F1239)],
      particleColors: [Color(0xFFEC4899), Color(0xFFF472B6), Color(0xFFF9A8D4)],
      particleType: ParticleType.floral,
    ),
    accentColors: const [
      Color(0xFFEC4899),
      Color(0xFFF472B6),
      Color(0xFFDB2777),
      Color(0xFFF9A8D4),
    ],
  );

  // ========================================
  // THEME 6: DEEP OCEAN
  // ========================================
  static final ThemeConfig deepOcean = ThemeConfig(
    id: 'deep_ocean',
    name: 'Deep Ocean',
    emoji: '🌊',
    lightTheme: _buildLightTheme(
      primary: const Color(0xFF1E40AF),
      secondary: const Color(0xFF1E3A8A),
      accent: const Color(0xFF3B82F6),
    ),
    darkTheme: _buildDarkTheme(
      primary: const Color(0xFF1E40AF),
      secondary: const Color(0xFF1E3A8A),
      accent: const Color(0xFF3B82F6),
    ),
    lightBackground: const BackgroundConfig(
      gradientColors: [Color(0xFFDCEEFB), Color(0xFFBFDBFE), Color(0xFF93C5FD)],
      particleColors: [Color(0xFF1E40AF), Color(0xFF3B82F6), Color(0xFF60A5FA)],
      particleType: ParticleType.aquatic,
      particleDensity: 0.4,
    ),
    darkBackground: const BackgroundConfig(
      gradientColors: [Color(0xFF0C1E3D), Color(0xFF1E3A8A), Color(0xFF1E40AF)],
      particleColors: [Color(0xFF1E40AF), Color(0xFF3B82F6), Color(0xFF60A5FA)],
      particleType: ParticleType.aquatic,
      particleDensity: 0.4,
    ),
    accentColors: const [
      Color(0xFF1E40AF),
      Color(0xFF1E3A8A),
      Color(0xFF3B82F6),
      Color(0xFF60A5FA),
    ],
  );

  // ========================================
  // THEME 7: GOLDEN AMBER
  // ========================================
  static final ThemeConfig goldenAmber = ThemeConfig(
    id: 'golden_amber',
    name: 'Golden Amber',
    emoji: '🟡',
    lightTheme: _buildLightTheme(
      primary: const Color(0xFFF59E0B),
      secondary: const Color(0xFFD97706),
      accent: const Color(0xFFFBBF24),
    ),
    darkTheme: _buildDarkTheme(
      primary: const Color(0xFFF59E0B),
      secondary: const Color(0xFFD97706),
      accent: const Color(0xFFFBBF24),
    ),
    lightBackground: const BackgroundConfig(
      gradientColors: [Color(0xFFFEFCE8), Color(0xFFFEF9C3), Color(0xFFFEF08A)],
      particleColors: [Color(0xFFF59E0B), Color(0xFFD97706), Color(0xFFFBBF24)],
      particleType: ParticleType.geometric,
    ),
    darkBackground: const BackgroundConfig(
      gradientColors: [Color(0xFF451A03), Color(0xFF78350F), Color(0xFF92400E)],
      particleColors: [Color(0xFFF59E0B), Color(0xFFD97706), Color(0xFFFBBF24)],
      particleType: ParticleType.geometric,
    ),
    accentColors: const [
      Color(0xFFF59E0B),
      Color(0xFFD97706),
      Color(0xFFFBBF24),
      Color(0xFFFCD34D),
    ],
  );

  // ========================================
  // THEME 8: ROYAL VIOLET
  // ========================================
  static final ThemeConfig royalViolet = ThemeConfig(
    id: 'royal_violet',
    name: 'Royal Violet',
    emoji: '💜',
    lightTheme: _buildLightTheme(
      primary: const Color(0xFF7C3AED),
      secondary: const Color(0xFF6D28D9),
      accent: const Color(0xFF8B5CF6),
    ),
    darkTheme: _buildDarkTheme(
      primary: const Color(0xFF7C3AED),
      secondary: const Color(0xFF6D28D9),
      accent: const Color(0xFF8B5CF6),
    ),
    lightBackground: const BackgroundConfig(
      gradientColors: [Color(0xFFF5F3FF), Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
      particleColors: [Color(0xFF7C3AED), Color(0xFF6D28D9), Color(0xFFA78BFA)],
      particleType: ParticleType.cosmic,
    ),
    darkBackground: const BackgroundConfig(
      gradientColors: [Color(0xFF2E1065), Color(0xFF4C1D95), Color(0xFF5B21B6)],
      particleColors: [Color(0xFF7C3AED), Color(0xFF6D28D9), Color(0xFFA78BFA)],
      particleType: ParticleType.cosmic,
    ),
    accentColors: const [
      Color(0xFF7C3AED),
      Color(0xFF6D28D9),
      Color(0xFF8B5CF6),
      Color(0xFFA78BFA),
    ],
  );

  // ========================================
  // THEME 9: ARCTIC ICE
  // ========================================
  static final ThemeConfig arcticIce = ThemeConfig(
    id: 'arctic_ice',
    name: 'Arctic Ice',
    emoji: '❄️',
    lightTheme: _buildLightTheme(
      primary: const Color(0xFF06B6D4),
      secondary: const Color(0xFF0891B2),
      accent: const Color(0xFF0E7490),
    ),
    darkTheme: _buildDarkTheme(
      primary: const Color(0xFF06B6D4),
      secondary: const Color(0xFF0891B2),
      accent: const Color(0xFF0E7490),
    ),
    lightBackground: const BackgroundConfig(
      gradientColors: [Color(0xFFFFFFFF), Color(0xFFF0FDFA), Color(0xFFCCFBF1)],
      particleColors: [Color(0xFF06B6D4), Color(0xFF0891B2), Color(0xFF22D3EE)],
      particleType: ParticleType.minimal,
    ),
    darkBackground: const BackgroundConfig(
      gradientColors: [Color(0xFF042F2E), Color(0xFF134E4A), Color(0xFF115E59)],
      particleColors: [Color(0xFF06B6D4), Color(0xFF0891B2), Color(0xFF22D3EE)],
      particleType: ParticleType.minimal,
    ),
    accentColors: const [
      Color(0xFF06B6D4),
      Color(0xFF0891B2),
      Color(0xFF0E7490),
      Color(0xFF22D3EE),
    ],
  );

  // ========================================
  // THEME 10: ROSE GOLD
  // ========================================
  static final ThemeConfig roseGold = ThemeConfig(
    id: 'rose_gold',
    name: 'Rose Gold',
    emoji: '🌹',
    lightTheme: _buildLightTheme(
      primary: const Color(0xFFF43F5E),
      secondary: const Color(0xFFE11D48),
      accent: const Color(0xFFFB7185),
    ),
    darkTheme: _buildDarkTheme(
      primary: const Color(0xFFF43F5E),
      secondary: const Color(0xFFE11D48),
      accent: const Color(0xFFFB7185),
    ),
    lightBackground: const BackgroundConfig(
      gradientColors: [Color(0xFFFFF1F2), Color(0xFFFFE4E6), Color(0xFFFECDD3)],
      particleColors: [Color(0xFFF43F5E), Color(0xFFE11D48), Color(0xFFFB7185)],
      particleType: ParticleType.floral,
    ),
    darkBackground: const BackgroundConfig(
      gradientColors: [Color(0xFF4C0519), Color(0xFF881337), Color(0xFF9F1239)],
      particleColors: [Color(0xFFF43F5E), Color(0xFFE11D48), Color(0xFFFB7185)],
      particleType: ParticleType.floral,
    ),
    accentColors: const [
      Color(0xFFF43F5E),
      Color(0xFFE11D48),
      Color(0xFFFB7185),
      Color(0xFFFDA4AF),
    ],
  );

  // ========================================
  // THEME BUILDERS
  // ========================================

  /// Build light theme with liquid glass design
  static ThemeData _buildLightTheme({
    required Color primary,
    required Color secondary,
    required Color accent,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      secondary: secondary,
      tertiary: accent,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: _buildTextTheme(const Color(0xFF1E293B)),
      
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1E293B),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1E293B),
          letterSpacing: -0.5,
        ),
      ),
      
      cardTheme: CardTheme(
        elevation: 0,
        color: Colors.white.withOpacity(0.7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Colors.white.withOpacity(0.8),
            width: 1.5,
          ),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: primary,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: primary.withOpacity(0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: primary.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.white.withOpacity(0.95),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        elevation: 0,
      ),
    );
  }

  /// Build dark theme with liquid glass design
  static ThemeData _buildDarkTheme({
    required Color primary,
    required Color secondary,
    required Color accent,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      primary: primary,
      secondary: secondary,
      tertiary: accent,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: _buildTextTheme(Colors.white),
      
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
      
      cardTheme: CardTheme(
        elevation: 0,
        color: Colors.white.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Colors.white.withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: primary,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: primary.withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: const Color(0xFF1A1F36).withOpacity(0.95),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        elevation: 0,
      ),
    );
  }

  /// Build text theme
  static TextTheme _buildTextTheme(Color textColor) {
    return TextTheme(
      displayLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textColor,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textColor,
        letterSpacing: -0.5,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textColor,
        letterSpacing: -0.3,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textColor,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }
}
