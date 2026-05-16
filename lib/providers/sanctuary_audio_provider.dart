import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:positive_phill/models/sanctuary_soundscape.dart';
import 'package:positive_phill/services/sanctuary_audio_service.dart';
import 'package:positive_phill/services/storage_service.dart';

/// Global ambience for Sanctuary Sounds. Never auto-plays from cold start.
class SanctuaryAudioProvider with ChangeNotifier {
  final StorageService _storage = StorageService();
  final SanctuaryAudioService _service = SanctuaryAudioService();

  SanctuarySoundscape? _selectedSoundscape;
  double _volume = 0.45;
  bool _isPlaying = false;
  bool _loaded = false;

  SanctuarySoundscape? get selectedSoundscape => _selectedSoundscape;
  double get volume => _volume;
  bool get isPlaying => _isPlaying;
  bool get isLoaded => _loaded;

  SanctuaryAudioProvider() {
    unawaited(_loadPersistedOnly());
  }

  Future<void> _loadPersistedOnly() async {
    try {
      _volume = await _storage.getSanctuaryVolume();
      final raw = await _storage.getSanctuarySoundscape();
      final parsed = SanctuarySoundscape.fromStorageId(raw);
      if (raw != null &&
          raw.trim().isNotEmpty &&
          parsed == null) {
        await _storage.setSanctuarySoundscape(null);
      }
      _selectedSoundscape = parsed;
    } catch (e) {
      debugPrint('SanctuaryAudioProvider.load failed: $e');
      _volume = 0.45;
      _selectedSoundscape = null;
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> play(SanctuarySoundscape sound) async {
    _selectedSoundscape = sound;
    await _storage.setSanctuarySoundscape(sound.storageId);
    await _service.play(sound, _volume);
    _isPlaying = true;
    notifyListeners();
  }

  Future<void> stop() async {
    await _service.stop();
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> setVolume(double value) async {
    final v = value.clamp(0.0, 1.0);
    _volume = v;
    notifyListeners();
    await _storage.setSanctuaryVolume(v);
    await _service.setVolume(v);
  }

  /// Human-readable subtitle for Settings (e.g. "Rainfall • playing" vs label only).
  String settingsSubtitle() {
    if (_selectedSoundscape == null) {
      return 'Off';
    }
    final label = _selectedSoundscape!.label;
    if (_isPlaying) return '$label · playing';
    return label;
  }

  @override
  void dispose() {
    unawaited(_service.disposeAsync());
    super.dispose();
  }
}
