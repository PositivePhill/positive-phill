import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemeMode();
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

  void toggleTheme() {
    if (_themeMode == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else if (_themeMode == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
      setThemeMode(brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
    }
  }
}
