import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  static final ValueNotifier<String?> customBackgroundPath = ValueNotifier<String?>(null);
  static final ValueNotifier<String?> customBackgroundWeb = ValueNotifier<String?>(null);
  static final ValueNotifier<Alignment> customBackgroundAlignment = ValueNotifier<Alignment>(Alignment.center);
  static final ValueNotifier<bool> textBacklightEnabled = ValueNotifier<bool>(true);

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
