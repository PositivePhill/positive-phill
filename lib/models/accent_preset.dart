import 'package:flutter/material.dart';

/// Curated accent presets (v1.1). Lavender matches v1.0 Platinum theme.
enum AccentPreset {
  lavender,
  mint,
  sunrise,
  ocean,
  rose,
  cosmic,
  forest,
  gold;

  String get storageName => name;

  String get displayName => switch (this) {
        AccentPreset.lavender => 'Lavender',
        AccentPreset.mint => 'Mint',
        AccentPreset.sunrise => 'Sunrise',
        AccentPreset.ocean => 'Ocean',
        AccentPreset.rose => 'Rose',
        AccentPreset.cosmic => 'Cosmic',
        AccentPreset.forest => 'Forest',
        AccentPreset.gold => 'Gold',
      };

  /// Seed for [ColorScheme.fromSeed]. Unused for [lavender].
  Color get seedColor => switch (this) {
        AccentPreset.lavender => const Color(0xFF7B68EE),
        AccentPreset.mint => const Color(0xFF00897B),
        AccentPreset.sunrise => const Color(0xFFE65100),
        AccentPreset.ocean => const Color(0xFF0277BD),
        AccentPreset.rose => const Color(0xFFC2185B),
        AccentPreset.cosmic => const Color(0xFF5E35B1),
        AccentPreset.forest => const Color(0xFF33691E),
        AccentPreset.gold => const Color(0xFFC6A000),
      };

  static AccentPreset fromStorage(String? raw) {
    if (raw == null || raw.isEmpty) return AccentPreset.lavender;
    for (final v in AccentPreset.values) {
      if (v.name == raw) return v;
    }
    return AccentPreset.lavender;
  }
}
