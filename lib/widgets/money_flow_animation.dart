import 'package:flutter/material.dart';
import 'dart:math';
import '../utils/indian_currency_formatter.dart';

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
  late Animation<double> _amountSlideAnimation;
  late Animation<double> _amountOpacityAnimation;
  late List<MoneyParticle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    
    // Main animation controller (4 seconds for particles)
    _controller = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    // Amount display animation controller (4 seconds total)
    _amountController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    // Slide animation for amount (from top, moves down)
    _amountSlideAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.1, end: 0.25)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.25, end: 0.25),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.25, end: 0.4)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 20,
      ),
    ]).animate(_amountController);

    // Opacity animation for amount
    _amountOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
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
      count = 15;
    } else if (widget.amount <= 500) {
      count = 30;
    } else if (widget.amount <= 1000) {
      count = 50;
    } else if (widget.amount <= 5000) {
      count = 70;
    } else if (widget.amount <= 10000) {
      count = 100;
    } else {
      count = 150;
    }

    return List.generate(count, (index) {
      return MoneyParticle(
        startX: 0.2 + _random.nextDouble() * 0.6, // Spread across screen
        startY: 0.0, // Always start from top
        endX: 0.1 + _random.nextDouble() * 0.8,
        endY: 1.0 + _random.nextDouble() * 0.3, // Flow downward past screen
        delay: _random.nextDouble() * 0.3,
        size: 16 + _random.nextDouble() * 20,
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
        // Colored tint background
        AnimatedBuilder(
          animation: _amountController,
          builder: (context, child) {
            return Container(
              color: widget.isIncome
                  ? const Color(0xFF10B981).withOpacity(0.15 * _amountOpacityAnimation.value)
                  : const Color(0xFFEF4444).withOpacity(0.15 * _amountOpacityAnimation.value),
            );
          },
        ),

        // Particles flowing down
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

        // Large amount display from top
        AnimatedBuilder(
          animation: _amountController,
          builder: (context, child) {
            return Positioned(
              top: MediaQuery.of(context).size.height * _amountSlideAnimation.value,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: _amountOpacityAnimation.value,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.isIncome
                          ? [
                              const Color(0xFF10B981).withOpacity(0.95),
                              const Color(0xFF059669).withOpacity(0.95),
                            ]
                          : [
                              const Color(0xFFEF4444).withOpacity(0.95),
                              const Color(0xFFDC2626).withOpacity(0.95),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: widget.isIncome
                            ? const Color(0xFF10B981).withOpacity(0.5)
                            : const Color(0xFFEF4444).withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.isIncome ? 'Received' : 'Spent',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.isIncome ? '+' : '-'}${IndianCurrencyFormatter.format(widget.amount)}',
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
      final easedProgress = Curves.easeInOut.transform(particleProgress);
      final x = particle.startX + (particle.endX - particle.startX) * easedProgress;
      final y = particle.startY + (particle.endY - particle.startY) * easedProgress;

      // Calculate opacity (fade in, stay, fade out)
      final opacity = particleProgress < 0.2
          ? particleProgress / 0.2
          : (particleProgress < 0.8
              ? 1.0
              : 1.0 - (particleProgress - 0.8) / 0.2);

      // Calculate scale (start small, grow, maintain)
      final scale = particleProgress < 0.3
          ? particleProgress / 0.3
          : 1.0;

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
