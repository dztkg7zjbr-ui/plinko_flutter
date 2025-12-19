class Zone {
  final double x0;
  final double x1;
  final double multiplier;

  // NEW: Timestamp for neon glow flash
  DateTime? highlightUntil;

  Zone(this.x0, this.x1, this.multiplier);
}