import 'package:flutter/foundation.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

export 'package:flutter_vibrate/flutter_vibrate.dart' show FeedbackType;

/// Safely wraps vibration calls so unsupported platforms (like web) simply skip.
class HapticsService {
  const HapticsService._();

  static Future<void> feedback(FeedbackType type) async {
    if (kIsWeb) return;
    try {
      final canVibrate = await Vibrate.canVibrate;
      if (canVibrate) Vibrate.feedback(type);
    } catch (error) {
      debugPrint('Haptics skipped: $error');
    }
  }
}