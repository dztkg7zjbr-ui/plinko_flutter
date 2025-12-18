import 'package:flutter/material.dart';
import '../managers/money.dart';

class BalanceDisplay extends StatelessWidget {
  final MoneyManager money;
  const BalanceDisplay({required this.money, super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Balance: \$${money.balance.toStringAsFixed(0)}',
      style: const TextStyle(
        color: Colors.greenAccent,
        fontSize: 26,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class WagerInputRow extends StatelessWidget {
  final MoneyManager money;
  final VoidCallback onDrop;

  const WagerInputRow({
    required this.money,
    required this.onDrop,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Wager:',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: TextField(
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              filled: true,
              fillColor: Colors.white12,
              border: OutlineInputBorder(borderSide: BorderSide.none),
            ),
            onSubmitted: (v) {
              final parsed = int.tryParse(v);
              if (parsed != null) {
                money.setWager(parsed.toDouble());
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            money.setWager(money.balance);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            foregroundColor: Colors.black,
          ),
          child: const Text('MAX'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: onDrop,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: const Text(
            'DROP',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
