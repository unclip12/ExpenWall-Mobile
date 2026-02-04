import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';

/// Premium Animated Background that reacts to theme changes
class PremiumAnimatedBackground extends StatefulWidget {
  final Widget child;
  final List<Color> colors;
  final bool showParticles;

  const PremiumAnimatedBackground({
    super.key,
    required this.child,
    required this.colors,
    this.showParticles = true,
  });

  @override
  State<PremiumAnimatedBackground> createState() =>
      _PremiumAnimatedBackgroundState();
}

class _PremiumAnimatedBackgroundState
    extends State<PremiumAnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _particleController;
  late List<FloatingParticle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Gradient animation (slow, infinite)
    _gradientController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);

    // Particle animation (medium speed, infinite)
    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _particles = _generateParticles();
  }

  @override
  void didUpdateWidget(PremiumAnimatedBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Regenerate particles when colors change
    if (oldWidget.colors != widget.colors) {
      setState(() {
        _particles = _generateParticles();
      });
    }
  }

  List<FloatingParticle> _generateParticles() {
    return List.generate(20, (index) {
      return FloatingParticle(
        startX: _random.nextDouble(),
        startY: _random.nextDouble(),
        endX: _random.nextDouble(),
        endY: _random.nextDouble(),
        size: 50 + _random.nextDouble() * 150,
        delay: _random.nextDouble(),
        color: widget.colors[_random.nextInt(widget.colors.length)]
            .withOpacity(0.05 + _random.nextDouble() * 0.1),
      );
    });
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Animated gradient background
        AnimatedBuilder(
          animation: _gradientController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.colors,
                  stops: [
                    0.0,
                    0.3 + _gradientController.value * 0.2,
                    0.7 + _gradientController.value * 0.2,
                  ],
                ),
              ),
            );
          },
        ),

        // Floating particles
        if (widget.showParticles)
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlePainter(
                  particles: _particles,
                  progress: _particleController.value,
                ),
                size: Size.infinite,
              );
            },
          ),

        // Mesh gradient overlay (for depth)
        Positioned.fill(
          child: CustomPaint(
            painter: MeshGradientPainter(
              colors: widget.colors,
            ),
          ),
        ),

        // Content
        widget.child,
      ],
    );
  }
}

class FloatingParticle {
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final double size;
  final double delay;
  final Color color;

  FloatingParticle({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.size,
    required this.delay,
    required this.color,
  });
}

class ParticlePainter extends CustomPainter {
  final List<FloatingParticle> particles;
  final double progress;

  ParticlePainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      // Calculate particle progress with delay
      final particleProgress =
          ((progress - particle.delay) % 1.0).clamp(0.0, 1.0);

      // Interpolate position with easing
      final easedProgress = Curves.easeInOut.transform(particleProgress);
      final x =
          particle.startX + (particle.endX - particle.startX) * easedProgress;
      final y =
          particle.startY + (particle.endY - particle.startY) * easedProgress;

      // Calculate opacity (fade in and out)
      double opacity;
      if (particleProgress < 0.3) {
        opacity = particleProgress / 0.3;
      } else if (particleProgress < 0.7) {
        opacity = 1.0;
      } else {
        opacity = 1.0 - (particleProgress - 0.7) / 0.3;
      }

      // Draw particle as circle
      final paint = Paint()
        ..color = particle.color.withOpacity(opacity * particle.color.opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, particle.size * 0.3);

      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

class MeshGradientPainter extends CustomPainter {
  final List<Color> colors;

  MeshGradientPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    // Create subtle mesh gradient overlay
    final paint = Paint()..style = PaintingStyle.fill;

    // Top-left gradient spot
    paint.shader = RadialGradient(
      colors: [
        colors[0].withOpacity(0.15),
        colors[0].withOpacity(0.0),
      ],
    ).createShader(
      Rect.fromCircle(
        center: Offset(size.width * 0.2, size.height * 0.2),
        radius: size.width * 0.5,
      ),
    );
    canvas.drawRect(Offset.zero & size, paint);

    // Bottom-right gradient spot
    paint.shader = RadialGradient(
      colors: [
        colors[colors.length - 1].withOpacity(0.15),
        colors[colors.length - 1].withOpacity(0.0),
      ],
    ).createShader(
      Rect.fromCircle(
        center: Offset(size.width * 0.8, size.height * 0.8),
        radius: size.width * 0.5,
      ),
    );
    canvas.drawRect(Offset.zero & size, paint);

    // Center gradient spot
    if (colors.length > 2) {
      paint.shader = RadialGradient(
        colors: [
          colors[1].withOpacity(0.1),
          colors[1].withOpacity(0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.5),
          radius: size.width * 0.4,
        ),
      );
      canvas.drawRect(Offset.zero & size, paint);
    }
  }

  @override
  bool shouldRepaint(MeshGradientPainter oldDelegate) {
    return colors != oldDelegate.colors;
  }
}

/// Liquid Glass Container Widget
class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final double blur;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 24,
    this.backgroundColor,
    this.blur = 10,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.white.withOpacity(0.6);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor ?? defaultBg,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.5),
                width: 1.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withOpacity(0.05),
                        Colors.white.withOpacity(0.02),
                      ]
                    : [
                        Colors.white.withOpacity(0.7),
                        Colors.white.withOpacity(0.3),
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
