import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../home/home_screen.dart';

/// Premium animated splash screen with cosmic design
class WalletSplashScreen extends StatefulWidget {
  const WalletSplashScreen({Key? key}) : super(key: key);

  @override
  State<WalletSplashScreen> createState() => _WalletSplashScreenState();
}

class _WalletSplashScreenState extends State<WalletSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _particleController;
  late AnimationController _ringController;
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;
  late AnimationController _exitController;

  late Animation<double> _bgFade;
  late Animation<double> _ringRotation;
  late Animation<double> _logoScale;
  late Animation<double> _logoGlow;
  late Animation<double> _textFade;
  late Animation<double> _textSlide;
  late Animation<double> _taglineFade;
  late Animation<double> _progressValue;
  late Animation<double> _exitFade;
  late Animation<double> _exitScale;

  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _generateParticles();
    _setupAnimations();
    _startSequence();
  }

  void _generateParticles() {
    for (int i = 0; i < 40; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 2.2 + 0.6,
        opacity: _random.nextDouble() * 0.5 + 0.15,
        phaseOffset: _random.nextDouble() * 2 * pi,
      ));
    }
  }

  void _setupAnimations() {
    // Background fade in
    _bgController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _bgFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeOut),
    );

    // Particle twinkling
    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Ring rotation (continuous)
    _ringController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();
    _ringRotation = Tween<double>(begin: 0.0, end: 2 * pi).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.linear),
    );

    // Logo spring pop-in
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    // Text slide-up reveal
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _textSlide = Tween<double>(begin: 28.0, end: 0.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    // Thin glowing progress bar
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _progressValue = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // Exit: scale up + fade out
    _exitController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );
    _exitScale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );
  }

  void _startSequence() async {
    HapticFeedback.lightImpact();
    _bgController.forward();

    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    _logoController.forward();
    HapticFeedback.mediumImpact();

    await Future.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;
    _textController.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _progressController.forward();

    await Future.delayed(const Duration(milliseconds: 1700));
    if (!mounted) return;
    HapticFeedback.selectionClick();
    _exitController.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _bgController.dispose();
    _particleController.dispose();
    _ringController.dispose();
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _bgController,
          _particleController,
          _ringController,
          _logoController,
          _textController,
          _progressController,
          _exitController,
        ]),
        builder: (context, _) {
          return Opacity(
            opacity: _exitFade.value,
            child: Transform.scale(
              scale: _exitScale.value,
              child: Container(
                width: size.width,
                height: size.height,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF07071A),
                      Color(0xFF0F0F2E),
                      Color(0xFF07071A),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    // --- Twinkling star particles ---
                    ..._particles.asMap().entries.map((e) {
                      final p = e.value;
                      final t = _particleController.value;
                      final twinkle = (sin(t * 2 * pi + p.phaseOffset) + 1) / 2;
                      return Positioned(
                        left: p.x * size.width,
                        top: p.y * size.height,
                        child: Opacity(
                          opacity: p.opacity * twinkle * _bgFade.value,
                          child: Container(
                            width: p.size,
                            height: p.size,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withOpacity(0.6),
                                  blurRadius: p.size * 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    // --- Radial glow bloom ---
                    Positioned.fill(
                      child: Opacity(
                        opacity: _bgFade.value * 0.6,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.center,
                              radius: 0.65,
                              colors: [
                                primary.withOpacity(0.22),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // --- Centre: logo + rings + text ---
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo with dual rotating rings
                          Transform.scale(
                            scale: _logoScale.value,
                            child: SizedBox(
                              width: 160,
                              height: 160,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Outer sweep-gradient ring (clockwise)
                                  Transform.rotate(
                                    angle: _ringRotation.value,
                                    child: CustomPaint(
                                      size: const Size(160, 160),
                                      painter: _SweepRingPainter(
                                        primaryColor: primary,
                                        secondaryColor: secondary,
                                        intensity: _logoGlow.value,
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                  ),
                                  // Inner dashed ring (counter-clockwise)
                                  Transform.rotate(
                                    angle: -_ringRotation.value * 0.6,
                                    child: CustomPaint(
                                      size: const Size(116, 116),
                                      painter: _DashedRingPainter(
                                        color: secondary,
                                        intensity: _logoGlow.value * 0.55,
                                      ),
                                    ),
                                  ),
                                  // Glowing logo circle
                                  Container(
                                    width: 84,
                                    height: 84,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          primary,
                                          Color.lerp(primary, secondary, 0.55)!,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primary.withOpacity(
                                              _logoGlow.value * 0.75),
                                          blurRadius: 38 * _logoGlow.value,
                                          spreadRadius: 7 * _logoGlow.value,
                                        ),
                                        BoxShadow(
                                          color: secondary.withOpacity(
                                              _logoGlow.value * 0.35),
                                          blurRadius: 60 * _logoGlow.value,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.account_balance_wallet_rounded,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 38),

                          // App name — shimmer gradient
                          Transform.translate(
                            offset: Offset(0, _textSlide.value),
                            child: Opacity(
                              opacity: _textFade.value,
                              child: ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.95),
                                    primary.withOpacity(0.9),
                                    Colors.white.withOpacity(0.95),
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ).createShader(bounds),
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

                          const SizedBox(height: 10),

                          // Tagline — spaced uppercase
                          Transform.translate(
                            offset: Offset(0, _textSlide.value * 0.5),
                            child: Opacity(
                              opacity: _textFade.value * _taglineFade.value,
                              child: Text(
                                'SMART EXPENSE TRACKING',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white.withOpacity(0.42),
                                  letterSpacing: 3.8,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- Thin glowing progress line ---
                    Positioned(
                      bottom: 68,
                      left: 52,
                      right: 52,
                      child: Opacity(
                        opacity: (_textFade.value * 0.95).clamp(0.0, 1.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: Container(
                            height: 2,
                            color: Colors.white.withOpacity(0.08),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _progressValue.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [primary, secondary],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primary.withOpacity(0.75),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Data class for a single star particle ───────────────────────────────────
class _Particle {
  final double x;
  final double y;
  final double size;
  final double opacity;
  final double phaseOffset;

  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.phaseOffset,
  });
}

// ─── Outer sweep-gradient rotating ring ──────────────────────────────────────
class _SweepRingPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final double intensity;
  final double strokeWidth;

  const _SweepRingPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.intensity,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth;

    // Soft glow halo
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 8
      ..color = primaryColor.withOpacity(0.1 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    canvas.drawCircle(center, radius, glowPaint);

    // Sweep arc
    final sweepShader = SweepGradient(
      colors: [
        Colors.transparent,
        primaryColor.withOpacity(0.25 * intensity),
        secondaryColor.withOpacity(0.9 * intensity),
        primaryColor.withOpacity(0.85 * intensity),
        Colors.transparent,
      ],
      stops: const [0.0, 0.1, 0.5, 0.9, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = sweepShader
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * pi,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_SweepRingPainter old) => old.intensity != intensity;
}

// ─── Inner dashed counter-rotating ring ──────────────────────────────────────
class _DashedRingPainter extends CustomPainter {
  final Color color;
  final double intensity;

  const _DashedRingPainter({required this.color, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = color.withOpacity(0.5 * intensity)
      ..strokeCap = StrokeCap.round;

    const dashCount = 18;
    const gapRatio = 0.38;
    final dashAngle = (2 * pi) / dashCount;
    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * dashAngle,
        dashAngle * (1 - gapRatio),
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter old) => old.intensity != intensity;
}
