import 'package:flutter/material.dart';
import 'dart:math';

class AnimatedGradientBackground extends StatefulWidget {
  final List<Color> colors;
  final Widget child;

  const AnimatedGradientBackground({
    super.key,
    required this.colors,
    required this.child,
  });

  @override
  State<AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 8),
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
    return Stack(
      children: [
        // Animated gradient background
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.colors,
                  stops: [
                    0.0,
                    0.3 + (sin(_controller.value * 2 * pi) * 0.1),
                    0.7 + (cos(_controller.value * 2 * pi) * 0.1),
                    1.0,
                  ],
                ),
              ),
            );
          },
        ),
        // Floating currency symbols
        const FloatingCurrencySymbols(),
        // Child content
        widget.child,
      ],
    );
  }
}

class FloatingCurrencySymbols extends StatefulWidget {
  const FloatingCurrencySymbols({super.key});

  @override
  State<FloatingCurrencySymbols> createState() => _FloatingCurrencySymbolsState();
}

class _FloatingCurrencySymbolsState extends State<FloatingCurrencySymbols>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<CurrencyParticle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    // Generate floating particles
    _particles = List.generate(15, (index) {
      return CurrencyParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: 0.01 + _random.nextDouble() * 0.02,
        size: 20 + _random.nextDouble() * 30,
        opacity: 0.03 + _random.nextDouble() * 0.05,
        symbol: _random.nextBool() ? '₹' : '💰',
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: CurrencyPainter(
            particles: _particles,
            progress: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class CurrencyParticle {
  final double x;
  final double y;
  final double speed;
  final double size;
  final double opacity;
  final String symbol;

  CurrencyParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
    required this.symbol,
  });
}

class CurrencyPainter extends CustomPainter {
  final List<CurrencyParticle> particles;
  final double progress;

  CurrencyPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      // Calculate floating position
      final yPos = ((particle.y + (progress * particle.speed)) % 1.0) * size.height;
      final xOffset = sin(progress * 3.14 * 2 + particle.x * 10) * 20;
      final xPos = particle.x * size.width + xOffset;

      // Draw symbol
      final textPainter = TextPainter(
        text: TextSpan(
          text: particle.symbol,
          style: TextStyle(
            fontSize: particle.size,
            color: Colors.white.withOpacity(particle.opacity),
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(xPos - textPainter.width / 2, yPos),
      );
    }
  }

  @override
  bool shouldRepaint(CurrencyPainter oldDelegate) => true;
}

// Smart text color helper
class SmartText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color backgroundColor;

  const SmartText(
    this.text, {
    super.key,
    this.style,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate luminance to determine if background is light or dark
    final luminance = backgroundColor.computeLuminance();
    final textColor = luminance > 0.5 ? Colors.black : Colors.white;

    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(color: textColor),
    );
  }
}
