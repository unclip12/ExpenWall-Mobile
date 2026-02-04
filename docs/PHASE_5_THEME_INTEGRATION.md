# Phase 5: Theme Integration & Testing Guide

**Date:** February 4, 2026  
**Status:** Ready for Integration

---

## Overview

This guide shows how to integrate the complete theme system into your app with ThemeProvider and ThemeSelectorScreen.

---

## Step 1: Add Provider Dependency

Make sure you have `provider` in your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1  # Add this if not already present
  shared_preferences: ^2.2.2  # For theme persistence
```

Run:
```bash
flutter pub get
```

---

## Step 2: Update main.dart

### Before:
```dart
import 'package:flutter/material.dart';
import 'screens/home_screen_v2.dart';

void main() {
  runApp(const ExpenWallApp());
}

class ExpenWallApp extends StatelessWidget {
  const ExpenWallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ExpenWall',
      theme: ThemeData(...),
      home: HomeScreenV2(userId: 'user123'),
    );
  }
}
```

### After:
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen_v2.dart';
import 'providers/theme_provider.dart';
import 'widgets/themed_background.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const ExpenWallApp(),
    ),
  );
}

class ExpenWallApp extends StatelessWidget {
  const ExpenWallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'ExpenWall',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.currentTheme,
          home: ThemedBackground(
            config: themeProvider.backgroundConfig,
            child: HomeScreenV2(userId: 'user123'),
          ),
        );
      },
    );
  }
}
```

---

## Step 3: Add Theme Selector to Insights Tab

### Option A: Navigate to ThemeSelectorScreen

Add a button/tile in your Insights tab:

```dart
import 'package:expenwall_mobile/screens/theme_selector_screen.dart';

// Inside your Insights/Settings screen:
GlassCard(
  padding: EdgeInsets.zero,
  child: ListTile(
    leading: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.palette,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
    title: const Text(
      'Themes',
      style: TextStyle(fontWeight: FontWeight.bold),
    ),
    subtitle: const Text('Choose your favorite color palette'),
    trailing: const Icon(Icons.chevron_right),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ThemeSelectorScreen(),
        ),
      );
    },
  ),
),
```

### Option B: Show as Bottom Sheet

```dart
import 'package:expenwall_mobile/screens/theme_selector_screen.dart';
import 'package:expenwall_mobile/widgets/animated_bottom_sheet.dart';

// Trigger:
AnimatedBottomSheet.show(
  context: context,
  builder: (context) => const ThemeSelectorScreen(),
);
```

---

## Step 4: Test All Themes

### Testing Checklist:

#### Light Mode Testing:
- [ ] **Midnight Purple** - Default, deep purple cosmic
- [ ] **Ocean Blue** - Serene blue ocean gradient
- [ ] **Forest Emerald** - Fresh green forest tones
- [ ] **Sunset Coral** - Warm coral and orange
- [ ] **Cherry Blossom** - Soft pink sakura aesthetic
- [ ] **Deep Ocean** - Dark blue underwater
- [ ] **Golden Amber** - Luxurious gold and amber
- [ ] **Royal Violet** - Rich royal purple
- [ ] **Arctic Ice** - Cool icy blue-white
- [ ] **Rose Gold** - Elegant rose gold shimmer

#### Dark Mode Testing:
- [ ] Test all 10 themes in dark mode
- [ ] Verify text readability
- [ ] Check contrast ratios
- [ ] Ensure particles are visible
- [ ] Test navigation bar colors

#### Theme Switching:
- [ ] Theme changes instantly (no lag)
- [ ] Background animates smoothly (300ms)
- [ ] Particles update correctly
- [ ] All UI elements update colors
- [ ] Theme persists after app restart
- [ ] Dark mode toggle works
- [ ] Dark mode persists after restart

---

## Step 5: Complete Integration Example

### Full main.dart:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen_v2.dart';
import 'providers/theme_provider.dart';
import 'widgets/themed_background.dart';

void main() {
  // Lock to portrait mode
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Run app with ThemeProvider
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const ExpenWallApp(),
    ),
  );
}

class ExpenWallApp extends StatelessWidget {
  const ExpenWallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'ExpenWall',
          debugShowCheckedModeBanner: false,
          
          // Use theme from provider
          theme: themeProvider.currentTheme,
          
          // Wrap home in ThemedBackground
          home: ThemedBackground(
            config: themeProvider.backgroundConfig,
            child: HomeScreenV2(userId: 'user123'),
          ),
          
          // Define routes
          routes: {
            '/theme-selector': (context) => const ThemeSelectorScreen(),
          },
        );
      },
    );
  }
}
```

### Example Insights/Settings Screen:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../screens/theme_selector_screen.dart';
import '../widgets/glass_card.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights & Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Current theme display
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      themeProvider.currentThemeConfig.emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Theme',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            themeProvider.currentThemeConfig.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ThemeSelectorScreen(),
                      ),
                    );
                  },
                  child: const Text('Change Theme'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Other settings...
        ],
      ),
    );
  }
}
```

---

## Troubleshooting

### Issue: Theme not persisting after restart
**Solution:** Ensure SharedPreferences is working:
```dart
import 'package:shared_preferences/shared_preferences.dart';

// Test in main():
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  print('SharedPreferences working: ${prefs != null}');
  runApp(...);
}
```

### Issue: Background not showing
**Solution:** Make sure ThemedBackground wraps your home widget:
```dart
home: ThemedBackground(
  config: themeProvider.backgroundConfig,
  child: YourHomeScreen(),
)
```

### Issue: Theme changes but UI doesn't update
**Solution:** Use `Consumer<ThemeProvider>` or `context.watch<ThemeProvider>()` to listen to changes.

### Issue: Particles causing lag
**Solution:** Reduce particle density in ThemeConfig:
```dart
particleDensity: 0.2, // Lower value = fewer particles
```

---

## Performance Tips

### 1. Optimize Background Rendering
```dart
// In ThemedBackground, use RepaintBoundary:
RepaintBoundary(
  child: ThemedBackground(
    config: config,
    child: child,
  ),
)
```

### 2. Lazy Load ThemeSelectorScreen
```dart
// Don't import until needed:
onTap: () async {
  final screen = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const ThemeSelectorScreen(),
    ),
  );
}
```

### 3. Test on Real Devices
- Emulators can be slow with animations
- Test on low-end Android devices (2GB RAM)
- Test on older iOS devices (iPhone 8)
- Monitor FPS using DevTools

---

## Expected User Experience

### Opening Theme Selector:
1. User taps "Themes" in Insights tab
2. ThemeSelectorScreen opens
3. Grid shows 10 theme cards with live previews
4. Current theme has checkmark and glow effect
5. Dark mode toggle at top

### Selecting Theme:
1. User taps a theme card
2. Haptic feedback (medium impact)
3. Theme changes instantly
4. Background gradient animates smoothly (300ms)
5. Particles update colors
6. Checkmark moves to selected theme
7. Theme is saved to SharedPreferences

### Toggling Dark Mode:
1. User taps dark mode switch
2. Light haptic feedback
3. UI transitions to dark/light colors
4. Background adjusts brightness
5. Text colors update for readability
6. Dark mode preference saved

### App Restart:
1. User closes and reopens app
2. Saved theme loads automatically
3. Dark mode setting restored
4. Background appears instantly (no flash)

---

## Next Steps (Phase 6)

After theme system is working:
1. Performance profiling
2. Accessibility testing
3. UI polish and bug fixes
4. Demo video recording
5. Screenshots for Play Store

---

**Ready to see your app transform! 🎨✨**

*Last Updated: February 4, 2026, 2:25 PM IST*
