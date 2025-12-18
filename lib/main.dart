import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import 'managers/money.dart';
import 'managers/physics.dart';
import 'widgets/ui.dart';
import 'painters/painter.dart';

void main() => runApp(const PlinkoApp());

class PlinkoApp extends StatelessWidget {
  const PlinkoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PlinkoBoard(),
    );
  }
}

class PlinkoBoard extends StatefulWidget {
  const PlinkoBoard({super.key});

  @override
  State<PlinkoBoard> createState() => _PlinkoBoardState();
}

class _PlinkoBoardState extends State<PlinkoBoard>
    with SingleTickerProviderStateMixin {
  final money = MoneyManager(initialBalance: 100);
  final physics = PhysicsManager();
  final AudioPlayer audio = AudioPlayer();

  @override
  void initState() {
    super.initState();
    physics.init(onScore: _handleScore);
  }

  void _handleScore(double win) {
    money.addWinnings(win);
    // Add visual/sound feedback here if needed
  }

  @override
  void dispose() {
    physics.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final boardSize = Size(size.width * 0.6, size.height * 0.82);

    if (physics.boardSize != boardSize) {
      physics.rebuildBoard(boardSize);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          const SizedBox(height: 20),
          BalanceDisplay(money: money),
          const SizedBox(height: 10),
          WagerInputRow(
            money: money,
            onDrop: () => setState(() {
              if (money.canPlaceWager()) {
                physics.dropBall(money.wager);
                money.placeWager();
              }
            }),
          ),
          Expanded(
            child: Center(
              child: SizedBox(
                width: boardSize.width,
                height: boardSize.height,
                child: CustomPaint(
                  painter: PlinkoPainter(
                    physics.pegs,
                    physics.ballRadius,
                    physics.balls,
                    physics.bucketTop,
                    physics.zones,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
