import 'package:flutter/material.dart';
import 'dart:ui';

/// Base Liquid Morphism Theme
/// Provides glass effects, gradients, and liquid animations
class LiquidTheme {
  final String name;
  final Color primaryColor;
  final Color accentColor;
  final List<Color> gradientColors;
  
  // Glass effect properties
  final double glassBlur;
  final double glassOpacity;
  final double glassBorderOpacity;
  
  // Animation properties
  final Duration standardDuration;
  final Curve standardCurve;
  
  // Spacing and sizing
  final double cardBorderRadius;
  final double cardPadding;
  final double cardMargin;
  final double cardElevation;

  const LiquidTheme({
    required this.name,
    required this.primaryColor,
    required this.accentColor,
    required this.gradientColors,
    this.glassBlur = 10.0,
    this.glassOpacity = 0.1,
    this.glassBorderOpacity = 0.2,
    this.standardDuration = const Duration(milliseconds: 300),
    this.standardCurve = Curves.easeOutCubic,
    this.cardBorderRadius = 24.0,
    this.cardPadding = 20.0,
    this.cardMargin = 16.0,
    this.cardElevation = 0.0,
  });

  /// Build Material 3 ThemeData
  ThemeData buildTheme(bool isDark) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
        primary: primaryColor,
        secondary: accentColor,
      ),
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black87,
        ),
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // Card Theme
      cardTheme: CardTheme(
        elevation: cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardBorderRadius),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark 
            ? Colors.black.withOpacity(0.8) 
            : Colors.white.withOpacity(0.8),
        selectedItemColor: primaryColor,
        unselectedItemColor: isDark 
            ? Colors.white54 
            : Colors.black54,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        elevation: 0,
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark 
            ? Colors.white.withOpacity(0.05) 
            : Colors.black.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark 
                ? Colors.white.withOpacity(0.1) 
                : Colors.black.withOpacity(0.1),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: primaryColor,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
  
  /// Create glass morphism container decoration
  BoxDecoration glassDecoration(bool isDark) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          (isDark ? Colors.white : Colors.white).withOpacity(glassOpacity),
          (isDark ? Colors.white : Colors.white).withOpacity(glassOpacity * 0.5),
        ],
      ),
      borderRadius: BorderRadius.circular(cardBorderRadius),
      border: Border.all(
        color: (isDark ? Colors.white : Colors.white).withOpacity(glassBorderOpacity),
        width: 1.5,
      ),
    );
  }
  
  /// Create gradient background decoration
  BoxDecoration gradientBackground(bool isDark) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark 
            ? gradientColors.map((c) => c.withOpacity(0.8)).toList()
            : gradientColors,
        stops: const [0.0, 0.5, 1.0],
      ),
    );
  }
}

/// Ocean Wave Theme - Deep Blue with Cyan accents
final oceanWaveTheme = LiquidTheme(
  name: 'Ocean Wave',
  primaryColor: const Color(0xFF1976D2),      // Deep Blue
  accentColor: const Color(0xFF00BCD4),       // Cyan
  gradientColors: const [
    Color(0xFF1976D2),  // Deep Blue
    Color(0xFF0D47A1),  // Darker Blue
    Color(0xFF01579B),  // Navy Blue
  ],
);

/// Sunset Glow Theme - Orange with Pink accents
final sunsetGlowTheme = LiquidTheme(
  name: 'Sunset Glow',
  primaryColor: const Color(0xFFFF6F00),      // Deep Orange
  accentColor: const Color(0xFFE91E63),       // Pink
  gradientColors: const [
    Color(0xFFFF6F00),  // Deep Orange
    Color(0xFFE65100),  // Darker Orange
    Color(0xFFBF360C),  // Dark Red-Orange
  ],
);

/// Available themes list
final availableThemes = [
  oceanWaveTheme,
  sunsetGlowTheme,
];
