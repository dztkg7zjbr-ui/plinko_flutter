import 'package:flutter/material.dart';
import '../models/ball.dart';
import '../models/zone.dart';

class PlinkoPainter extends CustomPainter {
  final List<Offset> pegs;
  final double ballRadius;
  final List<Ball> balls;
  final double bucketTop;
  final List<Zone> zones;

  PlinkoPainter(
    this.pegs,
    this.ballRadius,
    this.balls,
    this.bucketTop,
    this.zones,
  );

  @override
  void paint(Canvas c, Size s) {
    final pegPaint = Paint()..color = Colors.white;
    final ballPaint = Paint()..color = Colors.red;

    // draw pegs
    for (final p in pegs) {
      c.drawCircle(p, ballRadius * 0.6, pegPaint);
    }

    // draw zone outlines
    for (final z in zones) {
      final rect = Rect.fromLTRB(z.x0, bucketTop, z.x1, bucketTop + 30);
      final t = (z.multiplier / 25).clamp(0.0, 1.0);

      // gradient yellow → red by multiplier
      final color = HSVColor.lerp(
        HSVColor.fromColor(Colors.yellow),
        HSVColor.fromColor(Colors.red),
        t,
      )!
          .toColor();

      c.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color,
      );

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
        textAlign: TextAlign.center,
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

    // draw balls
    for (final b in balls) {
      c.drawCircle(b.pos, ballRadius, ballPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
