/// Ambient Sanctuary loop bundles (bundled MP3 assets).
enum SanctuarySoundscape {
  rainfall,
  riverFlow,
  oceanWaves,
  forestBirds,
  campfire,
  fishingLake,
  softWind,
  chillPad,
  lightThunder;

  /// Persisted prefs id (underscore form).
  String get storageId {
    switch (this) {
      case SanctuarySoundscape.rainfall:
        return 'rainfall';
      case SanctuarySoundscape.riverFlow:
        return 'river_flow';
      case SanctuarySoundscape.oceanWaves:
        return 'ocean_waves';
      case SanctuarySoundscape.forestBirds:
        return 'forest_birds';
      case SanctuarySoundscape.campfire:
        return 'campfire';
      case SanctuarySoundscape.fishingLake:
        return 'fishing_lake';
      case SanctuarySoundscape.softWind:
        return 'soft_wind';
      case SanctuarySoundscape.chillPad:
        return 'chill_pad';
      case SanctuarySoundscape.lightThunder:
        return 'light_thunder';
    }
  }

  String get label {
    switch (this) {
      case SanctuarySoundscape.rainfall:
        return 'Rainfall';
      case SanctuarySoundscape.riverFlow:
        return 'River Flow';
      case SanctuarySoundscape.oceanWaves:
        return 'Ocean Waves';
      case SanctuarySoundscape.forestBirds:
        return 'Forest Birds';
      case SanctuarySoundscape.campfire:
        return 'Campfire';
      case SanctuarySoundscape.fishingLake:
        return 'Fishing Lake';
      case SanctuarySoundscape.softWind:
        return 'Soft Wind';
      case SanctuarySoundscape.chillPad:
        return 'Chill Pad';
      case SanctuarySoundscape.lightThunder:
        return 'Light Thunder';
    }
  }

  String get emoji {
    switch (this) {
      case SanctuarySoundscape.rainfall:
        return '🌧';
      case SanctuarySoundscape.riverFlow:
        return '🏞';
      case SanctuarySoundscape.oceanWaves:
        return '🌊';
      case SanctuarySoundscape.forestBirds:
        return '🐦';
      case SanctuarySoundscape.campfire:
        return '🔥';
      case SanctuarySoundscape.fishingLake:
        return '🎣';
      case SanctuarySoundscape.softWind:
        return '🍃';
      case SanctuarySoundscape.chillPad:
        return '✨';
      case SanctuarySoundscape.lightThunder:
        return '⚡';
    }
  }

  /// File name segment for bundled MP3s (matches `audio/<filename>` in [assetPath]).
  String get audioFilename {
    switch (this) {
      case SanctuarySoundscape.rainfall:
        return 'rainfall_loop.mp3';
      case SanctuarySoundscape.riverFlow:
        return 'river_flow_loop.mp3';
      case SanctuarySoundscape.oceanWaves:
        return 'ocean_waves_loop.mp3';
      case SanctuarySoundscape.forestBirds:
        return 'forest_birds_loop.mp3';
      case SanctuarySoundscape.campfire:
        return 'campfire_loop.mp3';
      case SanctuarySoundscape.fishingLake:
        return 'fishing_lake_loop.mp3';
      case SanctuarySoundscape.softWind:
        return 'soft_wind_loop.mp3';
      case SanctuarySoundscape.chillPad:
        return 'chill_pad_loop.mp3';
      case SanctuarySoundscape.lightThunder:
        return 'light_thunder_loop.mp3';
    }
  }

  /// Flutter Web emitted path for &lt;audio&gt; (`<base href>`-relative).
  String get webAssetUrl => 'assets/assets/audio/$audioFilename';

  /// Paths for [AssetSource] on mobile/desktop (relative to Flutter asset bundle;
  /// no leading `assets/` package prefix).
  String get assetPath => 'audio/$audioFilename';

  /// Unknown id → treat as none (no persisted selection).
  static SanctuarySoundscape? fromStorageId(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final n = raw.trim();
    for (final v in SanctuarySoundscape.values) {
      if (v.storageId == n) return v;
    }
    return null;
  }
}
