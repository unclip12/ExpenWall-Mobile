import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';
import '../theme/premium_themes.dart';

/// Liquid Glass Background with animated particles
/// Reacts to theme changes with smooth transitions
class LiquidBackground extends StatefulWidget {
  final Widget child;
  final PremiumTheme theme;

  const LiquidBackground({
    super.key,
    required this.child,
    required this.theme,
  });

  @override
  State<LiquidBackground> createState() => _LiquidBackgroundState();
}

class _LiquidBackgroundState extends State<LiquidBackground>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _gradientController;
  late List<Particle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _gradientController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _particles = _generateParticles();
  }

  @override
  void didUpdateWidget(LiquidBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.theme.id != widget.theme.id) {
      // Regenerate particles with new theme colors
      setState(() {
        _particles = _generateParticles();
      });
    }
  }

  List<Particle> _generateParticles() {
    return List.generate(widget.theme.isDark ? 30 : 20, (index) {
      return Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 40 + _random.nextDouble() * 120,
        speedX: (_random.nextDouble() - 0.5) * 0.3,
        speedY: (_random.nextDouble() - 0.5) * 0.3,
        color: widget.theme.gradientColors[
            _random.nextInt(widget.theme.gradientColors.length)],
        opacity: widget.theme.isDark ? 0.15 : 0.25,
      );
    });
  }

  @override
  void dispose() {
    _particleController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Animated Gradient Background
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _gradientController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.theme.backgroundGradient,
                    stops: [
                      0.0,
                      0.5 + (_gradientController.value * 0.3),
                      1.0,
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Animated Particles
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlePainter(
                  particles: _particles,
                  progress: _particleController.value,
                ),
              );
            },
          ),
        ),

        // Frosted Glass Overlay
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    widget.theme.backgroundColor.withOpacity(0.3),
                    widget.theme.backgroundColor.withOpacity(0.5),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Content
        widget.child,
      ],
    );
  }
}

class Particle {
  double x;
  double y;
  final double size;
  final double speedX;
  final double speedY;
  final Color color;
  final double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.color,
    required this.opacity,
  });

  void update() {
    x += speedX * 0.001;
    y += speedY * 0.001;

    // Wrap around edges
    if (x < -0.2) x = 1.2;
    if (x > 1.2) x = -0.2;
    if (y < -0.2) y = 1.2;
    if (y > 1.2) y = -0.2;
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  ParticlePainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      particle.update();

      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);

      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

/// Milky Glass Card - Apple-style translucent card
class MilkyGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? borderRadius;
  final Color? color;

  const MilkyGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius ?? 24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius ?? 24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color ??
                  (isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.white.withOpacity(0.6)),
              borderRadius: BorderRadius.circular(borderRadius ?? 24),
              border: Border.all(
                color: Colors.white.withOpacity(isDark ? 0.1 : 0.3),
                width: 1.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(isDark ? 0.1 : 0.4),
                  Colors.white.withOpacity(isDark ? 0.05 : 0.2),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
