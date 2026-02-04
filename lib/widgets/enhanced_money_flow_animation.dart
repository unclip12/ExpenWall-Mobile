import 'package:flutter/material.dart';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';

/// Enhanced Money Flow Animation with Amount Display
class EnhancedMoneyFlowAnimation extends StatefulWidget {
  final double amount;
  final bool isIncome;
  final VoidCallback onComplete;

  const EnhancedMoneyFlowAnimation({
    super.key,
    required this.amount,
    required this.isIncome,
    required this.onComplete,
  });

  @override
  State<EnhancedMoneyFlowAnimation> createState() =>
      _EnhancedMoneyFlowAnimationState();
}

class _EnhancedMoneyFlowAnimationState
    extends State<EnhancedMoneyFlowAnimation>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _amountController;
  late Animation<double> _amountFade;
  late Animation<Offset> _amountSlide;
  late List<MoneyParticle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Particle animation (2 seconds)
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Amount animation (1.5 seconds)
    _amountController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _amountFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _amountController,
        curve: Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _amountSlide = Tween<Offset>(
      begin: Offset(0, 0.2),
      end: Offset(0, -0.5),
    ).animate(
      CurvedAnimation(
        parent: _amountController,
        curve: Curves.easeOut,
      ),
    );

    // Generate particles based on amount
    _particles = _generateParticles();

    // Start animations
    _particleController.forward();
    _amountController.forward();

    // Complete callback
    _particleController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
  }

  List<MoneyParticle> _generateParticles() {
    int count;
    // Amount-based particle count
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
        startX: 0.3 + _random.nextDouble() * 0.4,
        startY: widget.isIncome ? 0.0 : 0.45,
        endX: 0.1 + _random.nextDouble() * 0.8,
        endY: widget.isIncome
            ? 0.7 + _random.nextDouble() * 0.3
            : 1.0 + _random.nextDouble() * 0.2,
        delay: _random.nextDouble() * 0.4,
        size: 18 + _random.nextDouble() * 16,
        rotation: _random.nextDouble() * 6.28,
        symbol: _getRandomSymbol(),
      );
    });
  }

  String _getRandomSymbol() {
    final symbols = ['₹', '💰', '💵', '💸', '✨'];
    return symbols[_random.nextInt(symbols.length)];
  }

  @override
  void dispose() {
    _particleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Particle animation
        AnimatedBuilder(
          animation: _particleController,
          builder: (context, child) {
            return CustomPaint(
              painter: MoneyFlowPainter(
                particles: _particles,
                progress: _particleController.value,
                isIncome: widget.isIncome,
              ),
              size: Size.infinite,
            );
          },
        ),

        // Amount display
        Center(
          child: AnimatedBuilder(
            animation: _amountController,
            builder: (context, child) {
              return SlideTransition(
                position: _amountSlide,
                child: FadeTransition(
                  opacity: _amountFade,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.isIncome
                            ? [
                                Colors.green.withOpacity(0.9),
                                Colors.green.shade700.withOpacity(0.9),
                              ]
                            : [
                                Colors.red.withOpacity(0.9),
                                Colors.red.shade700.withOpacity(0.9),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.isIncome
                                  ? Colors.green
                                  : Colors.red)
                              .withOpacity(0.4),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.isIncome
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${widget.isIncome ? "+" : "-"}₹${widget.amount.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
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
      final x =
          particle.startX + (particle.endX - particle.startX) * easedProgress;
      final y =
          particle.startY + (particle.endY - particle.startY) * easedProgress;

      // Calculate opacity (fade in then fade out)
      double opacity;
      if (particleProgress < 0.2) {
        opacity = particleProgress / 0.2;
      } else if (particleProgress < 0.8) {
        opacity = 1.0;
      } else {
        opacity = 1.0 - (particleProgress - 0.8) / 0.2;
      }

      // Scale effect (start small, grow, then shrink)
      double scale;
      if (particleProgress < 0.3) {
        scale = particleProgress / 0.3;
      } else if (particleProgress < 0.7) {
        scale = 1.0;
      } else {
        scale = 1.0 - (particleProgress - 0.7) / 0.3 * 0.5;
      }

      // Draw particle
      final textPainter = TextPainter(
        text: TextSpan(
          text: particle.symbol,
          style: TextStyle(
            fontSize: particle.size * scale,
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
