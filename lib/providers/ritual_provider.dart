import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:positive_phill/models/ritual_length.dart';

/// Countdown timer for Rescue Flow only. Does not tie to XP, streak, or sessions.
class RitualProvider with ChangeNotifier {
  RitualLength _length = RitualLength.threeMin;
  int _remaining = RitualLength.threeMin.seconds;
  bool _isRunning = false;
  Timer? _timer;

  RitualLength get selectedLength => _length;
  int get remainingSeconds => _remaining;
  bool get isRunning => _isRunning;

  /// Sets the ritual length and refills the countdown (only when not running).
  void setLength(RitualLength length) {
    if (_isRunning) return;
    _length = length;
    _remaining = length.seconds;
    notifyListeners();
  }

  void start() {
    if (_remaining <= 0) {
      _remaining = _length.seconds;
    }
    if (_isRunning) return;
    _isRunning = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
    notifyListeners();
  }

  void _onTick(Timer timer) {
    if (_remaining <= 1) {
      _remaining = 0;
      _timer?.cancel();
      _timer = null;
      _isRunning = false;
      notifyListeners();
      return;
    }
    _remaining--;
    notifyListeners();
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
    if (_isRunning) {
      _isRunning = false;
      notifyListeners();
    }
  }

  /// Pause and restore countdown to the selected length.
  void reset() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _remaining = _length.seconds;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
