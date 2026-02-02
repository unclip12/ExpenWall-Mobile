import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set edge-to-edge mode (fixes bottom white line)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarColor: Colors.transparent,
    ),
  );

  runApp(const ExpenWallApp());
}

class ExpenWallApp extends StatefulWidget {
  const ExpenWallApp({super.key});

  @override
  State<ExpenWallApp> createState() => _ExpenWallAppState();
  
  // Global key to access app state from anywhere
  static _ExpenWallAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<_ExpenWallAppState>();
  }
}

class _ExpenWallAppState extends State<ExpenWallApp> {
  final ThemeService _themeService = ThemeService();
  
  AppThemeType _currentTheme = AppThemeType.midnightPurple;
  bool _isDarkMode = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThemePreferences();
  }

  Future<void> _loadThemePreferences() async {
    final savedTheme = await _themeService.getTheme();
    final savedDarkMode = await _themeService.isDarkMode();
    
    setState(() {
      _currentTheme = savedTheme;
      _isDarkMode = savedDarkMode;
      _isLoading = false;
    });
    
    // Update system UI overlay based on theme
    _updateSystemUI();
  }

  void _updateSystemUI() {
    final brightness = _isDarkMode ? Brightness.light : Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: brightness,
        systemNavigationBarIconBrightness: brightness,
      ),
    );
  }

  // Method to change theme at runtime
  Future<void> changeTheme(AppThemeType newTheme) async {
    setState(() {
      _currentTheme = newTheme;
    });
    await _themeService.setTheme(newTheme);
    _updateSystemUI();
  }

  // Method to toggle dark mode
  Future<void> toggleDarkMode(bool isDark) async {
    setState(() {
      _isDarkMode = isDark;
    });
    await _themeService.setDarkMode(isDark);
    _updateSystemUI();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final themeData = _themeService.getThemeData(_currentTheme, _isDarkMode);

    return MaterialApp(
      title: 'ExpenWall',
      debugShowCheckedModeBanner: false,
      theme: themeData,
      darkTheme: themeData,
      themeMode: ThemeMode.light, // We manage dark mode ourselves
      home: const SplashScreen(),
      builder: (context, child) {
        // Add beautiful gradient background based on theme
        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(
            gradient: _getBackgroundGradient(),
          ),
          child: child,
        );
      },
    );
  }

  LinearGradient _getBackgroundGradient() {
    // Get primary color from theme metadata
    final primaryColor = ThemeService.themeMetadata[_currentTheme]!['primaryColor'] as Color;
    
    if (_isDarkMode) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primaryColor.withOpacity(0.1),
          Colors.black,
          Colors.black,
        ],
      );
    } else {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primaryColor.withOpacity(0.05),
          Colors.white,
          primaryColor.withOpacity(0.03),
        ],
      );
    }
  }
}
