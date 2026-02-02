import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen_v2.dart';
import 'services/theme_service.dart';
import 'widgets/animated_gradient_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Enable edge-to-edge
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static _MyAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MyAppState>();
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _themeService = ThemeService();
  String _currentTheme = 'midnightPurple';
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreferences();
  }

  Future<void> _loadThemePreferences() async {
    final theme = await _themeService.getTheme();
    final darkMode = await _themeService.getDarkMode();
    setState(() {
      _currentTheme = theme;
      _isDarkMode = darkMode;
    });
  }

  void changeTheme(String theme, bool isDark) {
    setState(() {
      _currentTheme = theme;
      _isDarkMode = isDark;
    });
    _themeService.saveTheme(theme);
    _themeService.saveDarkMode(isDark);
  }

  @override
  Widget build(BuildContext context) {
    final themeData = _themeService.getThemeData(_currentTheme, _isDarkMode);
    final gradientColors = _themeService.getGradientColors(_currentTheme, _isDarkMode);

    return MaterialApp(
      title: 'ExpenWall',
      debugShowCheckedModeBanner: false,
      theme: themeData,
      home: AnimatedGradientBackground(
        colors: gradientColors,
        child: const SplashScreen(
          nextScreen: HomeScreenV2(),
        ),
      ),
      builder: (context, child) {
        return AnimatedGradientBackground(
          colors: gradientColors,
          child: child ?? const SizedBox(),
        );
      },
    );
  }
}
