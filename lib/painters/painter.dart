import 'package:flutter/material.dart';
import '../models/ball.dart';
import '../models/zone.dart';
import '../models/floating_text.dart';

class PlinkoPainter extends CustomPainter {
  final List<Offset> pegs;
  final double ballRadius;
  final List<Ball> balls;
  final double bucketTop;
  final List<Zone> zones;
  final List<FloatingText> floatingTexts;

  PlinkoPainter(
    this.pegs,
    this.ballRadius,
    this.balls,
    this.bucketTop,
    this.zones,
    this.floatingTexts,
  );

  @override
  void paint(Canvas c, Size s) {
    //--------------------------
    // PEG PAINT
    //--------------------------
    final pegPaint = Paint()..color = Colors.white;

    //--------------------------
    // BALL PAINT
    //--------------------------
    final ballPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    //--------------------------
    // GLOW PAINT (neon zones)
    //--------------------------
    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    //--------------------------
    // DRAW PEGS
    //--------------------------
    for (final p in pegs) {
      c.drawCircle(p, ballRadius * 0.6, pegPaint);
    }

    //--------------------------
    // DRAW ZONES (glow + labels)
    //--------------------------
    final now = DateTime.now();

    for (final z in zones) {
      final rect = Rect.fromLTRB(z.x0, bucketTop, z.x1, bucketTop + 30);

      // Color scale from yellow → red by multiplier
      final t = (z.multiplier / 25).clamp(0.0, 1.0);
      final zoneColor = HSVColor.lerp(
        HSVColor.fromColor(Colors.yellow),
        HSVColor.fromColor(Colors.red),
        t,
      )!.toColor();

      // Draw zone frame
      c.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = zoneColor,
      );

      // GLOW EFFECT if active
      if (z.highlightUntil != null && now.isBefore(z.highlightUntil!)) {
        glowPaint.color = zoneColor.withOpacity(0.6);
        c.drawRRect(
          RRect.fromRectAndRadius(
            rect.inflate(6),
            const Radius.circular(8),
          ),
          glowPaint,
        );
      }

      // LABEL TEXT
      final label = z.multiplier.toStringAsFixed(
        z.multiplier % 1 == 0 ? 0 : 1,
      );

      final tp = TextPainter(
        text: TextSpan(
          text: '${label}x',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(
        c,
        Offset(
          rect.center.dx - tp.width / 2,
          rect.center.dy - tp.height / 2,
        ),
      );
    }

    //--------------------------
    // DRAW BALLS
    //--------------------------
    final double visualBallRadius = ballRadius * 1.15; // +15% bigger

    for (final b in balls) {
      c.drawCircle(b.pos, visualBallRadius, ballPaint);
    }

    //--------------------------
    // FLOATING MONEY TEXT
    //--------------------------
    for (final ft in floatingTexts) {
      if (ft.opacity <= 0) continue;

      final textPainter = TextPainter(
        text: TextSpan(
          text: ft.display,
          style: TextStyle(
            color: Colors.greenAccent.withOpacity(ft.opacity),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 6,
                color: Colors.greenAccent.withOpacity(ft.opacity),
              )
            ],
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        c,
        Offset(
          ft.position.dx - textPainter.width / 2,
          ft.position.dy - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
