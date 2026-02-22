import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../home/home_screen.dart';
import 'wallet_painter.dart';

class WalletSplashScreen extends StatefulWidget {
  const WalletSplashScreen({Key? key}) : super(key: key);

  @override
  State<WalletSplashScreen> createState() => _WalletSplashScreenState();
}

class _WalletSplashScreenState extends State<WalletSplashScreen> with TickerProviderStateMixin {
  late AnimationController _walletOpenController;
  late AnimationController _cardsEjectController;
  late AnimationController _dashboardTransformController;
  late AnimationController _bgController;

  late Animation<double> _walletOpen;
  late Animation<double> _cardsEject;
  late Animation<double> _dashboardTransform;
  late Animation<double> _walletFade;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSequence();
  }

  void _setupAnimations() {
    _bgController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    
    _walletOpenController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _walletOpen = CurvedAnimation(parent: _walletOpenController, curve: Curves.easeOutBack);

    _cardsEjectController = AnimationController(duration: const Duration(milliseconds: 900), vsync: this);
    _cardsEject = CurvedAnimation(parent: _cardsEjectController, curve: Curves.easeOutBack);

    _dashboardTransformController = AnimationController(duration: const Duration(milliseconds: 1100), vsync: this);
    _dashboardTransform = CurvedAnimation(parent: _dashboardTransformController, curve: Curves.easeInOutCubic);
    
    // Fade out wallet and background text as dashboard expands
    _walletFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _dashboardTransformController, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );
  }

  void _startSequence() async {
    _bgController.forward();
    
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    HapticFeedback.lightImpact();
    _walletOpenController.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    _cardsEjectController.forward();

    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    _dashboardTransformController.forward();

    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _walletOpenController.dispose();
    _cardsEjectController.dispose();
    _dashboardTransformController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;

    return Scaffold(
      backgroundColor: const Color(0xFF07071A),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _walletOpenController,
          _cardsEjectController,
          _dashboardTransformController,
        ]),
        builder: (context, _) {
          return Stack(
            children: [
              // Background Gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF07071A), Color(0xFF0F0F2E), Color(0xFF07071A)],
                  ),
                ),
              ),
              
              // App Name (Fades out when transforming)
              Positioned(
                top: size.height * 0.18,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: _walletFade.value,
                  child: Center(
                    child: Text(
                      'ExpenWall',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              // Wallet Back
              Opacity(
                opacity: _walletFade.value,
                child: CustomPaint(
                  size: size,
                  painter: WalletBackPainter(primaryColor: primary),
                ),
              ),

              // Cards & Cash
              _buildAnimatableCard(size: size, index: 2, color: Colors.green.shade700, isCash: true),
              _buildAnimatableCard(size: size, index: 1, color: secondary),
              _buildAnimatableCard(size: size, index: 0, color: primary),

              // Wallet Front
              Opacity(
                opacity: _walletFade.value,
                child: CustomPaint(
                  size: size,
                  painter: WalletFrontPainter(
                    openProgress: _walletOpen.value,
                    primaryColor: primary,
                    accentColor: secondary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAnimatableCard({
    required Size size,
    required int index,
    required Color color,
    bool isCash = false,
  }) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final w = size.width * 0.5;
    final h = size.height * 0.3;

    // State A: In Wallet (tucked inside)
    final double inWalletY = cy - h * 0.05 + (index * 15);
    final double inWalletWidth = w * 0.85;
    final double inWalletHeight = h * 0.55;

    // State B: Ejected (sliding out to display)
    final double ejectedY = cy - h * 0.75 + (index * 40);
    final double ejectedWidth = w * 0.95;
    final double ejectedHeight = h * 0.65;

    // State C: Dashboard (Full Screen layout)
    double dashY = 0;
    double dashWidth = size.width * 0.9;
    double dashHeight = 0;

    if (index == 0) { // Top Summary Card
      dashY = size.height * 0.20;
      dashHeight = size.height * 0.22;
    } else if (index == 1) { // Middle List
      dashY = size.height * 0.55;
      dashHeight = size.height * 0.40;
    } else { // Bottom Cash / Action
      dashY = size.height * 0.86;
      dashHeight = size.height * 0.08;
    }

    // Interpolate Positions & Sizes
    double currentY = inWalletY + (ejectedY - inWalletY) * _cardsEject.value;
    currentY = currentY + (dashY - currentY) * _dashboardTransform.value;

    double currentWidth = inWalletWidth + (ejectedWidth - inWalletWidth) * _cardsEject.value;
    currentWidth = currentWidth + (dashWidth - currentWidth) * _dashboardTransform.value;

    double currentHeight = inWalletHeight + (ejectedHeight - inWalletHeight) * _cardsEject.value;
    currentHeight = currentHeight + (dashHeight - currentHeight) * _dashboardTransform.value;

    // Slight rotation when ejecting, then snapping flat for dashboard
    double currentRotation = (0.08 * (1 - index)) * _cardsEject.value;
    currentRotation = currentRotation * (1.0 - _dashboardTransform.value);

    // Dashboard UI slowly fades in as the final transition starts
    double dashUiOpacity = _dashboardTransform.value;

    return Positioned(
      left: cx - currentWidth / 2,
      top: currentY - currentHeight / 2,
      child: Transform.rotate(
        angle: currentRotation,
        child: Container(
          width: currentWidth,
          height: currentHeight,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16 + 8 * (1 - _dashboardTransform.value)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3 * _cardsEject.value),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Stack(
            children: [
              // Shows cash design initially
              if (isCash)
                Opacity(
                  opacity: (1.0 - dashUiOpacity * 2).clamp(0.0, 1.0),
                  child: Center(
                    child: Text(
                      '\$',
                      style: TextStyle(
                        color: Colors.white.withOpacity(_cardsEject.value),
                        fontSize: 36 * _cardsEject.value,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              // Fades into Dashboard UI components
              if (dashUiOpacity > 0)
                Opacity(
                  opacity: dashUiOpacity,
                  child: _buildDashboardMockup(index, dashUiOpacity),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardMockup(int index, double opacity) {
    if (index == 0) { // Balance Summary Card
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 100, height: 14, color: Colors.white.withOpacity(0.5)),
            const SizedBox(height: 12),
            Container(width: 160, height: 32, color: Colors.white),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 80, height: 45, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12))),
                Container(width: 80, height: 45, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12))),
              ],
            )
          ],
        ),
      );
    } else if (index == 1) { // Transactions List
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: List.generate(3, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Row(
              children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.2))),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 120, height: 14, color: Colors.white.withOpacity(0.8)),
                    const SizedBox(height: 8),
                    Container(width: 80, height: 10, color: Colors.white.withOpacity(0.4)),
                  ],
                ),
                const Spacer(),
                Container(width: 50, height: 16, color: Colors.white),
              ],
            ),
          )),
        ),
      );
    } else { // New Transaction Button / Bottom Nav
      return const Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_rounded, color: Colors.white, size: 28),
            SizedBox(width: 12),
            Text("NEW ENTRY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 16)),
          ],
        ),
      );
    }
  }
}