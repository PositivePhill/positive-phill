import 'package:flutter/material.dart';

/// Built-in home background gradients (no image assets).
enum BackgroundGradientPreset {
  none,
  calmGradient,
  sunriseGlow,
  oceanCalm,
  forestMist,
  cosmicViolet,
  roseGold;

  String get storageName => name;

  String get displayName => switch (this) {
        BackgroundGradientPreset.none => 'None',
        BackgroundGradientPreset.calmGradient => 'Calm Gradient',
        BackgroundGradientPreset.sunriseGlow => 'Sunrise Glow',
        BackgroundGradientPreset.oceanCalm => 'Ocean Calm',
        BackgroundGradientPreset.forestMist => 'Forest Mist',
        BackgroundGradientPreset.cosmicViolet => 'Cosmic Violet',
        BackgroundGradientPreset.roseGold => 'Rose Gold',
      };

  static BackgroundGradientPreset fromStorage(String? raw) {
    if (raw == null || raw.isEmpty) return BackgroundGradientPreset.none;
    for (final v in BackgroundGradientPreset.values) {
      if (v.name == raw) return v;
    }
    return BackgroundGradientPreset.none;
  }

  /// Linear gradient for [brightness]. Returns null for [none].
  LinearGradient? linearGradientFor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    switch (this) {
      case BackgroundGradientPreset.none:
        return null;
      case BackgroundGradientPreset.calmGradient:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  Color(0xFF1A2332),
                  Color(0xFF252040),
                  Color(0xFF1E2A28),
                ]
              : const [
                  Color(0xFFE8F4F8),
                  Color(0xFFF0EDF8),
                  Color(0xFFE8F0EC),
                ],
        );
      case BackgroundGradientPreset.sunriseGlow:
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [
                  Color(0xFF3D2818),
                  Color(0xFF4A2238),
                  Color(0xFF1C1B24),
                ]
              : const [
                  Color(0xFFFFF0E0),
                  Color(0xFFFFE4EC),
                  Color(0xFFE8F0FF),
                ],
        );
      case BackgroundGradientPreset.oceanCalm:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  Color(0xFF0D2438),
                  Color(0xFF152830),
                  Color(0xFF1A2040),
                ]
              : const [
                  Color(0xFFE0F2FA),
                  Color(0xFFE8F4F0),
                  Color(0xFFE3E8FF),
                ],
        );
      case BackgroundGradientPreset.forestMist:
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [
                  Color(0xFF1A2820),
                  Color(0xFF243018),
                  Color(0xFF1C2230),
                ]
              : const [
                  Color(0xFFE8F2E8),
                  Color(0xFFF0F5E8),
                  Color(0xFFE8EEF5),
                ],
        );
      case BackgroundGradientPreset.cosmicViolet:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  Color(0xFF221830),
                  Color(0xFF281838),
                  Color(0xFF181028),
                ]
              : const [
                  Color(0xFFF0E8FF),
                  Color(0xFFE8E4FF),
                  Color(0xFFECE8F5),
                ],
        );
      case BackgroundGradientPreset.roseGold:
        return LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: isDark
              ? const [
                  Color(0xFF2A1820),
                  Color(0xFF302018),
                  Color(0xFF221C28),
                ]
              : const [
                  Color(0xFFFFF0F0),
                  Color(0xFFFFF8E8),
                  Color(0xFFF5F0FF),
                ],
        );
    }
  }
}
