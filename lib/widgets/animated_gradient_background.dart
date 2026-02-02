import 'package:flutter/material.dart';
import 'dart:math';

class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  final List<Color> colors;

  const AnimatedGradientBackground({
    super.key,
    required this.child,
    required this.colors,
  });

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState
    extends State<AnimatedGradientBackground>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _symbolController;
  late List<FloatingSymbol> _symbols;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Wave animation
    _waveController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    // Symbol floating animation
    _symbolController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    // Initialize floating symbols
    _symbols = List.generate(8, (index) {
      return FloatingSymbol(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speedX: (_random.nextDouble() - 0.5) * 0.1,
        speedY: -0.05 - _random.nextDouble() * 0.1, // Upward movement
        size: 30 + _random.nextDouble() * 40,
        opacity: 0.03 + _random.nextDouble() * 0.07,
        rotation: _random.nextDouble() * 360,
        rotationSpeed: (_random.nextDouble() - 0.5) * 45,
      );
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _symbolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Animated gradient waves
        AnimatedBuilder(
          animation: _waveController,
          builder: (context, child) {
            return CustomPaint(
              painter: WaveGradientPainter(
                colors: widget.colors,
                animation: _waveController.value,
              ),
              size: Size.infinite,
            );
          },
        ),

        // Floating rupee symbols
        AnimatedBuilder(
          animation: _symbolController,
          builder: (context, child) {
            return CustomPaint(
              painter: FloatingSymbolsPainter(
                symbols: _symbols,
                progress: _symbolController.value,
              ),
              size: Size.infinite,
            );
          },
        ),

        // Content with smart text visibility
        SmartTextVisibility(
          colors: widget.colors,
          waveProgress: _waveController.value,
          child: widget.child,
        ),
      ],
    );
  }
}

class WaveGradientPainter extends CustomPainter {
  final List<Color> colors;
  final double animation;

  WaveGradientPainter({
    required this.colors,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create multiple gradient layers with wave effect
    for (int i = 0; i < 3; i++) {
      final offset = (animation + i * 0.33) % 1.0;
      final gradient = LinearGradient(
        begin: Alignment(
          cos((offset * 2 * pi) - pi / 2),
          sin((offset * 2 * pi) - pi / 2),
        ),
        end: Alignment(
          -cos((offset * 2 * pi) - pi / 2),
          -sin((offset * 2 * pi) - pi / 2),
        ),
        colors: colors,
      );

      final paint = Paint()
        ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..blendMode = i == 0 ? BlendMode.src : BlendMode.overlay;

      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveGradientPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

class FloatingSymbol {
  final double x;
  final double y;
  final double speedX;
  final double speedY;
  final double size;
  final double opacity;
  final double rotation;
  final double rotationSpeed;

  FloatingSymbol({
    required this.x,
    required this.y,
    required this.speedX,
    required this.speedY,
    required this.size,
    required this.opacity,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class FloatingSymbolsPainter extends CustomPainter {
  final List<FloatingSymbol> symbols;
  final double progress;

  FloatingSymbolsPainter({
    required this.symbols,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var symbol in symbols) {
      // Calculate position with wrapping
      var x = ((symbol.x + symbol.speedX * progress) % 1.0) * size.width;
      var y = ((symbol.y + symbol.speedY * progress) % 1.0) * size.height;

      // Calculate rotation
      final currentRotation = symbol.rotation + symbol.rotationSpeed * progress;

      // Draw symbol
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(currentRotation * pi / 180);

      final textPainter = TextPainter(
        text: TextSpan(
          text: '₹', // Indian Rupee symbol
          style: TextStyle(
            fontSize: symbol.size,
            color: Colors.white.withOpacity(symbol.opacity),
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

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(FloatingSymbolsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class SmartTextVisibility extends StatefulWidget {
  final Widget child;
  final List<Color> colors;
  final double waveProgress;

  const SmartTextVisibility({
    super.key,
    required this.child,
    required this.colors,
    required this.waveProgress,
  });

  @override
  State<SmartTextVisibility> createState() => _SmartTextVisibilityState();
}

class _SmartTextVisibilityState extends State<SmartTextVisibility> {
  @override
  Widget build(BuildContext context) {
    // Calculate average brightness of background
    final avgBrightness = _calculateAverageBrightness(widget.colors);

    // Apply theme based on background brightness
    final textColor = avgBrightness > 0.5 ? Colors.black87 : Colors.white;

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: textColor,
              displayColor: textColor,
            ),
        iconTheme: IconThemeData(
          color: textColor,
        ),
      ),
      child: widget.child,
    );
  }

  double _calculateAverageBrightness(List<Color> colors) {
    double totalBrightness = 0;
    for (var color in colors) {
      final brightness = (color.red * 0.299 +
              color.green * 0.587 +
              color.blue * 0.114) /
          255;
      totalBrightness += brightness;
    }
    return totalBrightness / colors.length;
  }
}
