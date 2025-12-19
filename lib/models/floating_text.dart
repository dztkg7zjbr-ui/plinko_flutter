import 'package:flutter/material.dart';

class FloatingText {
  Offset position;       // current position on board
  double opacity;        // 1 → 0 as it fades
  double velocityY;      // upward speed
  final double amount;   // win amount (for display)
  final DateTime created;

  // animation length (ms)
  static const lifespan = 1500; // 1.5 seconds

  FloatingText({
    required this.position,
    required this.amount,
  })  : opacity = 1.0,
        velocityY = -40.0,      // moves upward
        created = DateTime.now();

  /// Returns true if this text has expired
  bool get expired {
    final age = DateTime.now().difference(created).inMilliseconds;
    return age > lifespan;
  }

  /// Update position + opacity each tick
  void update(double dt) {
    // Move upward over time
    position = Offset(position.dx, position.dy + velocityY * dt);

    // Fade out linearly
    final age = DateTime.now().difference(created).inMilliseconds;
    opacity = 1.0 - (age / lifespan).clamp(0.0, 1.0);
  }

  /// Text to display, formatted like +20 or +4.5
  String get display =>
      amount % 1 == 0 ? "+${amount.toInt()}" : "+${amount.toStringAsFixed(1)}";
}
