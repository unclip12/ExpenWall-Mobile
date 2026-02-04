import 'package:flutter/material.dart';

/// Premium theme configuration
class ThemeConfig {
  final String id;
  final String name;
  final String emoji;
  final ThemeData lightTheme;
  final ThemeData darkTheme;
  final BackgroundConfig lightBackground;
  final BackgroundConfig darkBackground;
  final List<Color> accentColors;
  
  const ThemeConfig({
    required this.id,
    required this.name,
    required this.emoji,
    required this.lightTheme,
    required this.darkTheme,
    required this.lightBackground,
    required this.darkBackground,
    required this.accentColors,
  });
}

/// Background configuration for animated backgrounds
class BackgroundConfig {
  final List<Color> gradientColors;
  final List<Color> particleColors;
  final ParticleType particleType;
  final double particleDensity;
  final double animationSpeed;
  
  const BackgroundConfig({
    required this.gradientColors,
    required this.particleColors,
    required this.particleType,
    this.particleDensity = 0.3,
    this.animationSpeed = 1.0,
  });
}

enum ParticleType {
  currency,     // Rupee symbols
  geometric,    // Circles, triangles
  floral,       // Flowers, petals
  cosmic,       // Stars, planets
  aquatic,      // Bubbles, waves
  minimal,      // Dots only
}
