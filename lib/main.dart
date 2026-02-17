import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/theme_provider.dart';
import 'screens/splash/wallet_splash_screen.dart';

/// ExpenWall Mobile v3.0 - Clean Rebuild
/// Phase 1: Foundation with Liquid Morphism + Animated Splash
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for edge-to-edge
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Enable edge-to-edge mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const ExpenWallApp(),
    ),
  );
}

class ExpenWallApp extends StatelessWidget {
  const ExpenWallApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'ExpenWall',
          debugShowCheckedModeBanner: false,
          
          // Use Material 3 theme from liquid_theme
          theme: themeProvider.themeData,
          
          // Start with animated wallet splash screen
          home: const WalletSplashScreen(),
        );
      },
    );
  }
}
