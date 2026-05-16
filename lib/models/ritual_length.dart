/// Ritual Timer Lite session lengths (seconds).
enum RitualLength {
  oneMin(60),
  threeMin(180),
  fiveMin(300);

  const RitualLength(this.seconds);
  final int seconds;

  String get label {
    switch (this) {
      case RitualLength.oneMin:
        return '1 min';
      case RitualLength.threeMin:
        return '3 min';
      case RitualLength.fiveMin:
        return '5 min';
    }
  }
}
