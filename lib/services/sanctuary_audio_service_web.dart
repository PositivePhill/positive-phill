// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:positive_phill/models/sanctuary_soundscape.dart';

/// Uses [html.AudioElement] so Sanctuary Sounds works on Flutter Web builds
/// (no `audioplayers` MethodChannel plugins on GitHub Pages).
///
/// Playback only starts via [play] (user gesture orchestrated by UI).
class SanctuaryAudioService {
  html.AudioElement? _audio;

  bool get hasPlayer => _audio != null;

  String _resolvedSrc(SanctuarySoundscape sound) {
    final relative = sound.webAssetUrl;
    final baseUri = html.document.baseUri ?? '';
    if (baseUri.isEmpty) return relative;
    return Uri.parse(baseUri).resolve(relative).toString();
  }

  Future<void> play(SanctuarySoundscape sound, double volume) async {
    final v = volume.clamp(0.0, 1.0);
    try {
      await disposeAsync();

      final a = html.AudioElement();
      _audio = a;

      a
        ..src = _resolvedSrc(sound)
        ..loop = true
        ..volume = v;

      await a.play();
    } catch (e, st) {
      debugPrint('SanctuaryAudioService (web).play failed: $e\n$st');
      try {
        await disposeAsync();
      } catch (_) {}
    }
  }

  Future<void> setVolume(double volume) async {
    final v = volume.clamp(0.0, 1.0);
    try {
      final a = _audio;
      if (a != null) {
        a.volume = v;
      }
    } catch (e, st) {
      debugPrint('SanctuaryAudioService (web).setVolume failed: $e\n$st');
    }
  }

  Future<void> stop() async {
    try {
      final a = _audio;
      if (a != null) {
        a.pause();
        a.currentTime = 0;
      }
    } catch (e, st) {
      debugPrint('SanctuaryAudioService (web).stop failed: $e\n$st');
    }
  }

  Future<void> disposeAsync() async {
    try {
      final a = _audio;
      _audio = null;
      if (a != null) {
        a.pause();
        a.currentTime = 0;
        a.src = '';
        a.load();
      }
    } catch (e, st) {
      debugPrint('SanctuaryAudioService (web).dispose failed: $e\n$st');
    }
  }
}
