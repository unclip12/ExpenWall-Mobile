import 'package:flutter/material.dart';
import 'dart:math';

class MoneyFlowAnimation extends StatefulWidget {
  final double amount;
  final bool isIncome; // true = money coming in, false = money going out
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

    _initializeParticles();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });

    _controller.forward();
  }

  void _initializeParticles() {
    // Calculate number of particles based on amount
    int particleCount;
    if (widget.amount < 100) {
      particleCount = 8;
    } else if (widget.amount < 1000) {
      particleCount = 20;
    } else if (widget.amount < 5000) {
      particleCount = 40;
    } else if (widget.amount < 10000) {
      particleCount = 60;
    } else {
      particleCount = 100;
    }

    _particles = List.generate(particleCount, (index) {
      return MoneyParticle(
        startX: _random.nextDouble(),
        startY: widget.isIncome ? 0.0 : 0.5, // Income from top, Expense from middle
        speedX: (_random.nextDouble() - 0.5) * 0.3,
        speedY: widget.isIncome ? 0.5 + _random.nextDouble() * 0.3 : 0.3 + _random.nextDouble() * 0.4,
        size: 12 + _random.nextDouble() * 8,
        rotation: _random.nextDouble() * 360,
        rotationSpeed: (_random.nextDouble() - 0.5) * 180,
        symbol: _random.nextBool() ? '₹' : '💵', // Rupee symbol or money emoji
        delay: _random.nextDouble() * 0.3,
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
  final double speedX;
  final double speedY;
  final double size;
  final double rotation;
  final double rotationSpeed;
  final String symbol;
  final double delay;

  MoneyParticle({
    required this.startX,
    required this.startY,
    required this.speedX,
    required this.speedY,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.symbol,
    required this.delay,
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
      // Calculate progress with delay
      final particleProgress = ((progress - particle.delay) / (1 - particle.delay)).clamp(0.0, 1.0);

      if (particleProgress <= 0) continue;

      // Calculate position
      final x = size.width * (particle.startX + particle.speedX * particleProgress);
      final y = size.height * (particle.startY + particle.speedY * particleProgress);

      // Calculate opacity (fade in and fade out)
      double opacity;
      if (particleProgress < 0.2) {
        opacity = particleProgress / 0.2;
      } else if (particleProgress > 0.8) {
        opacity = (1 - particleProgress) / 0.2;
      } else {
        opacity = 1.0;
      }

      // Calculate rotation
      final currentRotation = particle.rotation + particle.rotationSpeed * particleProgress;

      // Draw particle
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(currentRotation * 3.14159 / 180);

      final textPainter = TextPainter(
        text: TextSpan(
          text: particle.symbol,
          style: TextStyle(
            fontSize: particle.size,
            color: (isIncome ? Colors.green : Colors.red).withOpacity(opacity),
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3 * opacity),
                blurRadius: 4,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(MoneyFlowPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
