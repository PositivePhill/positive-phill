import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:positive_phill/services/storage_service.dart';

class TtsProvider with ChangeNotifier {
  final StorageService _storage = StorageService();
  final FlutterTts _tts = FlutterTts();

  bool _voiceEnabled = true;
  double _speechRate = 0.5;
  double _pitch = 1.0;
  bool _autoRead = false;
  String? _selectedVoiceName;
  bool _isSpeaking = false;
  String? _currentText;
  List<Map<String, String>> _availableVoices = [];

  // Monotonic counter — used by speak() to defeat late cancel-handler races
  // and to skip stale calls when newer requests have already taken over.
  int _speakSeq = 0;

  bool get voiceEnabled => _voiceEnabled;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  bool get autoRead => _autoRead;
  String? get selectedVoiceName => _selectedVoiceName;
  bool get isSpeaking => _isSpeaking;
  String? get currentText => _currentText;
  List<Map<String, String>> get availableVoices => _availableVoices;

  TtsProvider() {
    _init();
  }

  Future<void> _init() async {
    await _loadSettings();
    await _applySettings();
    await _loadVoices();

    _tts.setStartHandler(() {
      _isSpeaking = true;
      notifyListeners();
    });
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      _currentText = null;
      notifyListeners();
    });
    _tts.setCancelHandler(() {
      _isSpeaking = false;
      _currentText = null;
      notifyListeners();
    });
    _tts.setErrorHandler((_) {
      _isSpeaking = false;
      _currentText = null;
      notifyListeners();
    });
  }

  Future<void> _loadSettings() async {
    _voiceEnabled = await _storage.getTtsEnabled();
    _speechRate = await _storage.getTtsSpeechRate();
    _pitch = await _storage.getTtsPitch();
    _autoRead = await _storage.getTtsAutoRead();
    _selectedVoiceName = await _storage.getTtsVoiceName();
    notifyListeners();
  }

  Future<void> _applySettings() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(_speechRate);
      await _tts.setPitch(_pitch);
      if (_selectedVoiceName != null) {
        await _tts.setVoice({'name': _selectedVoiceName!, 'locale': 'en-US'});
      }
    } catch (e) {
      debugPrint('TtsProvider: failed to apply settings: $e');
    }
  }

  Future<void> _loadVoices() async {
    if (kIsWeb) return;
    try {
      final raw = await _tts.getVoices;
      if (raw == null) return;
      final parsed = <Map<String, String>>[];
      for (final v in raw) {
        if (v is Map) {
          final name = v['name']?.toString() ?? '';
          final locale = v['locale']?.toString() ?? '';
          if (name.isNotEmpty) {
            parsed.add({'name': name, 'locale': locale});
          }
        }
      }
      _availableVoices = parsed;
      notifyListeners();
    } catch (e) {
      debugPrint('TtsProvider: could not load voices: $e');
    }
  }

  Future<void> speak(String text) async {
    if (!_voiceEnabled || text.trim().isEmpty) return;
    final mySeq = ++_speakSeq;
    try {
      // Stop any in-flight speech. On web the underlying SpeechSynthesis
      // needs a brief moment after cancel() before a new speak() will
      // actually start, otherwise the browser drops the new request.
      await _tts.stop();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      // Bail out if a newer speak() request has already superseded this one.
      if (mySeq != _speakSeq) return;
      _currentText = text;
      notifyListeners();
      await _tts.speak(text.trim());
    } catch (e) {
      debugPrint('TtsProvider: speak error: $e');
      if (mySeq == _speakSeq) {
        _isSpeaking = false;
        _currentText = null;
        notifyListeners();
      }
    }
  }

  Future<void> stop() async {
    // Invalidate any in-flight speak() so its post-delay continuation aborts.
    _speakSeq++;
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('TtsProvider: stop error: $e');
    }
    _isSpeaking = false;
    _currentText = null;
    notifyListeners();
  }

  Future<void> setVoiceEnabled(bool value) async {
    _voiceEnabled = value;
    if (!value) await stop();
    notifyListeners();
    await _storage.setTtsEnabled(value);
  }

  Future<void> setSpeechRate(double value) async {
    _speechRate = value;
    notifyListeners();
    try {
      await _tts.setSpeechRate(value);
    } catch (_) {}
    await _storage.setTtsSpeechRate(value);
  }

  Future<void> setPitch(double value) async {
    _pitch = value;
    notifyListeners();
    try {
      await _tts.setPitch(value);
    } catch (_) {}
    await _storage.setTtsPitch(value);
  }

  Future<void> setAutoRead(bool value) async {
    _autoRead = value;
    notifyListeners();
    await _storage.setTtsAutoRead(value);
  }

  Future<void> setVoice(String name, String locale) async {
    _selectedVoiceName = name;
    notifyListeners();
    try {
      await _tts.setVoice({'name': name, 'locale': locale});
    } catch (_) {}
    await _storage.setTtsVoiceName(name);
  }

  Future<void> preview() async {
    await speak('Positive thoughts guide my path forward.');
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _tts.stop();
    }
    super.dispose();
  }
}
