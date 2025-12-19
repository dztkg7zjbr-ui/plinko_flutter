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

class WagerInputRow extends StatefulWidget {
  final MoneyManager money;
  final VoidCallback onDrop;

  const WagerInputRow({
    required this.money,
    required this.onDrop,
    super.key,
  });

  @override
  State<WagerInputRow> createState() => _WagerInputRowState();
}

class _WagerInputRowState extends State<WagerInputRow> {
  late TextEditingController controller;
  String? errorMessage; // NEW

  @override
  void initState() {
    super.initState();
    controller =
        TextEditingController(text: widget.money.wager.toStringAsFixed(0));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _setWager(double value) {
    widget.money.setWager(value);
    controller.text = widget.money.wager.toStringAsFixed(0);
    setState(() {});
  }

  // NEW: show an error for 2.5 seconds
  void _showError(String msg) {
    setState(() => errorMessage = msg);

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => errorMessage = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Wager:',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(width: 8),

            // ===== WAGER INPUT BOX =====
            SizedBox(
              width: 80,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white12,
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                ),
                onSubmitted: (v) {
                  final parsed = double.tryParse(v);
                  if (parsed != null) _setWager(parsed);
                },
              ),
            ),

            const SizedBox(width: 8),

            // ===== MAX BUTTON =====
            ElevatedButton(
              onPressed: () {
                _setWager(widget.money.balance);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.black,
              ),
              child: const Text('MAX'),
            ),

            const SizedBox(width: 12),

            // ===== DROP BUTTON =====
            ElevatedButton(
              onPressed: () {
                if (widget.money.wager > widget.money.balance) {
                  _showError("Wager exceeds balance");
                  return;
                }

                widget.onDrop();
                controller.text =
                    widget.money.wager.toStringAsFixed(0);
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text(
                'DROP',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),

        // ===== ERROR MESSAGE BELOW WAGER ROW =====
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              errorMessage!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
      ],
    );
  }
}
