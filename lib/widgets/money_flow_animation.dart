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
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _amountController;
  late Animation<double> _amountScaleAnimation;
  late Animation<double> _amountOpacityAnimation;
  late List<MoneyParticle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    
    // Main animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Amount display animation controller
    _amountController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Scale animation for amount (pop in effect)
    _amountScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInBack)),
        weight: 20,
      ),
    ]).animate(_amountController);

    // Opacity animation for amount
    _amountOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_amountController);

    // Generate particles based on amount
    _particles = _generateParticles();

    // Start animations
    _controller.forward().then((_) {
      widget.onComplete();
    });
    _amountController.forward();
  }

  List<MoneyParticle> _generateParticles() {
    int count;
    // Amount-based intensity
    if (widget.amount <= 100) {
      count = 12;
    } else if (widget.amount <= 500) {
      count = 25;
    } else if (widget.amount <= 1000) {
      count = 40;
    } else if (widget.amount <= 5000) {
      count = 60;
    } else if (widget.amount <= 10000) {
      count = 80;
    } else {
      count = 120;
    }

    return List.generate(count, (index) {
      return MoneyParticle(
        startX: 0.3 + _random.nextDouble() * 0.4, // Center area
        startY: widget.isIncome ? 0.0 : 0.5, // Top for income, center for expense
        endX: 0.1 + _random.nextDouble() * 0.8,
        endY: widget.isIncome
            ? 0.7 + _random.nextDouble() * 0.3
            : 1.0 + _random.nextDouble() * 0.2,
        delay: _random.nextDouble() * 0.5,
        size: 18 + _random.nextDouble() * 18,
        rotation: _random.nextDouble() * 6.28,
        symbol: _getRandomSymbol(),
      );
    });
  }

  String _getRandomSymbol() {
    final symbols = ['₹', '💸', '💵', '💰', '✨', '💎'];
    return symbols[_random.nextInt(symbols.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Particles
        AnimatedBuilder(
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
        ),

        // Large amount display
        Center(
          child: AnimatedBuilder(
            animation: _amountController,
            builder: (context, child) {
              return Transform.scale(
                scale: _amountScaleAnimation.value,
                child: Opacity(
                  opacity: _amountOpacityAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.isIncome
                            ? [
                                const Color(0xFF10B981).withOpacity(0.9),
                                const Color(0xFF059669).withOpacity(0.9),
                              ]
                            : [
                                const Color(0xFFEF4444).withOpacity(0.9),
                                const Color(0xFFDC2626).withOpacity(0.9),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: widget.isIncome
                              ? const Color(0xFF10B981).withOpacity(0.4)
                              : const Color(0xFFEF4444).withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.isIncome ? '+' : '-',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${widget.amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
      final particleProgress =
          ((progress - particle.delay) / (1 - particle.delay)).clamp(0.0, 1.0);

      if (particleProgress <= 0) continue;

      // Interpolate position with easing
      final easedProgress = Curves.easeOut.transform(particleProgress);
      final x = particle.startX + (particle.endX - particle.startX) * easedProgress;
      final y = particle.startY + (particle.endY - particle.startY) * easedProgress;

      // Calculate opacity (fade out at end)
      final opacity = particleProgress < 0.7
          ? 1.0
          : (1.0 - (particleProgress - 0.7) / 0.3);

      // Calculate scale (start small, grow, then shrink)
      final scale = particleProgress < 0.3
          ? particleProgress / 0.3
          : (particleProgress < 0.7
              ? 1.0
              : 1.0 - (particleProgress - 0.7) / 0.3);

      // Draw particle
      final textPainter = TextPainter(
        text: TextSpan(
          text: particle.symbol,
          style: TextStyle(
            fontSize: particle.size * scale,
            color: isIncome
                ? Color.lerp(
                    const Color(0xFF10B981),
                    const Color(0xFF34D399),
                    particleProgress,
                  )!.withOpacity(opacity * 0.9)
                : Color.lerp(
                    const Color(0xFFEF4444),
                    const Color(0xFFFCA5A5),
                    particleProgress,
                  )!.withOpacity(opacity * 0.9),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.rotate(particle.rotation * particleProgress);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(MoneyFlowPainter oldDelegate) => true;
}
