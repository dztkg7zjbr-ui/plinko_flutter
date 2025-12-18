import 'package:flutter/material.dart';

class Ball {
  Offset pos;
  Offset vel;
  final double wager;
  bool scored;

  Ball({
    required this.pos,
    required this.vel,
    required this.wager,
    this.scored = false,
  });
}
