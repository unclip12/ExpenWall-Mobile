import 'package:flutter/material.dart';
import 'dart:math';

class MoneyFlowAnimation extends StatefulWidget {
  final double amount;
  final bool isIncome;
  final VoidCallback onComplete;

  const MoneyFlowAnimation({
    super.key,
    required this.amount,
    required this.isIncome,
    required this.onComplete,
  });

  @override
  State<MoneyFlowAnimation> createState() => _MoneyFlowAnimationState();
}

class _MoneyFlowAnimationState extends State<MoneyFlowAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<MoneyParticle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Generate particles based on amount
    _particles = _generateParticles();

    _controller.forward().then((_) {
      widget.onComplete();
    });
  }

  List<MoneyParticle> _generateParticles() {
    int count;
    // Amount-based intensity
    if (widget.amount <= 100) {
      count = 8;
    } else if (widget.amount <= 1000) {
      count = 20;
    } else if (widget.amount <= 5000) {
      count = 40;
    } else if (widget.amount <= 10000) {
      count = 60;
    } else {
      count = 100;
    }

    return List.generate(count, (index) {
      return MoneyParticle(
        startX: 0.3 + _random.nextDouble() * 0.4, // Center area
        startY: widget.isIncome ? 0.0 : 0.5, // Top for income, center for expense
        endX: 0.1 + _random.nextDouble() * 0.8,
        endY: widget.isIncome ? 0.7 + _random.nextDouble() * 0.3 : 1.0 + _random.nextDouble() * 0.2,
        delay: _random.nextDouble() * 0.5,
        size: 20 + _random.nextDouble() * 15,
        rotation: _random.nextDouble() * 6.28,
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
          painter: MoneyFlowPainter(
            particles: _particles,
            progress: _controller.value,
            isIncome: widget.isIncome,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class MoneyParticle {
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final double delay;
  final double size;
  final double rotation;
  final String symbol;

  MoneyParticle({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.delay,
    required this.size,
    required this.rotation,
    required this.symbol,
  });
}

class MoneyFlowPainter extends CustomPainter {
  final List<MoneyParticle> particles;
  final double progress;
  final bool isIncome;

  MoneyFlowPainter({
    required this.particles,
    required this.progress,
    required this.isIncome,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      // Calculate particle progress with delay
      final particleProgress = ((progress - particle.delay) / (1 - particle.delay)).clamp(0.0, 1.0);
      
      if (particleProgress <= 0) continue;

      // Interpolate position
      final x = particle.startX + (particle.endX - particle.startX) * particleProgress;
      final y = particle.startY + (particle.endY - particle.startY) * particleProgress;

      // Calculate opacity (fade out at end)
      final opacity = particleProgress < 0.8 ? 1.0 : (1.0 - (particleProgress - 0.8) / 0.2);

      // Draw particle
      final textPainter = TextPainter(
        text: TextSpan(
          text: particle.symbol,
          style: TextStyle(
            fontSize: particle.size,
            color: isIncome
                ? Colors.green.withOpacity(opacity)
                : Colors.red.withOpacity(opacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.rotate(particle.rotation * particleProgress);
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(MoneyFlowPainter oldDelegate) => true;
}
