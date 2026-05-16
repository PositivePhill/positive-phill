import 'package:positive_phill/models/affirmation.dart';

/// User-facing rescue intents mapped to existing [AffirmationCategory] pools only.
enum RescueIntent {
  calm,
  hype,
  focus,
  healing,
  confidence,
}

extension RescueIntentX on RescueIntent {
  String get displayTitle {
    switch (this) {
      case RescueIntent.calm:
        return 'Calm me down';
      case RescueIntent.hype:
        return 'Hype me up';
      case RescueIntent.focus:
        return 'Help me focus';
      case RescueIntent.healing:
        return 'Healing';
      case RescueIntent.confidence:
        return 'Confidence';
    }
  }

  /// Wellness-safe one-line hint (no medical / therapy framing).
  String get supportLine {
    switch (this) {
      case RescueIntent.calm:
        return 'Take a breath. One moment at a time.';
      case RescueIntent.hype:
        return 'A little lift, when you need it.';
      case RescueIntent.focus:
        return 'Gentle focus for the next step.';
      case RescueIntent.healing:
        return 'Be kind to yourself.';
      case RescueIntent.confidence:
        return 'You are capable.';
    }
  }

  AffirmationCategory get category {
    switch (this) {
      case RescueIntent.calm:
        return AffirmationCategory.calm;
      case RescueIntent.hype:
        return AffirmationCategory.confidence;
      case RescueIntent.focus:
        return AffirmationCategory.focus;
      case RescueIntent.healing:
        return AffirmationCategory.healing;
      case RescueIntent.confidence:
        return AffirmationCategory.confidence;
    }
  }
}
