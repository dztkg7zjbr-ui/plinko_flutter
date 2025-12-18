class MoneyManager {
  double _balance;
  double _wager;

  MoneyManager({required double initialBalance})
      : _balance = initialBalance,
        _wager = 1;

  double get balance => _balance;
  double get wager => _wager;

  void setWager(double val) {
    _wager = val.clamp(1, _balance);
  }

  bool canPlaceWager() => _wager <= _balance;

  void placeWager() {
    _balance -= _wager;
  }

  void addWinnings(double win) {
    _balance += win;
  }
}
