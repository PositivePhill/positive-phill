import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:positive_phill/models/accent_preset.dart';
import 'package:positive_phill/theme.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _accentPresetKey = 'accent_preset';

  ThemeMode _themeMode = ThemeMode.system;
  AccentPreset _accentPreset = AccentPreset.lavender;

  ThemeMode get themeMode => _themeMode;

  AccentPreset get accentPreset => _accentPreset;

  ThemeData get lightThemeData => lightThemeForAccent(_accentPreset);

  ThemeData get darkThemeData => darkThemeForAccent(_accentPreset);

  ThemeProvider() {
    _loadThemeMode();
    _loadAccentPreset();
  }

  Future<void> _loadThemeMode() async {
    ThemeMode resolved = ThemeMode.system;

    try {
      final prefs = await SharedPreferences.getInstance();
      final Object? raw = prefs.get(_themeModeKey);

      if (raw is String) {
        if (raw == ThemeMode.light.name) {
          resolved = ThemeMode.light;
        } else if (raw == ThemeMode.dark.name) {
          resolved = ThemeMode.dark;
        } else {
          resolved = ThemeMode.system;
        }
      } else if (raw is int) {
        // 🔁 Legacy migration (old builds stored index)
        if (raw == ThemeMode.light.index) {
          resolved = ThemeMode.light;
        } else if (raw == ThemeMode.dark.index) {
          resolved = ThemeMode.dark;
        } else {
          resolved = ThemeMode.system;
        }

        // Persist migrated value as string
        await prefs.setString(_themeModeKey, resolved.name);
      } else {
        resolved = ThemeMode.system;
      }
    } catch (e) {
      resolved = ThemeMode.system;
    }

    _themeMode = resolved;
    notifyListeners();
  }

  Future<void> _loadAccentPreset() async {
    AccentPreset resolved = AccentPreset.lavender;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_accentPresetKey);
      resolved = AccentPreset.fromStorage(raw);
    } catch (_) {
      resolved = AccentPreset.lavender;
    }
    _accentPreset = resolved;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, mode.name);
    } catch (e) {
      // Fail silently
    }
  }

  Future<void> setAccentPreset(AccentPreset preset) async {
    _accentPreset = preset;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accentPresetKey, preset.storageName);
    } catch (_) {
      // Fail silently
    }
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else if (_themeMode == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      final brightness =
          SchedulerBinding.instance.platformDispatcher.platformBrightness;
      setThemeMode(brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
    }
  }
}
