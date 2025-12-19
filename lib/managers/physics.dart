import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:audioplayers/audioplayers.dart';

import '../models/ball.dart';
import '../models/zone.dart';
import '../models/floating_text.dart';

class PhysicsManager {
  // ===== PUBLIC DATA =====
  final List<Ball> balls = [];
  final List<Offset> pegs = [];
  final List<Zone> zones = [];
  final List<FloatingText> floatingTexts = [];

  double ballRadius = 0;
  double pegRadius = 0;

  double leftWallX = 0;
  double rightWallX = 0;
  double bucketTop = 0;

  Size boardSize = Size.zero;

  // ===== INTERNAL =====
  late void Function(double win) _onScore;
  late VoidCallback _onFrame;

  late Ticker _ticker;
  Duration _lastTime = Duration.zero;

  final AudioPlayer audio = AudioPlayer();

  // ===== INIT =====
  void init({
    required void Function(double win) onScore,
    required VoidCallback onFrame,
  }) {
    _onScore = onScore;
    _onFrame = onFrame;
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

    // Build zones
    final bottomCount = topPegCount + pegRows - 1;
    final bottomRow = pegs.sublist(pegs.length - bottomCount);

    final leftPeg = bottomRow.first.dx;
    final rightPeg = bottomRow.last.dx;

    final padding = ballRadius * 1.25;
    leftWallX = leftPeg - padding;
    rightWallX = rightPeg + padding;

    final multipliers = [
      25, 10, 5, 4.5, 4, 3.5, 3, 2.5, 2, 1.5, 1, 0.5, 0.2,
      0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5, 10, 25,
    ];

    final span = (rightWallX - leftWallX) / multipliers.length;

    for (int i = 0; i < multipliers.length; i++) {
      zones.add(
        Zone(
          leftWallX + (i * span),
          leftWallX + ((i + 1) * span),
          multipliers[i].toDouble(),
        ),
      );
    }

    bucketTop = bottomRow.first.dy + ballRadius * 2.2;
  }

  // ===== DROP BALL =====
  void dropBall(double wager) {
    if (boardSize == Size.zero || pegs.isEmpty) return;

    const int topPegCount = 5;
    final centerIndex = topPegCount ~/ 2;
    final centerPeg = pegs[centerIndex];

    final dx = (Random().nextDouble() * 2 - 1) * ballRadius * 0.25;

    final spawnX = centerPeg.dx + dx;
    final spawnY = centerPeg.dy - ballRadius * 9;

    balls.add(
      Ball(
        pos: Offset(spawnX, spawnY),
        vel: Offset.zero,
        wager: wager,
      ),
    );

    audio.play(AssetSource('sounds/drop.wav'), volume: 0.4);

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

    double dt = (elapsed - _lastTime).inMicroseconds / 1e6;
    dt = dt.clamp(0.0, 0.02); // Prevent tunneling
    _lastTime = elapsed;

    // Update floating texts
    for (final ft in floatingTexts) {
      ft.update(dt);
    }
    floatingTexts.removeWhere((ft) => ft.expired);

    // Check if glow still active
    final now = DateTime.now();
    bool glowActive = false;
    for (final z in zones) {
      if (z.highlightUntil != null && now.isBefore(z.highlightUntil!)) {
        glowActive = true;
        break;
      }
    }

    // If no balls and no glow, stop ticker
    if (balls.isEmpty && !glowActive && floatingTexts.isEmpty) {
      _ticker.stop();
      _onFrame();
      return;
    }

    // Physics step only if balls remain
    if (balls.isNotEmpty) {
      _step(dt);
    }

    _onFrame();
  }

  // ===== PHYSICS STEP =====
  void _step(double dt) {
    const gravity = 1045.0; // +10% faster fall
    const drag = 0.05;

    final remove = <Ball>[];

    for (final ball in balls) {
      // Apply gravity + drag
      ball.vel = Offset(ball.vel.dx, ball.vel.dy + gravity * dt);
      ball.vel *= (1 - drag * dt);

      // Move
      ball.pos += ball.vel * dt;

      _collideWalls(ball);
      _collidePegs(ball);

      // Scoring
      if (!ball.scored && ball.pos.dy >= bucketTop) {
        final z = _zoneForX(ball.pos.dx);
        if (z != null) {
          ball.scored = true;

          // Trigger glow
          z.highlightUntil =
              DateTime.now().add(const Duration(milliseconds: 200));

          // Floating text pop
          floatingTexts.add(
            FloatingText(
              position: Offset(ball.pos.dx, bucketTop - 20),
              amount: ball.wager * z.multiplier,
            ),
          );

          audio.play(AssetSource('sounds/score.wav'), volume: 0.7);

          _onScore(ball.wager * z.multiplier);

          remove.add(ball);
          continue;
        }
      }

      // Off-screen cleanup
      if (ball.pos.dy > boardSize.height + ballRadius * 3) {
        remove.add(ball);
      }
    }

    for (final b in remove) {
      balls.remove(b);
    }
  }

  // ===== WALL COLLISION =====
  void _collideWalls(Ball ball) {
    const wallBounce = 0.6; // bouncier walls

    if (ball.pos.dx - leftWallX < ballRadius) {
      ball.pos = Offset(leftWallX + ballRadius, ball.pos.dy);
      ball.vel = Offset(-ball.vel.dx * wallBounce, ball.vel.dy);
      audio.play(AssetSource('sounds/wall.wav'), volume: 0.25);
    }

    if (rightWallX - ball.pos.dx < ballRadius) {
      ball.pos = Offset(rightWallX - ballRadius, ball.pos.dy);
      ball.vel = Offset(-ball.vel.dx * wallBounce, ball.vel.dy);
      audio.play(AssetSource('sounds/wall.wav'), volume: 0.25);
    }
  }

  // ===== PEG COLLISION =====
  void _collidePegs(Ball ball) {
    const double elasticity = 0.32;
    const double tangential = 0.12;

    for (final peg in pegs) {
      final d = ball.pos - peg;
      final dist = d.distance;

      final minDist = ballRadius + pegRadius + 0.5;

      if (dist > 0 && dist < minDist) {
        final n = d / dist;
        final overlap = minDist - dist;

        ball.pos += n * (overlap + 0.75);

        final v = ball.vel;
        final vn = v.dx * n.dx + v.dy * n.dy;

        if (vn < 0) {
          final t = Offset(-n.dy, n.dx);
          final vt = v.dx * t.dx + v.dy * t.dy;

          final reflectedNormal = Offset(
            (-elasticity * vn) * n.dx,
            (-elasticity * vn) * n.dy,
          );

          final tangentialPart = Offset(
            (vt * (1 - tangential)) * t.dx,
            (vt * (1 - tangential)) * t.dy,
          );

          ball.vel = reflectedNormal + tangentialPart;

          audio.play(AssetSource('sounds/peg.wav'), volume: 0.15);
        }
      }
    }
  }

  // ===== FIND ZONE =====
  Zone? _zoneForX(double x) {
    for (final z in zones) {
      if (x >= z.x0 && x < z.x1) return z;
    }
    return null;
  }
}
