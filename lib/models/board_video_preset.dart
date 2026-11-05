import 'dart:ui' show Color;

/// Bundled Inspirational Board loop videos (muted, looping on Home).
enum BoardVideoPreset {
  none,
  rainWindow,
  oceanCalm,
  forestLight,
  campfireGlow,
  cosmicDrift;

  /// Preset written once for a proven fresh install (no saved preferences).
  static const BoardVideoPreset freshInstallDefault = BoardVideoPreset.rainWindow;

  /// Stable id for persistence (snake_case; `none` is stored explicitly).
  String get storageId => switch (this) {
        BoardVideoPreset.none => 'none',
        BoardVideoPreset.rainWindow => 'rain_window',
        BoardVideoPreset.oceanCalm => 'ocean_calm',
        BoardVideoPreset.forestLight => 'forest_light',
        BoardVideoPreset.campfireGlow => 'campfire_glow',
        BoardVideoPreset.cosmicDrift => 'cosmic_drift',
      };

  String get displayName => switch (this) {
        BoardVideoPreset.none => 'None',
        BoardVideoPreset.rainWindow => 'Rain Window',
        BoardVideoPreset.oceanCalm => 'Ocean Calm',
        BoardVideoPreset.forestLight => 'Forest Light',
        BoardVideoPreset.campfireGlow => 'Campfire Glow',
        BoardVideoPreset.cosmicDrift => 'Cosmic Drift',
      };

  /// Path for [VideoPlayerController.asset]. Null when [none].
  String? bundledAssetPath() => switch (this) {
        BoardVideoPreset.none => null,
        BoardVideoPreset.rainWindow =>
          'assets/videos/rain_window_loop.mp4',
        BoardVideoPreset.oceanCalm =>
          'assets/videos/ocean_calm_loop.mp4',
        BoardVideoPreset.forestLight =>
          'assets/videos/forest_light_loop.mp4',
        BoardVideoPreset.campfireGlow =>
          'assets/videos/campfire_glow_loop.mp4',
        BoardVideoPreset.cosmicDrift =>
          'assets/videos/cosmic_drift_loop.mp4',
      };

  /// Still frame shown beneath the video until playback is visible.
  String? posterAssetPath() => switch (this) {
        BoardVideoPreset.none => null,
        BoardVideoPreset.rainWindow => 'assets/images/posters/rain_window.jpg',
        BoardVideoPreset.oceanCalm => 'assets/images/posters/ocean_calm.jpg',
        BoardVideoPreset.forestLight =>
          'assets/images/posters/forest_light.jpg',
        BoardVideoPreset.campfireGlow =>
          'assets/images/posters/campfire_glow.jpg',
        BoardVideoPreset.cosmicDrift =>
          'assets/images/posters/cosmic_drift.jpg',
      };

  /// Average poster color, painted while the poster image decodes.
  Color get posterPlaceholderColor => switch (this) {
        BoardVideoPreset.none => const Color(0xFF121212),
        BoardVideoPreset.rainWindow => const Color(0xFF6D6B6F),
        BoardVideoPreset.oceanCalm => const Color(0xFF686E71),
        BoardVideoPreset.forestLight => const Color(0xFF666945),
        BoardVideoPreset.campfireGlow => const Color(0xFF22100B),
        BoardVideoPreset.cosmicDrift => const Color(0xFF56005E),
      };

  /// Normalizes persisted ids so live values like `forestlight` match [forestLight].
  static String _canonicalStorageKey(String raw) {
    final trimmed = raw.trim().toLowerCase();
    return trimmed.replaceAll(RegExp(r'[\s_\-]+'), '');
  }

  static BoardVideoPreset fromStorageId(String? value) {
    if (value == null) return BoardVideoPreset.none;
    final key = _canonicalStorageKey(value);
    if (key.isEmpty || key == 'none') return BoardVideoPreset.none;
    return switch (key) {
      'rainwindow' => BoardVideoPreset.rainWindow,
      'oceancalm' => BoardVideoPreset.oceanCalm,
      'forestlight' => BoardVideoPreset.forestLight,
      'campfireglow' => BoardVideoPreset.campfireGlow,
      'cosmicdrift' => BoardVideoPreset.cosmicDrift,
      _ => BoardVideoPreset.none,
    };
  }
}
