import 'package:flutter/material.dart';
import 'dart:async';
import 'wallet_painter.dart';
import '../home/home_screen.dart';

/// Animated splash screen with wallet opening animation
class WalletSplashScreen extends StatefulWidget {
  const WalletSplashScreen({Key? key}) : super(key: key);

  @override
  State<WalletSplashScreen> createState() => _WalletSplashScreenState();
}

class _WalletSplashScreenState extends State<WalletSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _walletController;
  late AnimationController _contentController;
  late AnimationController _transitionController;

  late Animation<double> _walletOpenAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<double> _contentScaleAnimation;
  late Animation<double> _transitionFadeAnimation;
  late Animation<double> _transitionScaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimationSequence();
  }

  void _setupAnimations() {
    // Wallet opening animation (0-2s)
    _walletController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _walletOpenAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _walletController,
        curve: Curves.easeOutCubic,
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _walletController,
        curve: Curves.easeInOut,
      ),
    );

    // Content reveal animation (1.5-2.5s)
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _contentFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: Curves.easeIn,
      ),
    );

    _contentScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: Curves.easeOutBack,
      ),
    );

    // Transition to home (2.5-3s)
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _transitionFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: Curves.easeInCubic,
      ),
    );

    _transitionScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: Curves.easeInCubic,
      ),
    );
  }

  void _startAnimationSequence() async {
    // Start wallet opening
    _walletController.forward();

    // Wait 1.5s then reveal content
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      _contentController.forward();
    }

    // Wait 1s more then transition to home
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      _transitionController.forward();
    }

    // Wait for transition to finish then navigate
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  @override
  void dispose() {
    _walletController.dispose();
    _contentController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _walletController,
          _contentController,
          _transitionController,
        ]),
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.scaffoldBackgroundColor,
                  theme.scaffoldBackgroundColor.withOpacity(0.8),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Animated glow effect
                Positioned.fill(
                  child: Opacity(
                    opacity: _glowAnimation.value * 0.3,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.8,
                          colors: [
                            primaryColor.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Wallet animation
                Center(
                  child: Opacity(
                    opacity: _transitionFadeAnimation.value,
                    child: Transform.scale(
                      scale: _transitionScaleAnimation.value,
                      child: CustomPaint(
                        size: Size(
                          MediaQuery.of(context).size.width,
                          MediaQuery.of(context).size.height,
                        ),
                        painter: WalletPainter(
                          openProgress: _walletOpenAnimation.value,
                          primaryColor: primaryColor,
                          accentColor: secondaryColor,
                        ),
                      ),
                    ),
                  ),
                ),

                // App name and logo reveal
                Center(
                  child: Opacity(
                    opacity: _contentFadeAnimation.value *
                        _transitionFadeAnimation.value,
                    child: Transform.scale(
                      scale: _contentScaleAnimation.value,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo/Icon
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [primaryColor, secondaryColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // App name
                          Text(
                            'ExpenWall',
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: theme.colorScheme.onBackground,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Tagline
                          Text(
                            'Smart Expense Tracking',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onBackground
                                  .withOpacity(0.6),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Loading indicator at bottom
                Positioned(
                  bottom: 80,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: _transitionFadeAnimation.value,
                    child: Center(
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            primaryColor.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
