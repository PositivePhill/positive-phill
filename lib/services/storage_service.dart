import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:positive_phill/models/background_gradient_preset.dart';
import 'package:positive_phill/models/board_video_preset.dart';
import 'package:positive_phill/models/user_progress.dart';

class StorageService {
  static const String _userProgressKey = 'user_progress';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _reminderHourKey = 'reminder_hour';
  static const String _reminderMinuteKey = 'reminder_minute';
  static const String _customBgPathKey = 'custom_bg_path';
  static const String _customBgWebKey = 'custom_bg_web';
  static const String _customBgAlignXKey = 'custom_bg_align_x';
  static const String _customBgAlignYKey = 'custom_bg_align_y';
  static const String _textBacklightEnabledKey = 'text_backlight_enabled';
  static const String _ttsEnabledKey = 'tts_enabled';
  static const String _ttsSpeechRateKey = 'tts_speech_rate';
  static const String _ttsPitchKey = 'tts_pitch';
  static const String _ttsAutoReadKey = 'tts_auto_read';
  static const String _ttsVoiceNameKey = 'tts_voice_name';
  static const String _zenModeEnabledKey = 'zen_mode_enabled';
  static const String _dailyMoodValueKey = 'daily_mood_value';
  static const String _dailyMoodDateKey = 'daily_mood_date';
  static const String _dailyQuestsKey = 'daily_quests';
  static const String _backgroundGradientPresetKey = 'bg_gradient_preset';
  static const String _boardVideoPresetKey = 'board_video_preset';

  /// Last chosen ambient loop id (`SanctuarySoundscape.storageId`).
  /// Playing state is not persisted.
  static const String sanctuarySoundscape = 'sanctuary_soundscape';

  /// Ambience volume clamped 0–1 when stored.
  static const String sanctuaryVolume = 'sanctuary_volume';

  static final ValueNotifier<String?> customBackgroundPath = ValueNotifier<String?>(null);
  static final ValueNotifier<String?> customBackgroundWeb = ValueNotifier<String?>(null);
  static final ValueNotifier<Alignment> customBackgroundAlignment = ValueNotifier<Alignment>(Alignment.center);
  static final ValueNotifier<bool> textBacklightEnabled = ValueNotifier<bool>(true);
  static final ValueNotifier<BackgroundGradientPreset> backgroundGradientPreset =
      ValueNotifier<BackgroundGradientPreset>(BackgroundGradientPreset.none);

  static final ValueNotifier<BoardVideoPreset> boardVideoPreset =
      ValueNotifier<BoardVideoPreset>(BoardVideoPreset.none);

  /// Call once during cold start ([main]) before [runApp] so Home (and widgets
  /// that subscribe to [boardVideoPreset]) see persisted prefs on the first frame.
  static Future<void> hydrateBoardVideoPresetOnLaunch() async {
    await StorageService().getBoardVideoPreset();
  }

  Future<UserProgress> loadUserProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_userProgressKey);
      
      if (jsonString == null) {
        return const UserProgress();
      }
      
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserProgress.fromJson(json);
    } catch (e) {
      debugPrint('Failed to load user progress: $e');
      return const UserProgress();
    }
  }

  Future<void> saveUserProgress(UserProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(progress.toJson());
      await prefs.setString(_userProgressKey, jsonString);
    } catch (e) {
      debugPrint('Failed to save user progress: $e');
    }
  }

  Future<void> resetProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userProgressKey);
      await prefs.remove(_dailyMoodValueKey);
      await prefs.remove(_dailyMoodDateKey);
      await prefs.remove(_dailyQuestsKey);
    } catch (e) {
      debugPrint('Failed to reset progress: $e');
    }
  }

  Future<bool> getNotificationsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_notificationsEnabledKey) ?? false;
    } catch (e) {
      debugPrint('Failed to load notifications enabled: $e');
      return false;
    }
  }

  Future<void> setNotificationsEnabled(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationsEnabledKey, value);
    } catch (e) {
      debugPrint('Failed to save notifications enabled: $e');
    }
  }

  Future<int> getReminderHour() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_reminderHourKey) ?? 9;
    } catch (e) {
      debugPrint('Failed to load reminder hour: $e');
      return 9;
    }
  }

  Future<int> getReminderMinute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_reminderMinuteKey) ?? 0;
    } catch (e) {
      debugPrint('Failed to load reminder minute: $e');
      return 0;
    }
  }

  Future<void> setReminderTime(int hour, int minute) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_reminderHourKey, hour);
      await prefs.setInt(_reminderMinuteKey, minute);
    } catch (e) {
      debugPrint('Failed to save reminder time: $e');
    }
  }

  Future<String?> getCustomBackgroundPath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_customBgPathKey);
    } catch (e) {
      debugPrint('Failed to load custom background path: $e');
      return null;
    }
  }

  Future<void> setCustomBackgroundPath(String? path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (path == null) {
        await prefs.remove(_customBgPathKey);
      } else {
        await prefs.setString(_customBgPathKey, path);
        await setCustomBackgroundAlignment(Alignment.center);
      }
      customBackgroundPath.value = path;
    } catch (e) {
      debugPrint('Failed to save custom background path: $e');
    }
  }

  Future<String?> getCustomBackgroundWeb() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_customBgWebKey);
    } catch (e) {
      debugPrint('Failed to load custom background web: $e');
      return null;
    }
  }

  Future<void> setCustomBackgroundWeb(String? base64) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (base64 == null) {
        await prefs.remove(_customBgWebKey);
      } else {
        await prefs.setString(_customBgWebKey, base64);
        await setCustomBackgroundAlignment(Alignment.center);
      }
      customBackgroundWeb.value = base64;
    } catch (e) {
      debugPrint('Failed to save custom background web: $e');
    }
  }

  Future<BackgroundGradientPreset> getBackgroundGradientPreset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_backgroundGradientPresetKey);
      final preset = BackgroundGradientPreset.fromStorage(raw);
      backgroundGradientPreset.value = preset;
      return preset;
    } catch (e) {
      debugPrint('Failed to load background gradient preset: $e');
      backgroundGradientPreset.value = BackgroundGradientPreset.none;
      return BackgroundGradientPreset.none;
    }
  }

  Future<void> setBackgroundGradientPreset(BackgroundGradientPreset preset) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_backgroundGradientPresetKey, preset.storageName);
      backgroundGradientPreset.value = preset;
    } catch (e) {
      debugPrint('Failed to save background gradient preset: $e');
    }
  }

  Future<BoardVideoPreset> getBoardVideoPreset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_boardVideoPresetKey);
      final preset = BoardVideoPreset.fromStorageId(raw);
      final invalidStored = raw != null &&
          raw.trim().isNotEmpty &&
          preset == BoardVideoPreset.none;
      if (invalidStored) {
        await prefs.remove(_boardVideoPresetKey);
      }
      final previous = boardVideoPreset.value;
      boardVideoPreset.value = preset;
      if (kDebugMode && preset != previous) {
        debugPrint(
          'StorageService hydrated board video preset: ${preset.name}',
        );
      }
      return preset;
    } catch (e) {
      debugPrint('Failed to load board_video_preset: $e');
      boardVideoPreset.value = BoardVideoPreset.none;
      return BoardVideoPreset.none;
    }
  }

  Future<void> setBoardVideoPreset(BoardVideoPreset preset) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (preset == BoardVideoPreset.none) {
        await prefs.remove(_boardVideoPresetKey);
      } else {
        await prefs.setString(_boardVideoPresetKey, preset.storageId);
      }
      boardVideoPreset.value = preset;
      if (kDebugMode) {
        if (preset == BoardVideoPreset.none) {
          debugPrint('setBoardVideoPreset saved: none (key removed)');
        } else {
          debugPrint('setBoardVideoPreset saved: ${preset.storageId}');
        }
      }
    } catch (e) {
      debugPrint('Failed to save board_video_preset: $e');
    }
  }

  Future<Alignment> getCustomBackgroundAlignment() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final x = prefs.getDouble(_customBgAlignXKey) ?? 0.0;
      final y = prefs.getDouble(_customBgAlignYKey) ?? 0.0;
      final align = Alignment(
        x.clamp(-1.0, 1.0),
        y.clamp(-1.0, 1.0),
      );
      customBackgroundAlignment.value = align;
      return align;
    } catch (e) {
      debugPrint('Failed to load custom background alignment: $e');
      return Alignment.center;
    }
  }

  Future<void> setCustomBackgroundAlignment(Alignment align) async {
    try {
      final x = align.x.clamp(-1.0, 1.0);
      final y = align.y.clamp(-1.0, 1.0);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_customBgAlignXKey, x);
      await prefs.setDouble(_customBgAlignYKey, y);
      customBackgroundAlignment.value = Alignment(x, y);
    } catch (e) {
      debugPrint('Failed to save custom background alignment: $e');
    }
  }

  Future<bool> getTextBacklightEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getBool(_textBacklightEnabledKey) ?? true;
      textBacklightEnabled.value = value;
      return value;
    } catch (e) {
      debugPrint('Failed to load text backlight: $e');
      return true;
    }
  }

  Future<void> setTextBacklightEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_textBacklightEnabledKey, enabled);
      textBacklightEnabled.value = enabled;
    } catch (e) {
      debugPrint('Failed to save text backlight: $e');
    }
  }

  Future<bool> getTtsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_ttsEnabledKey) ?? true;
    } catch (e) {
      debugPrint('Failed to load tts enabled: $e');
      return true;
    }
  }

  Future<void> setTtsEnabled(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_ttsEnabledKey, value);
    } catch (e) {
      debugPrint('Failed to save tts enabled: $e');
    }
  }

  Future<double> getTtsSpeechRate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_ttsSpeechRateKey) ?? 0.5;
    } catch (e) {
      debugPrint('Failed to load tts speech rate: $e');
      return 0.5;
    }
  }

  Future<void> setTtsSpeechRate(double value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_ttsSpeechRateKey, value);
    } catch (e) {
      debugPrint('Failed to save tts speech rate: $e');
    }
  }

  Future<double> getTtsPitch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_ttsPitchKey) ?? 1.0;
    } catch (e) {
      debugPrint('Failed to load tts pitch: $e');
      return 1.0;
    }
  }

  Future<void> setTtsPitch(double value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_ttsPitchKey, value);
    } catch (e) {
      debugPrint('Failed to save tts pitch: $e');
    }
  }

  Future<bool> getTtsAutoRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_ttsAutoReadKey) ?? false;
    } catch (e) {
      debugPrint('Failed to load tts auto read: $e');
      return false;
    }
  }

  Future<void> setTtsAutoRead(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_ttsAutoReadKey, value);
    } catch (e) {
      debugPrint('Failed to save tts auto read: $e');
    }
  }

  Future<String?> getTtsVoiceName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_ttsVoiceNameKey);
    } catch (e) {
      debugPrint('Failed to load tts voice name: $e');
      return null;
    }
  }

  Future<void> setTtsVoiceName(String? value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value == null) {
        await prefs.remove(_ttsVoiceNameKey);
      } else {
        await prefs.setString(_ttsVoiceNameKey, value);
      }
    } catch (e) {
      debugPrint('Failed to save tts voice name: $e');
    }
  }

  Future<bool> getZenModeEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_zenModeEnabledKey) ?? false;
    } catch (e) {
      debugPrint('Failed to load zen mode: $e');
      return false;
    }
  }

  Future<void> setZenModeEnabled(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_zenModeEnabledKey, value);
    } catch (e) {
      debugPrint('Failed to save zen mode: $e');
    }
  }

  // ── Mood ──────────────────────────────────────────────────────────────────

  Future<String?> getDailyMoodValue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_dailyMoodValueKey);
    } catch (e) {
      debugPrint('Failed to load daily mood value: $e');
      return null;
    }
  }

  Future<String?> getDailyMoodDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_dailyMoodDateKey);
    } catch (e) {
      debugPrint('Failed to load daily mood date: $e');
      return null;
    }
  }

  Future<void> setDailyMood(String moodName, String dateString) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dailyMoodValueKey, moodName);
      await prefs.setString(_dailyMoodDateKey, dateString);
    } catch (e) {
      debugPrint('Failed to save daily mood: $e');
    }
  }

  Future<void> clearDailyMood() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_dailyMoodValueKey);
      await prefs.remove(_dailyMoodDateKey);
    } catch (e) {
      debugPrint('Failed to clear daily mood: $e');
    }
  }

  // ── Quests ────────────────────────────────────────────────────────────────

  Future<String?> getDailyQuestsJson() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_dailyQuestsKey);
    } catch (e) {
      debugPrint('Failed to load daily quests: $e');
      return null;
    }
  }

  Future<void> setDailyQuestsJson(String json) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dailyQuestsKey, json);
    } catch (e) {
      debugPrint('Failed to save daily quests: $e');
    }
  }

  Future<void> clearDailyQuests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_dailyQuestsKey);
    } catch (e) {
      debugPrint('Failed to clear daily quests: $e');
    }
  }

  // ── Sanctuary Sounds (ambient audio) ────────────────────────────────────

  Future<String?> getSanctuarySoundscape() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(sanctuarySoundscape);
    } catch (e) {
      debugPrint('Failed to load sanctuary_soundscape: $e');
      return null;
    }
  }

  /// Persists chosen soundscape id (`SanctuarySoundscape.storageId`).
  /// Clearing selection is not surfaced in UI v1.3 — pass null to remove key if needed later.
  Future<void> setSanctuarySoundscape(String? id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (id == null || id.trim().isEmpty) {
        await prefs.remove(sanctuarySoundscape);
      } else {
        await prefs.setString(sanctuarySoundscape, id.trim());
      }
    } catch (e) {
      debugPrint('Failed to save sanctuary_soundscape: $e');
    }
  }

  Future<double> getSanctuaryVolume() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getDouble(sanctuaryVolume);
      if (v == null) return 0.45;
      return v.clamp(0.0, 1.0);
    } catch (e) {
      debugPrint('Failed to load sanctuary_volume: $e');
      return 0.45;
    }
  }

  Future<void> setSanctuaryVolume(double value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(sanctuaryVolume, value.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('Failed to save sanctuary_volume: $e');
    }
  }

  Future<void> clearCustomBackground() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_customBgPathKey);
      await prefs.remove(_customBgWebKey);
      await prefs.remove(_customBgAlignXKey);
      await prefs.remove(_customBgAlignYKey);
      customBackgroundPath.value = null;
      customBackgroundWeb.value = null;
      customBackgroundAlignment.value = Alignment.center;
    } catch (e) {
      debugPrint('Failed to clear custom background: $e');
    }
  }
}
