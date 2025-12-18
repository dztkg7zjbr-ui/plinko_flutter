import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../models/ball.dart';
import '../models/zone.dart';

class PhysicsManager {
  // ===== PUBLIC DATA (USED BY MAIN & PAINTER) =====
  final List<Ball> balls = [];
  final List<Offset> pegs = [];
  final List<Zone> zones = [];

  double ballRadius = 0;
  double pegRadius = 0;

  double leftWallX = 0;
  double rightWallX = 0;
  double bucketTop = 0;

  Size boardSize = Size.zero;

  // ===== INTERNAL =====
  late void Function(double win) _onScore;

  late Ticker _ticker;
  Duration _lastTime = Duration.zero;

  // ===== INIT =====
  void init({required void Function(double win) onScore}) {
    _onScore = onScore;
    _ticker = Ticker(_onTick);
  }

  void dispose() {
    _ticker.dispose();
  }

  // ===== BOARD BUILD =====
  void rebuildBoard(Size size) {
    if (boardSize == size) return;

    boardSize = size;
    pegs.clear();
    zones.clear();

    pegRadius = boardSize.width * 0.0045;
    ballRadius = boardSize.width * 0.009;

    const int topPegCount = 5;
    const int pegRows = 20;

    final topMargin = ballRadius * 4;
    final bottomMargin = ballRadius * 8;
    final usableH = boardSize.height - topMargin - bottomMargin;
    final rowSpacing = usableH / (pegRows - 1);

    final usableW = boardSize.width * 0.84;
    final widest = topPegCount + pegRows - 1;
    final colSpacing = usableW / (widest - 1);

    // Build pegs
    for (int r = 0; r < pegRows; r++) {
      final count = topPegCount + r;
      final rowW = (count - 1) * colSpacing;
      final startX = (boardSize.width - rowW) / 2;
      final y = topMargin + r * rowSpacing;

      for (int c = 0; c < count; c++) {
        pegs.add(Offset(startX + c * colSpacing, y));
      }
    }

    // Bottom row
    final bottomCount = topPegCount + pegRows - 1;
    final bottomRow = pegs.sublist(pegs.length - bottomCount);

    final leftPeg = bottomRow.first.dx;
    final rightPeg = bottomRow.last.dx;

    final multipliers = [
      25, 10, 5, 4.5, 4, 3.5, 3, 2.5, 2, 1.5, 1, 0.5, 0.2,
      0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5, 10, 25
    ];

    final span = (rightPeg - leftPeg) / (multipliers.length - 2);

    leftWallX = leftPeg - span;
    rightWallX = rightPeg + span;

    for (int i = 0; i < multipliers.length; i++) {
      final x0 = leftWallX + i * span;
      zones.add(Zone(x0, x0 + span, multipliers[i].toDouble()));
    }

    bucketTop = bottomRow.first.dy + ballRadius * 2.2;
  }

  // ===== DROP BALL =====
  void dropBall(double wager) {
    if (boardSize == Size.zero || pegs.isEmpty) return;

    final spawnX =
        (leftWallX + rightWallX) / 2 +
        Random().nextDouble() * ballRadius * 2 -
        ballRadius;

    final spawnY = pegs.first.dy - ballRadius * 6;

    balls.add(
      Ball(
        pos: Offset(spawnX, spawnY),
        vel: Offset.zero,
        wager: wager,
      ),
    );

    if (!_ticker.isActive) {
      _lastTime = Duration.zero;
      _ticker.start();
    }
  }

  // ===== TICKER LOOP =====
  void _onTick(Duration elapsed) {
    if (_lastTime == Duration.zero) {
      _lastTime = elapsed;
      return;
    }

    final dt = (elapsed - _lastTime).inMicroseconds / 1e6;
    _lastTime = elapsed;

    if (balls.isEmpty) {
      _ticker.stop();
      return;
    }

    _step(dt);
  }

  // ===== PHYSICS STEP =====
  void _step(double dt) {
    const gravity = 950.0;
    const airDrag = 0.05;

    final toRemove = <Ball>[];

    for (final ball in balls) {
      // Gravity
      ball.vel = Offset(ball.vel.dx, ball.vel.dy + gravity * dt);

      // Drag
      ball.vel *= (1 - airDrag * dt);

      // Integrate
      ball.pos += ball.vel * dt;

      _collideWalls(ball);
      _collidePegs(ball);

      // Zone hit
      if (!ball.scored && ball.pos.dy >= bucketTop) {
        final z = _zoneForX(ball.pos.dx);
        if (z != null) {
          ball.scored = true;
          _onScore(ball.wager * z.multiplier);
          toRemove.add(ball);
          continue;
        }
      }

      // Cleanup
      if (ball.pos.dy > boardSize.height + ballRadius * 2) {
        toRemove.add(ball);
      }
    }

    for (final b in toRemove) {
      balls.remove(b);
    }
  }

  // ===== COLLISIONS =====
  void _collideWalls(Ball ball) {
    final dxL = ball.pos.dx - leftWallX;
    if (dxL.abs() < ballRadius) {
      ball.pos = Offset(leftWallX + ballRadius, ball.pos.dy);
      ball.vel = Offset(-ball.vel.dx * 0.35, ball.vel.dy);
    }

    final dxR = rightWallX - ball.pos.dx;
    if (dxR.abs() < ballRadius) {
      ball.pos = Offset(rightWallX - ballRadius, ball.pos.dy);
      ball.vel = Offset(-ball.vel.dx * 0.35, ball.vel.dy);
    }
  }

  void _collidePegs(Ball ball) {
    for (final p in pegs) {
      final d = ball.pos - p;
      final dist = d.distance;
      final minD = pegRadius + ballRadius;

      if (dist > 0 && dist < minD) {
        final n = d / dist;
        ball.pos += n * (minD - dist + 0.5);

        final vDot = ball.vel.dx * n.dx + ball.vel.dy * n.dy;
        if (vDot < 0) {
          ball.vel -= n * ((1 + 0.28) * vDot);
        }
      }
    }
  }

  // ===== ZONE LOOKUP =====
  Zone? _zoneForX(double x) {
    for (final z in zones) {
      if (x >= z.x0 && x < z.x1) return z;
    }
    return null;
  }
}
