import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Draws a leather bifold men's wallet with open/close animation.
/// [openProgress] 0.0 = fully closed, 1.0 = flap fully rotated open.
/// [pulseScale]   drives the breathing pulse on the closed wallet.
class WalletPainter extends CustomPainter {
  final double openProgress;
  final double pulseScale;
  final Color primaryColor;
  final Color accentColor;

  const WalletPainter({
    required this.openProgress,
    this.pulseScale = 1.0,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final wW = size.width * 0.56;   // wallet width
    final wH = size.height * 0.28;  // wallet height

    canvas.save();
    // Apply pulse scale from center
    canvas.translate(cx, cy);
    canvas.scale(pulseScale, pulseScale);
    canvas.translate(-cx, -cy);

    _drawDropShadow(canvas, cx, cy, wW, wH);
    _drawWalletBody(canvas, cx, cy, wW, wH);
    _drawCardSlotInside(canvas, cx, cy, wW, wH);
    _drawTopFlap(canvas, cx, cy, wW, wH);
    _drawBottomStitching(canvas, cx, cy, wW, wH);
    if (openProgress < 0.25) _drawEmbossLogo(canvas, cx, cy);

    canvas.restore();
  }

  // ── Drop Shadow ─────────────────────────────────────────────────
  void _drawDropShadow(Canvas canvas, double cx, double cy, double wW, double wH) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + 18), width: wW * 0.9, height: wH * 0.4),
        const Radius.circular(20),
      ),
      paint,
    );
  }

  // ── Wallet Body (back / main) ───────────────────────────────────
  void _drawWalletBody(Canvas canvas, double cx, double cy, double wW, double wH) {
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: wW, height: wH);
    final gradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF5C3420),
        Color(0xFF3D2314),
        Color(0xFF2A1A0E),
      ],
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(20)),
      Paint()..shader = gradient.createShader(rect),
    );
    // Subtle leather specular highlight
    final specRect = Rect.fromLTWH(
      cx - wW / 2 + 10, cy - wH / 2 + 8,
      wW * 0.45, wH * 0.32,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(specRect, const Radius.circular(14)),
      Paint()..color = Colors.white.withOpacity(0.06),
    );
  }

  // ── Card Slot visible inside when open ─────────────────────────
  void _drawCardSlotInside(Canvas canvas, double cx, double cy, double wW, double wH) {
    if (openProgress < 0.25) return;
    final vis = ((openProgress - 0.25) / 0.75).clamp(0.0, 1.0);
    // Dark interior pocket
    final rect = Rect.fromCenter(
      center: Offset(cx, cy + wH * 0.05),
      width: wW * 0.82,
      height: wH * 0.72,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      Paint()..color = Colors.black.withOpacity(0.45 * vis),
    );
    // Card slot line
    final slotPaint = Paint()
      ..color = Colors.black.withOpacity(0.6 * vis)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(cx - wW * 0.38, cy - wH * 0.05),
      Offset(cx + wW * 0.38, cy - wH * 0.05),
      slotPaint,
    );
  }

  // ── Top Flap with perspective rotation ─────────────────────────
  void _drawTopFlap(Canvas canvas, double cx, double cy, double wW, double wH) {
    canvas.save();
    // Pivot is the top edge of the wallet
    final pivotY = cy - wH / 2;
    canvas.translate(cx, pivotY);

    // Rotate 0 → 140 degrees (flap swings back)
    final angle = openProgress * math.pi * 0.78;
    final scaleY = math.cos(angle);
    final isInside = angle > math.pi / 2;

    // Perspective: compress Y as angle increases
    canvas.scale(1.0, scaleY.abs().clamp(0.01, 1.0));

    final flapRect = Rect.fromLTWH(-wW / 2, 0, wW, wH * 0.52);

    // Outside of flap (warm leather) or inside (darker lining)
    final List<Color> flapColors = isInside
        ? [const Color(0xFF1E100A), const Color(0xFF2A1A0E)]
        : [const Color(0xFF7A4830), const Color(0xFF5C3420)];

    canvas.drawRRect(
      RRect.fromRectAndRadius(flapRect, const Radius.circular(20)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: flapColors,
        ).createShader(flapRect),
    );

    // Stitching along top edge of flap
    _drawStitchRow(canvas, -wW / 2 + 10, wH * 0.07, wW - 20, 9);

    // Brass snap clasp (only visible on outside)
    if (!isInside) {
      final claspCenter = Offset(0, wH * 0.28);
      // Outer ring
      canvas.drawCircle(
        claspCenter, 8,
        Paint()..color = const Color(0xFFC8A96E),
      );
      // Inner ring
      canvas.drawCircle(
        claspCenter, 5,
        Paint()..color = const Color(0xFF8B6914),
      );
      // Center dot
      canvas.drawCircle(
        claspCenter, 2,
        Paint()..color = const Color(0xFFE8C97E),
      );
    }

    canvas.restore();
  }

  // ── Bottom stitching row ─────────────────────────────────────────
  void _drawBottomStitching(Canvas canvas, double cx, double cy, double wW, double wH) {
    final y = cy + wH / 2 - 10;
    _drawStitchRow(canvas, cx - wW / 2 + 12, y, wW - 24, 10);
  }

  void _drawStitchRow(Canvas canvas, double startX, double y, double totalW, int count) {
    final paint = Paint()
      ..color = const Color(0xFFC8A96E).withOpacity(0.55)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final spacing = totalW / count;
    for (int i = 0; i < count; i++) {
      final x = startX + i * spacing;
      canvas.drawLine(Offset(x, y), Offset(x + spacing * 0.5, y), paint);
    }
  }

  // ── Embossed "EW" Logo (closed only) ───────────────────────────
  void _drawEmbossLogo(Canvas canvas, double cx, double cy) {
    final tp = TextPainter(
      text: TextSpan(
        text: 'EW',
        style: TextStyle(
          color: Colors.white.withOpacity(0.10),
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: 4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2 + 10));
  }

  @override
  bool shouldRepaint(WalletPainter old) =>
      old.openProgress != openProgress || old.pulseScale != pulseScale;
}
