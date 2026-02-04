import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_config.dart';
import '../theme/theme_compat.dart';
import '../providers/theme_provider.dart';
import '../widgets/glass_card.dart';

/// Screen for selecting app theme from 10 premium options
/// Shows theme previews in a grid with color swatches
class ThemeSelectorScreen extends StatelessWidget {
  const ThemeSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Theme'),
        centerTitle: true,
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header section
              Text(
                'Premium Themes',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your favorite color palette',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // Dark mode toggle
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      themeProvider.isDarkMode
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dark Mode',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            themeProvider.isDarkMode
                                ? 'Easier on the eyes at night'
                                : 'Better for daytime use',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (_) {
                        HapticFeedback.lightImpact();
                        themeProvider.toggleDarkMode();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Theme grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: AppTheme.allThemes.length,
                itemBuilder: (context, index) {
                  final theme = AppTheme.allThemes[index];
                  final isSelected =
                      themeProvider.currentThemeConfig.id == theme.id;

                  return _ThemeCard(
                    theme: theme,
                    isSelected: isSelected,
                    isDarkMode: themeProvider.isDarkMode,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      themeProvider.setTheme(theme);
                    },
                  );
                },
              ),
              const SizedBox(height: 100),
            ],
          );
        },
      ),
    );
  }
}

/// Individual theme preview card
class _ThemeCard extends StatelessWidget {
  final ThemeConfig theme;
  final bool isSelected;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.theme,
    required this.isSelected,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgConfig = theme.getBackgroundConfig(isDarkMode);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.primaryColor
                : Colors.grey.withOpacity(0.3),
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // Gradient background preview
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: bgConfig.gradientColors,
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Theme icon & name
                    Row(
                      children: [
                        Text(
                          theme.emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 8),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.check_circle,
                              color: theme.primaryColor,
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),

                    // Theme name
                    Text(
                      theme.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Color swatches
                    Row(
                      children: [
                        _ColorSwatch(color: theme.primaryColor),
                        const SizedBox(width: 4),
                        _ColorSwatch(color: theme.secondaryColor),
                        const SizedBox(width: 4),
                        _ColorSwatch(color: theme.accentColor),
                      ],
                    ),
                  ],
                ),
              ),

              // Selected overlay
              if (isSelected)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small circular color swatch
class _ColorSwatch extends StatelessWidget {
  final Color color;

  const _ColorSwatch({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
