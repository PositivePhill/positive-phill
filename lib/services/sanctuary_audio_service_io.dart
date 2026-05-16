import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:positive_phill/models/sanctuary_soundscape.dart';

/// Wraps one [AudioPlayer] for looping ambient assets. Lazily instantiated.
///
/// Playback only starts via [play] (user gesture orchestrated by UI).
class SanctuaryAudioService {
  AudioPlayer? _player;

  bool get hasPlayer => _player != null;

  Future<void> play(SanctuarySoundscape sound, double volume) async {
    final v = volume.clamp(0.0, 1.0);
    try {
      _player ??= AudioPlayer();
      final p = _player!;
      await p.stop();
      await p.setReleaseMode(ReleaseMode.loop);
      await p.setVolume(v);
      await p.play(AssetSource(sound.assetPath));
    } catch (e, st) {
      debugPrint('SanctuaryAudioService.play failed: $e\n$st');
    }
  }

  Future<void> setVolume(double volume) async {
    final v = volume.clamp(0.0, 1.0);
    try {
      await _player?.setVolume(v);
    } catch (e, st) {
      debugPrint('SanctuaryAudioService.setVolume failed: $e\n$st');
    }
  }

  Future<void> stop() async {
    try {
      await _player?.stop();
    } catch (e, st) {
      debugPrint('SanctuaryAudioService.stop failed: $e\n$st');
    }
  }

  Future<void> disposeAsync() async {
    final p = _player;
    _player = null;
    if (p != null) {
      try {
        await p.dispose();
      } catch (e, st) {
        debugPrint('SanctuaryAudioService.dispose failed: $e\n$st');
      }
    }
  }
}
