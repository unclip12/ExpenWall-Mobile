import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Custom painter for drawing the back of the wallet
class WalletBackPainter extends CustomPainter {
  final Color primaryColor;

  WalletBackPainter({
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final w = size.width * 0.5;
    final h = size.height * 0.3;

    // Draw shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    final shadowPath = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(cx, cy + h * 0.3 + 20),
        width: w * 1.2,
        height: h * 0.3,
      ));

    canvas.drawPath(shadowPath, shadowPaint);

    // Draw inside back of wallet
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        primaryColor.withOpacity(0.6),
        primaryColor.withOpacity(0.9),
      ],
    );

    // Make the back slightly taller so it sits behind the cards properly
    final rect = Rect.fromCenter(
      center: Offset(cx, cy - h * 0.1),
      width: w * 0.95,
      height: h * 1.1,
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      paint,
    );
  }

  @override
  bool shouldRepaint(WalletBackPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor;
  }
}

/// Custom painter for drawing the front of the wallet
class WalletFrontPainter extends CustomPainter {
  final double openProgress; // 0.0 to 1.0
  final Color primaryColor;
  final Color accentColor;

  WalletFrontPainter({
    required this.openProgress,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final w = size.width * 0.5;
    final h = size.height * 0.3;

    // Draw bottom front part of wallet (fixed)
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        primaryColor,
        primaryColor.withOpacity(0.8),
      ],
    );

    final rect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: w,
      height: h,
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(20)),
      paint,
    );

    // Add inner shadow/depth
    final innerShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final innerRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: w * 0.9,
      height: h * 0.8,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, const Radius.circular(15)),
      innerShadowPaint,
    );

    // Draw top flap (animates)
    canvas.save();

    // Calculate rotation angle (0 to 120 degrees)
    final angle = openProgress * math.pi * 0.66; // 120 degrees in radians
    final pivotY = cy - h / 2;

    // Apply 3D perspective transformation
    canvas.translate(cx, pivotY);

    // Simplified 2D projection of 3D rotation
    final scaleY = math.cos(angle);
    final offsetY = h / 2 * (1 - scaleY);

    canvas.translate(0, offsetY);
    canvas.scale(1, scaleY.abs());

    // Draw the flap
    final flapGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        accentColor,
        accentColor.withOpacity(0.7),
      ],
    );

    final flapRect = Rect.fromCenter(
      center: Offset(0, h / 4),
      width: w,
      height: h * 0.6,
    );

    final flapPaint = Paint()
      ..shader = flapGradient.createShader(flapRect)
      ..style = PaintingStyle.fill;

    // If angle > 90 degrees (pi/2), we are looking at the inside of the flap
    if (angle > math.pi / 2) {
      flapPaint.color = primaryColor.withOpacity(0.6); // Inner color
    } else {
      flapPaint.color = flapPaint.color.withOpacity((1 - openProgress * 0.3));
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(flapRect, const Radius.circular(20)),
      flapPaint,
    );

    canvas.restore();

    // Draw details (clasp, stitching)
    final claspPaint = Paint()
      ..color = accentColor.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final claspY = cy + (openProgress * h * 0.2);

    canvas.drawCircle(
      Offset(cx, claspY),
      8,
      claspPaint,
    );

    final claspInnerPaint = Paint()
      ..color = primaryColor.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(cx, claspY),
      4,
      claspInnerPaint,
    );

    final stitchPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final stitchPath = Path();
    final stitchY = cy + h * 0.35;
    const stitchCount = 8;
    final stitchSpacing = w * 0.8 / stitchCount;

    for (int i = 0; i < stitchCount; i++) {
      final x = cx - w * 0.4 + (i * stitchSpacing);
      stitchPath.moveTo(x, stitchY);
      stitchPath.lineTo(x + stitchSpacing * 0.4, stitchY);
    }

    canvas.drawPath(stitchPath, stitchPaint);
  }

  @override
  bool shouldRepaint(WalletFrontPainter oldDelegate) {
    return oldDelegate.openProgress != openProgress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor;
  }
}
