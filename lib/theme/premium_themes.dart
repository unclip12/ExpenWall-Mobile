import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium Theme System - 10 Beautiful Themes with Liquid Glass Design
class PremiumThemes {
  // Theme Names
  static const List<String> themeNames = [
    'Midnight Purple',
    'Ocean Blue',
    'Forest Emerald',
    'Sunset Coral',
    'Cherry Blossom',
    'Deep Ocean',
    'Golden Amber',
    'Royal Violet',
    'Rose Gold',
    'Arctic Ice',
  ];

  // Get theme by index
  static ThemeData getTheme(int index, bool isDark) {
    switch (index) {
      case 0:
        return _midnightPurple(isDark);
      case 1:
        return _oceanBlue(isDark);
      case 2:
        return _forestEmerald(isDark);
      case 3:
        return _sunsetCoral(isDark);
      case 4:
        return _cherryBlossom(isDark);
      case 5:
        return _deepOcean(isDark);
      case 6:
        return _goldenAmber(isDark);
      case 7:
        return _royalViolet(isDark);
      case 8:
        return _roseGold(isDark);
      case 9:
        return _arcticIce(isDark);
      default:
        return _midnightPurple(isDark);
    }
  }

  // Get background colors for theme
  static List<Color> getBackgroundColors(int index, bool isDark) {
    if (isDark) {
      switch (index) {
        case 0: // Midnight Purple
          return [Color(0xFF0A0E1A), Color(0xFF1A1534), Color(0xFF2D1B4E)];
        case 1: // Ocean Blue
          return [Color(0xFF0A1929), Color(0xFF132F4C), Color(0xFF1E4976)];
        case 2: // Forest Emerald
          return [Color(0xFF0A1A12), Color(0xFF133027), Color(0xFF1E4A3C)];
        case 3: // Sunset Coral
          return [Color(0xFF1A0A0F), Color(0xFF2D1520), Color(0xFF4A2332)];
        case 4: // Cherry Blossom
          return [Color(0xFF1A0A15), Color(0xFF2D1525), Color(0xFF4A2340)];
        case 5: // Deep Ocean
          return [Color(0xFF020617), Color(0xFF0F172A), Color(0xFF1E293B)];
        case 6: // Golden Amber
          return [Color(0xFF1A1410), Color(0xFF2D2418), Color(0xFF4A3A20)];
        case 7: // Royal Violet
          return [Color(0xFF120A1A), Color(0xFF1F1430), Color(0xFF331E4A)];
        case 8: // Rose Gold
          return [Color(0xFF1A1012), Color(0xFF2D1A20), Color(0xFF4A2832)];
        case 9: // Arctic Ice
          return [Color(0xFF0A1419), Color(0xFF13232D), Color(0xFF1E3744)];
        default:
          return [Color(0xFF0A0E1A), Color(0xFF1A1534), Color(0xFF2D1B4E)];
      }
    } else {
      switch (index) {
        case 0: // Midnight Purple
          return [Color(0xFFFAF5FF), Color(0xFFF3E8FF), Color(0xFFE9D5FF)];
        case 1: // Ocean Blue
          return [Color(0xFFF0F9FF), Color(0xFFE0F2FE), Color(0xFFBAE6FD)];
        case 2: // Forest Emerald
          return [Color(0xFFF0FDF4), Color(0xFFDCFCE7), Color(0xFFBBF7D0)];
        case 3: // Sunset Coral
          return [Color(0xFFFFF5F5), Color(0xFFFED7D7), Color(0xFFFBB6B6)];
        case 4: // Cherry Blossom
          return [Color(0xFFFFF5F7), Color(0xFFFED7E2), Color(0xFFFBB6CE)];
        case 5: // Deep Ocean
          return [Color(0xFFF8FAFC), Color(0xFFF1F5F9), Color(0xFFE2E8F0)];
        case 6: // Golden Amber
          return [Color(0xFFFFFBEB), Color(0xFFFEF3C7), Color(0xFFFDE68A)];
        case 7: // Royal Violet
          return [Color(0xFFFAF5FF), Color(0xFFF3E8FF), Color(0xFFE9D5FF)];
        case 8: // Rose Gold
          return [Color(0xFFFFF5F7), Color(0xFFFED7E2), Color(0xFFFBB6CE)];
        case 9: // Arctic Ice
          return [Color(0xFFF0F9FF), Color(0xFFE0F2FE), Color(0xFFBAE6FD)];
        default:
          return [Color(0xFFFAF5FF), Color(0xFFF3E8FF), Color(0xFFE9D5FF)];
      }
    }
  }

  // Get primary color for theme
  static Color getPrimaryColor(int index) {
    switch (index) {
      case 0:
        return Color(0xFF9333EA); // Purple
      case 1:
        return Color(0xFF0284C7); // Blue
      case 2:
        return Color(0xFF059669); // Emerald
      case 3:
        return Color(0xFFDC2626); // Coral/Red
      case 4:
        return Color(0xFFDB2777); // Pink
      case 5:
        return Color(0xFF0F172A); // Deep Blue
      case 6:
        return Color(0xFFD97706); // Amber
      case 7:
        return Color(0xFF7C3AED); // Violet
      case 8:
        return Color(0xFFBE185D); // Rose
      case 9:
        return Color(0xFF0891B2); // Cyan
      default:
        return Color(0xFF9333EA);
    }
  }

  // Base theme builder
  static ThemeData _buildTheme({
    required Color primary,
    required Color secondary,
    required Color accent,
    required Color background,
    required Color surface,
    required Color surfaceVariant,
    required bool isDark,
  }) {
    final textColor = isDark ? Colors.white : Color(0xFF1E293B);
    final brightness = isDark ? Brightness.dark : Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        primary: primary,
        secondary: secondary,
        tertiary: accent,
        surface: surface,
        background: background,
      ),
      scaffoldBackgroundColor: background,
      textTheme: _buildTextTheme(textColor),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: surfaceVariant.withOpacity(isDark ? 0.3 : 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.5),
            width: 1.5,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: primary,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: primary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant.withOpacity(isDark ? 0.2 : 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: primary.withOpacity(0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : primary.withOpacity(0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: primary,
            width: 2,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }

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

  // Theme 1: Midnight Purple
  static ThemeData _midnightPurple(bool isDark) {
    return _buildTheme(
      primary: Color(0xFF9333EA),
      secondary: Color(0xFF8B5CF6),
      accent: Color(0xFF6366F1),
      background: isDark ? Color(0xFF0A0E1A) : Color(0xFFFAF5FF),
      surface: isDark ? Color(0xFF151B2E) : Color(0xFFFFFFFF),
      surfaceVariant: isDark ? Color(0xFF1A1F36) : Color(0xFFF3E8FF),
      isDark: isDark,
    );
  }

  // Theme 2: Ocean Blue
  static ThemeData _oceanBlue(bool isDark) {
    return _buildTheme(
      primary: Color(0xFF0284C7),
      secondary: Color(0xFF0EA5E9),
      accent: Color(0xFF06B6D4),
      background: isDark ? Color(0xFF0A1929) : Color(0xFFF0F9FF),
      surface: isDark ? Color(0xFF132F4C) : Color(0xFFFFFFFF),
      surfaceVariant: isDark ? Color(0xFF1E4976) : Color(0xFFE0F2FE),
      isDark: isDark,
    );
  }

  // Theme 3: Forest Emerald
  static ThemeData _forestEmerald(bool isDark) {
    return _buildTheme(
      primary: Color(0xFF059669),
      secondary: Color(0xFF10B981),
      accent: Color(0xFF14B8A6),
      background: isDark ? Color(0xFF0A1A12) : Color(0xFFF0FDF4),
      surface: isDark ? Color(0xFF133027) : Color(0xFFFFFFFF),
      surfaceVariant: isDark ? Color(0xFF1E4A3C) : Color(0xFFDCFCE7),
      isDark: isDark,
    );
  }

  // Theme 4: Sunset Coral
  static ThemeData _sunsetCoral(bool isDark) {
    return _buildTheme(
      primary: Color(0xFFDC2626),
      secondary: Color(0xFFEF4444),
      accent: Color(0xFFF97316),
      background: isDark ? Color(0xFF1A0A0F) : Color(0xFFFFF5F5),
      surface: isDark ? Color(0xFF2D1520) : Color(0xFFFFFFFF),
      surfaceVariant: isDark ? Color(0xFF4A2332) : Color(0xFFFED7D7),
      isDark: isDark,
    );
  }

  // Theme 5: Cherry Blossom
  static ThemeData _cherryBlossom(bool isDark) {
    return _buildTheme(
      primary: Color(0xFFDB2777),
      secondary: Color(0xFFEC4899),
      accent: Color(0xFFF472B6),
      background: isDark ? Color(0xFF1A0A15) : Color(0xFFFFF5F7),
      surface: isDark ? Color(0xFF2D1525) : Color(0xFFFFFFFF),
      surfaceVariant: isDark ? Color(0xFF4A2340) : Color(0xFFFED7E2),
      isDark: isDark,
    );
  }

  // Theme 6: Deep Ocean
  static ThemeData _deepOcean(bool isDark) {
    return _buildTheme(
      primary: Color(0xFF0F172A),
      secondary: Color(0xFF1E293B),
      accent: Color(0xFF334155),
      background: isDark ? Color(0xFF020617) : Color(0xFFF8FAFC),
      surface: isDark ? Color(0xFF0F172A) : Color(0xFFFFFFFF),
      surfaceVariant: isDark ? Color(0xFF1E293B) : Color(0xFFF1F5F9),
      isDark: isDark,
    );
  }

  // Theme 7: Golden Amber
  static ThemeData _goldenAmber(bool isDark) {
    return _buildTheme(
      primary: Color(0xFFD97706),
      secondary: Color(0xFFF59E0B),
      accent: Color(0xFFFBBF24),
      background: isDark ? Color(0xFF1A1410) : Color(0xFFFFFBEB),
      surface: isDark ? Color(0xFF2D2418) : Color(0xFFFFFFFF),
      surfaceVariant: isDark ? Color(0xFF4A3A20) : Color(0xFFFEF3C7),
      isDark: isDark,
    );
  }

  // Theme 8: Royal Violet
  static ThemeData _royalViolet(bool isDark) {
    return _buildTheme(
      primary: Color(0xFF7C3AED),
      secondary: Color(0xFF8B5CF6),
      accent: Color(0xFFA78BFA),
      background: isDark ? Color(0xFF120A1A) : Color(0xFFFAF5FF),
      surface: isDark ? Color(0xFF1F1430) : Color(0xFFFFFFFF),
      surfaceVariant: isDark ? Color(0xFF331E4A) : Color(0xFFF3E8FF),
      isDark: isDark,
    );
  }

  // Theme 9: Rose Gold
  static ThemeData _roseGold(bool isDark) {
    return _buildTheme(
      primary: Color(0xFFBE185D),
      secondary: Color(0xFFE11D48),
      accent: Color(0xFFF43F5E),
      background: isDark ? Color(0xFF1A1012) : Color(0xFFFFF5F7),
      surface: isDark ? Color(0xFF2D1A20) : Color(0xFFFFFFFF),
      surfaceVariant: isDark ? Color(0xFF4A2832) : Color(0xFFFED7E2),
      isDark: isDark,
    );
  }

  // Theme 10: Arctic Ice
  static ThemeData _arcticIce(bool isDark) {
    return _buildTheme(
      primary: Color(0xFF0891B2),
      secondary: Color(0xFF06B6D4),
      accent: Color(0xFF22D3EE),
      background: isDark ? Color(0xFF0A1419) : Color(0xFFF0F9FF),
      surface: isDark ? Color(0xFF13232D) : Color(0xFFFFFFFF),
      surfaceVariant: isDark ? Color(0xFF1E3744) : Color(0xFFE0F2FE),
      isDark: isDark,
    );
  }
}
