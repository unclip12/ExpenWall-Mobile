# ExpenWall v2.7.0 - Premium UI Overhaul Integration Guide

**Last Updated:** February 4, 2026, 1:41 PM IST  
**Version:** v2.7.0

---

## 🎨 Overview

This guide will help you integrate the new premium UI components into ExpenWall Mobile.

### What's New

✅ **10 Premium Themes** - Midnight Purple, Ocean Blue, Forest Emerald, Sunset Coral, Cherry Blossom, Deep Ocean, Golden Amber, Royal Violet, Arctic Ice, Rose Gold

✅ **Liquid Glass Design** - Apple-style translucent UI with blur effects

✅ **Animated Backgrounds** - Theme-specific gradients and particles

✅ **Bottom Sheet Animation** - Slide-up Add Transaction from FAB

✅ **Enhanced Money Flow** - Large amount display with particles

---

## 📋 Integration Steps

### Step 1: Update Main App with ThemedBackground

**File:** `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'theme/theme_config.dart';
import 'widgets/themed_background.dart';
import 'screens/home_screen_v2.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _currentThemeId = 'midnight_purple';
  bool _isDarkMode = true;

  void _changeTheme(String themeId) {
    setState(() {
      _currentThemeId = themeId;
    });
  }

  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeConfig = AppTheme.getTheme(_currentThemeId);

    return MaterialApp(
      title: 'ExpenWall',
      debugShowCheckedModeBanner: false,
      theme: themeConfig.lightTheme,
      darkTheme: themeConfig.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: ThemedBackground(
        config: _isDarkMode
            ? themeConfig.darkBackground
            : themeConfig.lightBackground,
        isDark: _isDarkMode,
        child: HomeScreenV2(
          onThemeChange: _changeTheme,
          onDarkModeToggle: _toggleDarkMode,
          currentThemeId: _currentThemeId,
          isDarkMode: _isDarkMode,
        ),
      ),
    );
  }
}
```

---

### Step 2: Update HomeScreenV2 FAB with Bottom Sheet

**File:** `lib/screens/home_screen_v2.dart`

Find the FloatingActionButton and replace navigation with:

```dart
import '../widgets/animated_bottom_sheet.dart';
import 'add_transaction_screen_v2.dart';

// Inside HomeScreenV2 build method
floatingActionButton: FloatingActionButton(
  heroTag: 'add_transaction_fab',
  onPressed: () {
    AnimatedBottomSheet.show(
      context: context,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddTransactionScreenV2(
          onTransactionAdded: (transaction) {
            Navigator.pop(context);
            // Trigger money flow animation
            _showMoneyFlowAnimation(transaction);
          },
        ),
      ),
      isDismissible: true,
      enableDrag: true,
      showHandle: true,
    );
  },
  child: const Icon(Icons.add, size: 28),
),
```

---

### Step 3: Add Money Flow Animation Trigger

**File:** `lib/screens/home_screen_v2.dart`

Add this method to HomeScreenV2:

```dart
import '../widgets/money_flow_animation.dart';

void _showMoneyFlowAnimation(Transaction transaction) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.3),
    builder: (context) => MoneyFlowAnimation(
      amount: transaction.amount,
      isIncome: transaction.type == TransactionType.income,
      onComplete: () {
        Navigator.pop(context);
        // Refresh transaction list
        setState(() {});
      },
    ),
  );
}
```

---

### Step 4: Create Theme Selector UI

**File:** `lib/screens/insights_screen.dart` (or create new `theme_selector_screen.dart`)

```dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class ThemeSelectorScreen extends StatelessWidget {
  final String currentThemeId;
  final Function(String) onThemeChange;

  const ThemeSelectorScreen({
    super.key,
    required this.currentThemeId,
    required this.onThemeChange,
  });

  @override
  Widget build(BuildContext context) {
    final allThemes = AppTheme.allThemes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Theme'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: allThemes.length,
        itemBuilder: (context, index) {
          final theme = allThemes[index];
          final isSelected = theme.id == currentThemeId;

          return AnimatedGlassCard(
            onTap: () => onThemeChange(theme.id),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: theme.darkBackground.gradientColors,
                ),
                border: isSelected
                    ? Border.all(
                        color: Colors.white,
                        width: 3,
                      )
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    theme.emoji,
                    style: const TextStyle(fontSize: 40),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    theme.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
```

---

### Step 5: Update Insights Tab with Theme Selector

**File:** `lib/screens/insights_screen.dart`

Add a button to open theme selector:

```dart
GlassCard(
  padding: const EdgeInsets.all(20),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Appearance',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 16),
      
      // Theme Selector Button
      ListTile(
        leading: Text(
          AppTheme.getTheme(currentThemeId).emoji,
          style: const TextStyle(fontSize: 28),
        ),
        title: const Text('Theme'),
        subtitle: Text(AppTheme.getTheme(currentThemeId).name),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ThemeSelectorScreen(
                currentThemeId: currentThemeId,
                onThemeChange: onThemeChange,
              ),
            ),
          );
        },
      ),
      
      const Divider(height: 32),
      
      // Dark Mode Toggle
      SwitchListTile(
        secondary: Icon(
          isDarkMode ? Icons.dark_mode : Icons.light_mode,
        ),
        title: const Text('Dark Mode'),
        value: isDarkMode,
        onChanged: (value) => onDarkModeToggle(),
      ),
    ],
  ),
),
```

---

### Step 6: Update AddTransactionScreenV2

**File:** `lib/screens/add_transaction_screen_v2.dart`

Remove Scaffold wrapper and update to work inside bottom sheet:

```dart
class AddTransactionScreenV2 extends StatefulWidget {
  final Function(Transaction)? onTransactionAdded;

  const AddTransactionScreenV2({
    super.key,
    this.onTransactionAdded,
  });

  @override
  State<AddTransactionScreenV2> createState() => _AddTransactionScreenV2State();
}

class _AddTransactionScreenV2State extends State<AddTransactionScreenV2> {
  // ... existing state variables ...

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Add Transaction',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // ... rest of form fields ...
          
          // Save button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _saveTransaction,
              child: const Text(
                'Save Transaction',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _saveTransaction() async {
    // ... existing validation ...
    
    final transaction = Transaction(/* ... */);
    await _transactionService.addTransaction(transaction);
    
    // Call callback with transaction
    widget.onTransactionAdded?.call(transaction);
  }
}
```

---

## 🎨 Component Usage Examples

### ThemedBackground

```dart
ThemedBackground(
  config: themeConfig.darkBackground,
  isDark: true,
  child: YourScreen(),
)
```

### AnimatedBottomSheet

```dart
AnimatedBottomSheet.show(
  context: context,
  child: YourBottomSheetContent(),
  isDismissible: true,
  enableDrag: true,
  showHandle: true,
)
```

### MoneyFlowAnimation

```dart
MoneyFlowAnimation(
  amount: 500.0,
  isIncome: false, // true for income, false for expense
  onComplete: () {
    // Called when animation completes
  },
)
```

### GlassCard

```dart
GlassCard(
  padding: const EdgeInsets.all(20),
  borderRadius: 24,
  blur: 15,
  showShimmer: true,
  child: YourContent(),
)
```

---

## 🎯 Testing Checklist

### Theme System
- [ ] All 10 themes load correctly
- [ ] Light/dark mode transitions smoothly
- [ ] Background changes with theme
- [ ] Particles match theme colors
- [ ] All UI elements readable in all themes

### Animations
- [ ] Bottom sheet slides up smoothly
- [ ] Bottom sheet dismisses on swipe down
- [ ] Money flow animation shows correct amount
- [ ] Money flow shows + for income, - for expense
- [ ] Particles display properly
- [ ] Amount display is large and visible

### Integration
- [ ] FAB opens bottom sheet (not new screen)
- [ ] Add transaction works from bottom sheet
- [ ] Cancel closes bottom sheet
- [ ] Save triggers money flow animation
- [ ] Theme selector accessible from Insights
- [ ] Selected theme persists

---

## 🐛 Known Issues & Solutions

### Issue 1: Bottom sheet keyboard overlap
**Solution:** Wrap content with `viewInsets.bottom` padding

```dart
Padding(
  padding: EdgeInsets.only(
    bottom: MediaQuery.of(context).viewInsets.bottom,
  ),
  child: YourContent(),
)
```

### Issue 2: Theme not persisting
**Solution:** Save theme ID to SharedPreferences

```dart
final prefs = await SharedPreferences.getInstance();
await prefs.setString('theme_id', themeId);
await prefs.setBool('is_dark_mode', isDarkMode);
```

### Issue 3: Particles causing lag
**Solution:** Reduce particle density in BackgroundConfig

```dart
BackgroundConfig(
  // ...
  particleDensity: 0.2, // Lower value = fewer particles
)
```

---

## 📝 Optional Enhancements

### 1. Add Theme Preview

Show live preview when selecting theme:

```dart
// In ThemeSelectorScreen
onTap: () {
  // Show preview dialog
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: ThemedBackground(
        config: theme.darkBackground,
        isDark: true,
        child: Container(
          height: 400,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text('Preview: ${theme.name}'),
              // Show sample cards, buttons, etc.
            ],
          ),
        ),
      ),
    ),
  );
}
```

### 2. Add Haptic Feedback

```dart
import 'package:flutter/services.dart';

// On theme change
HapticFeedback.mediumImpact();

// On transaction save
HapticFeedback.heavyImpact();
```

### 3. Add Theme Transition Animation

```dart
AnimatedTheme(
  data: themeConfig.darkTheme,
  duration: const Duration(milliseconds: 500),
  curve: Curves.easeInOut,
  child: YourApp(),
)
```

---

## 🚀 Next Steps

1. **Test on real device** - Animations perform differently on device vs emulator
2. **Performance profiling** - Check for dropped frames
3. **User feedback** - Get opinions on theme colors and animations
4. **Accessibility** - Test with TalkBack/VoiceOver
5. **Documentation** - Update README with new features

---

## 📞 Support

If you encounter issues:

1. Check this integration guide
2. Review component documentation
3. Test on multiple devices
4. Profile performance

---

**Happy Building! 🎨✨**

*Last Updated: February 4, 2026, 1:41 PM IST*
