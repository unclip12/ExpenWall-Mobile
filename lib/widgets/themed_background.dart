import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';
import '../theme/theme_config.dart';

/// Animated background that changes based on theme
class ThemedBackground extends StatefulWidget {
  final Widget child;
  final BackgroundConfig config;
  final bool isDark;

  const ThemedBackground({
    super.key,
    required this.child,
    required this.config,
    required this.isDark,
  });

  @override
  State<ThemedBackground> createState() => _ThemedBackgroundState();
}

class _ThemedBackgroundState extends State<ThemedBackground>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _particleController;
  late List<Particle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    
    // Gradient animation (slow, subtle)
    _gradientController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    // Particle animation
    _particleController = AnimationController(
      duration: Duration(
        seconds: (20 / widget.config.animationSpeed).round(),
      ),
      vsync: this,
    )..repeat();

    _generateParticles();
  }

  @override
  void didUpdateWidget(ThemedBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config || oldWidget.isDark != widget.isDark) {
      _generateParticles();
      _particleController.duration = Duration(
        seconds: (20 / widget.config.animationSpeed).round(),
      );
    }
  }

  void _generateParticles() {
    final particleCount = (30 * widget.config.particleDensity).round();
    _particles = List.generate(particleCount, (index) {
      // FIXED: Reduce opacity in light mode
      final baseOpacity = 0.1 + _random.nextDouble() * 0.3;
      final adjustedOpacity = widget.isDark ? baseOpacity : baseOpacity * 0.3;
      
      return Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 4 + _random.nextDouble() * 12,
        speed: 0.1 + _random.nextDouble() * 0.3,
        angle: _random.nextDouble() * 2 * pi,
        opacity: adjustedOpacity,
        color: widget.config.particleColors[
          _random.nextInt(widget.config.particleColors.length)
        ],
        type: widget.config.particleType,
        rotationSpeed: -0.5 + _random.nextDouble(),
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
                  colors: widget.config.gradientColors,
                  stops: [
                    0.0,
                    0.3 + (_gradientController.value * 0.2),
                    0.7 + (_gradientController.value * 0.3),
                  ],
                ),
              ),
            );
          },
        ),

        // Particles
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

        // Blur overlay for glass effect
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Container(
            color: widget.isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.white.withOpacity(0.3),
          ),
        ),

        // Content
        widget.child,
      ],
    );
  }
}

class Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double angle;
  final double opacity;
  final Color color;
  final ParticleType type;
  final double rotationSpeed;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.angle,
    required this.opacity,
    required this.color,
    required this.type,
    required this.rotationSpeed,
  });
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
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;

      // Calculate position with movement
      final x = (particle.x + (cos(particle.angle) * progress * particle.speed)) % 1.0;
      final y = (particle.y + (sin(particle.angle) * progress * particle.speed)) % 1.0;
      final position = Offset(x * size.width, y * size.height);

      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(progress * particle.rotationSpeed * 2 * pi);

      _drawParticle(canvas, particle, paint);

      canvas.restore();
    }
  }

  void _drawParticle(Canvas canvas, Particle particle, Paint paint) {
    switch (particle.type) {
      case ParticleType.currency:
        _drawCurrency(canvas, particle, paint);
        break;
      case ParticleType.geometric:
        _drawGeometric(canvas, particle, paint);
        break;
      case ParticleType.floral:
        _drawFloral(canvas, particle, paint);
        break;
      case ParticleType.cosmic:
        _drawCosmic(canvas, particle, paint);
        break;
      case ParticleType.aquatic:
        _drawAquatic(canvas, particle, paint);
        break;
      case ParticleType.minimal:
        _drawMinimal(canvas, particle, paint);
        break;
    }
  }

  void _drawCurrency(Canvas canvas, Particle particle, Paint paint) {
    // Draw rupee symbol
    final textPainter = TextPainter(
      text: TextSpan(
        text: '₹',
        style: TextStyle(
          fontSize: particle.size,
          color: paint.color,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
  }

  void _drawGeometric(Canvas canvas, Particle particle, Paint paint) {
    // Draw circle or triangle
    if (particle.size > 8) {
      // Triangle
      final path = Path();
      path.moveTo(0, -particle.size / 2);
      path.lineTo(particle.size / 2, particle.size / 2);
      path.lineTo(-particle.size / 2, particle.size / 2);
      path.close();
      canvas.drawPath(path, paint);
    } else {
      // Circle
      canvas.drawCircle(Offset.zero, particle.size / 2, paint);
    }
  }

  void _drawFloral(Canvas canvas, Particle particle, Paint paint) {
    // Draw flower petal shape
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * pi / 5);
      final x = cos(angle) * particle.size / 2;
      final y = sin(angle) * particle.size / 2;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawCosmic(Canvas canvas, Particle particle, Paint paint) {
    // Draw star
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = (i * 2 * pi / 10);
      final radius = (i.isEven ? particle.size / 2 : particle.size / 4);
      final x = cos(angle) * radius;
      final y = sin(angle) * radius;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawAquatic(Canvas canvas, Particle particle, Paint paint) {
    // Draw bubble (circle with gradient)
    final gradient = RadialGradient(
      colors: [
        paint.color.withOpacity(paint.color.opacity * 0.3),
        paint.color,
      ],
    );
    final gradientPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: Offset.zero, radius: particle.size / 2),
      );
    canvas.drawCircle(Offset.zero, particle.size / 2, gradientPaint);
  }

  void _drawMinimal(Canvas canvas, Particle particle, Paint paint) {
    // Simple dots
    canvas.drawCircle(Offset.zero, particle.size / 3, paint);
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}
