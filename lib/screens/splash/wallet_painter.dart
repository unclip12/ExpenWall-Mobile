import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Custom painter for drawing the wallet with realistic shadows and gradients
class WalletPainter extends CustomPainter {
  final double openProgress; // 0.0 to 1.0
  final Color primaryColor;
  final Color accentColor;

  WalletPainter({
    required this.openProgress,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final walletWidth = size.width * 0.5;
    final walletHeight = size.height * 0.3;

    // Draw shadow
    _drawShadow(canvas, centerX, centerY, walletWidth, walletHeight);

    // Draw bottom part of wallet (stays fixed)
    _drawBottomWallet(canvas, centerX, centerY, walletWidth, walletHeight);

    // Draw top flap (animates)
    _drawTopFlap(canvas, centerX, centerY, walletWidth, walletHeight);

    // Draw wallet details (clasp, stitching)
    _drawDetails(canvas, centerX, centerY, walletWidth, walletHeight);
  }

  void _drawShadow(Canvas canvas, double cx, double cy, double width, double height) {
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3 * (1 - openProgress * 0.5))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    final shadowPath = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(cx, cy + height * 0.3 + openProgress * 20),
        width: width * 1.2,
        height: height * 0.3,
      ));

    canvas.drawPath(shadowPath, shadowPaint);
  }

  void _drawBottomWallet(Canvas canvas, double cx, double cy, double width, double height) {
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
      width: width,
      height: height,
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    final rRect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(20),
    );

    canvas.drawRRect(rRect, paint);

    // Add inner shadow/depth
    final innerShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final innerRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: width * 0.9,
      height: height * 0.8,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, const Radius.circular(15)),
      innerShadowPaint,
    );
  }

  void _drawTopFlap(Canvas canvas, double cx, double cy, double width, double height) {
    canvas.save();

    // Calculate rotation angle (0 to 120 degrees)
    final angle = openProgress * math.pi * 0.66; // 120 degrees in radians
    final pivotY = cy - height / 2;

    // Apply 3D perspective transformation
    canvas.translate(cx, pivotY);
    
    // Create perspective effect
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.001) // perspective
      ..rotateX(-angle); // rotate around X axis

    final perspectiveTransform = matrix.storage;
    
    // Simplified 2D projection of 3D rotation
    final scaleY = math.cos(angle);
    final offsetY = height / 2 * (1 - scaleY);
    
    canvas.translate(0, offsetY);
    canvas.scale(1, scaleY.abs());

    // Draw the flap
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        accentColor,
        accentColor.withOpacity(0.7),
      ],
    );

    final rect = Rect.fromCenter(
      center: Offset(0, height / 4),
      width: width,
      height: height * 0.6,
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    // Adjust opacity based on rotation
    paint.color = paint.color.withOpacity((1 - openProgress * 0.3));

    final rRect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(20),
    );

    canvas.drawRRect(rRect, paint);

    canvas.restore();
  }

  void _drawDetails(Canvas canvas, double cx, double cy, double width, double height) {
    // Draw clasp/button
    final claspPaint = Paint()
      ..color = accentColor.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final claspY = cy + (openProgress * height * 0.2);
    
    canvas.drawCircle(
      Offset(cx, claspY),
      8,
      claspPaint,
    );

    // Draw inner circle for clasp detail
    final claspInnerPaint = Paint()
      ..color = primaryColor.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(cx, claspY),
      4,
      claspInnerPaint,
    );

    // Draw stitching lines (decorative)
    final stitchPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final stitchPath = Path();
    final stitchY = cy + height * 0.35;
    final stitchCount = 8;
    final stitchSpacing = width * 0.8 / stitchCount;

    for (int i = 0; i < stitchCount; i++) {
      final x = cx - width * 0.4 + (i * stitchSpacing);
      stitchPath.moveTo(x, stitchY);
      stitchPath.lineTo(x + stitchSpacing * 0.4, stitchY);
    }

    canvas.drawPath(stitchPath, stitchPaint);
  }

  @override
  bool shouldRepaint(WalletPainter oldDelegate) {
    return oldDelegate.openProgress != openProgress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor;
  }
}
