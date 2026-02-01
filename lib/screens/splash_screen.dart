import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/firebase_service.dart';
import 'auth_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Initialize Firebase
      await _firebaseService.initialize();

      // Wait for animation to complete (3 seconds)
      await Future.delayed(const Duration(seconds: 3));

      if (!mounted) return;

      // Check if user is signed in
      final isSignedIn = _firebaseService.isSignedIn;

      // Navigate to appropriate screen
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              isSignedIn ? const HomeScreen() : const AuthScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Liquid transition effect
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            var tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);
            return SlideTransition(
              position: offsetAnimation,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    } catch (e) {
      print('Initialization error: $e');
      // Show error and retry
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing app: $e'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _initialize,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
              Theme.of(context).colorScheme.tertiary,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo with liquid drop animation
              _buildLogo(),
              const SizedBox(height: 40),
              // App Name with shimmer effect
              _buildAppName(),
              const SizedBox(height: 20),
              // Tagline
              _buildTagline(),
              const SizedBox(height: 60),
              // Loading indicator
              _buildLoadingIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white,
            Colors.white.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.5),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.account_balance_wallet_rounded,
          size: 60,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          delay: 1000.ms,
          duration: 2000.ms,
          color: Colors.white.withOpacity(0.3),
        )
        .animate()
        .scale(
          begin: const Offset(0, 0),
          end: const Offset(1, 1),
          duration: 800.ms,
          curve: Curves.elasticOut,
        )
        .then()
        .shake(
          hz: 2,
          curve: Curves.easeInOutCubic,
          duration: 500.ms,
        );
  }

  Widget _buildAppName() {
    return Text(
      'ExpenWall',
      style: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 2,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 400.ms, duration: 600.ms)
        .slideY(begin: 0.3, end: 0, duration: 600.ms, curve: Curves.easeOut)
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          delay: 1500.ms,
          duration: 2000.ms,
          color: Colors.white.withOpacity(0.5),
        );
  }

  Widget _buildTagline() {
    return Text(
      'Track. Save. Resist.',
      style: TextStyle(
        fontSize: 18,
        color: Colors.white.withOpacity(0.9),
        letterSpacing: 1.5,
        fontWeight: FontWeight.w300,
      ),
    )
        .animate()
        .fadeIn(delay: 800.ms, duration: 600.ms)
        .slideY(begin: 0.3, end: 0, duration: 600.ms, curve: Curves.easeOut);
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 40,
      height: 40,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(
          Colors.white.withOpacity(0.8),
        ),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .fadeIn(delay: 1200.ms, duration: 600.ms)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          duration: 1000.ms,
          curve: Curves.easeInOut,
        );
  }
}
