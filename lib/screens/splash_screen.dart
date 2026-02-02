import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'home_screen.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _titleController;
  late AnimationController _walletController;
  late Animation<double> _titleFadeAnimation;
  late Animation<Offset> _titleSlideAnimation;
  late Animation<double> _walletRotateAnimation;
  late Animation<double> _walletScaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Wallet animation - smooth entrance
    _walletController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _walletScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _walletController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _walletRotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _walletController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    // Title animation - letters fade in
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeIn),
    );

    _titleSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeOut),
    );

    // Start animations
    _walletController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _titleController.forward();
    });

    // Navigate to home after splash
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    // Wait for animations to complete
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    // Navigate directly to HomeScreen (no auth required!)
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _walletController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark 
              ? AppTheme.darkBackgroundGradient
              : AppTheme.lightBackgroundGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Wallet Icon with smooth animation
              AnimatedBuilder(
                animation: _walletController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _walletScaleAnimation.value,
                    child: Transform.rotate(
                      angle: (1 - _walletRotateAnimation.value) * math.pi * 0.2,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: AppTheme.purpleGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryPurple.withOpacity(0.4),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              
              // Title with letter animation
              SlideTransition(
                position: _titleSlideAnimation,
                child: FadeTransition(
                  opacity: _titleFadeAnimation,
                  child: ShaderMask(
                    shaderCallback: (bounds) => AppTheme.purpleGradient.createShader(bounds),
                    child: Text(
                      'ExpenWall',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            color: AppTheme.primaryPurple.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Subtitle
              FadeTransition(
                opacity: _titleFadeAnimation,
                child: Text(
                  'Smart Expense Tracking',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark 
                        ? Colors.white.withOpacity(0.7)
                        : Colors.black54,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 60),
              
              // Dot loader
              const DotLoader(),
            ],
          ),
        ),
      ),
    );
  }
}

// Smooth dot loader animation
class DotLoader extends StatefulWidget {
  const DotLoader({super.key});

  @override
  State<DotLoader> createState() => _DotLoaderState();
}

class _DotLoaderState extends State<DotLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 20,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (index) {
              final delay = index * 0.2;
              final value = (_controller.value - delay) % 1.0;
              final opacity = (math.sin(value * math.pi * 2) + 1) / 2;
              final scale = 0.6 + (opacity * 0.4);
              
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryPurple.withOpacity(opacity),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryPurple.withOpacity(opacity * 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
