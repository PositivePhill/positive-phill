/// Bundled Inspirational Board loop videos (muted, looping on Home).
enum BoardVideoPreset {
  none,
  rainWindow,
  oceanCalm,
  forestLight,
  campfireGlow,
  cosmicDrift;

  String get storageName => name;

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

  static BoardVideoPreset fromStorage(String? raw) {
    if (raw == null || raw.trim().isEmpty) return BoardVideoPreset.none;
    final n = raw.trim();
    for (final v in BoardVideoPreset.values) {
      if (v.name == n) return v;
    }
    return BoardVideoPreset.none;
  }
}
