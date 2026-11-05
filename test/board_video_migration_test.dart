import 'package:flutter_test/flutter_test.dart';
import 'package:positive_phill/models/board_video_preset.dart';
import 'package:positive_phill/providers/user_provider.dart';
import 'package:positive_phill/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'board_video_preset';

Future<String?> _stored() async =>
    (await SharedPreferences.getInstance()).getString(_key);

Future<BoardVideoPreset> _launch(Map<String, Object> initial) async {
  SharedPreferences.setMockInitialValues(initial);
  await StorageService.hydrateBoardVideoPresetOnLaunch();
  return StorageService.boardVideoPreset.value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    StorageService.boardVideoPreset.value = BoardVideoPreset.none;
  });

  group('first launch after upgrade', () {
    test('proven fresh install gets Rain Window', () async {
      expect(await _launch({}), BoardVideoPreset.rainWindow);
      expect(await _stored(), 'rain_window');
    });

    test('saved Rain Window is kept', () async {
      expect(await _launch({_key: 'rain_window'}), BoardVideoPreset.rainWindow);
      expect(await _stored(), 'rain_window');
    });

    test('saved Ocean Calm is kept', () async {
      expect(await _launch({_key: 'ocean_calm', 'user_progress': '{}'}),
          BoardVideoPreset.oceanCalm);
      expect(await _stored(), 'ocean_calm');
    });

    test('every saved video preset is kept', () async {
      for (final preset in BoardVideoPreset.values) {
        if (preset == BoardVideoPreset.none) continue;
        expect(await _launch({_key: preset.storageId}), preset);
        expect(await _stored(), preset.storageId);
      }
    });

    test('legacy id spelling is kept', () async {
      expect(await _launch({_key: 'forestlight'}),
          BoardVideoPreset.forestLight);
      expect(await _stored(), 'forestlight');
    });

    test('explicit none is kept', () async {
      expect(await _launch({_key: 'none'}), BoardVideoPreset.none);
      expect(await _stored(), 'none');
    });

    test('returning user with progress but no preset stays on none',
        () async {
      expect(await _launch({'user_progress': '{"xp":40}'}),
          BoardVideoPreset.none);
      expect(await _stored(), 'none');
    });

    test('any single existing preference marks a returning install',
        () async {
      final markers = <String, Object>{
        'theme_mode': 'dark',
        'accent_preset': 'ocean',
        'bg_gradient_preset': 'sunrise',
        'custom_bg_web': 'abc',
        'custom_bg_path': '/tmp/a.png',
        'custom_bg_align_x': 0.1,
        'text_backlight_enabled': false,
        'tts_enabled': false,
        'tts_speech_rate': 0.4,
        'tts_voice_name': 'v',
        'zen_mode_enabled': true,
        'notifications_enabled': true,
        'reminder_hour': 8,
        'daily_mood_value': 'calm',
        'daily_quests': '{}',
        'sanctuary_soundscape': 'rain',
        'sanctuary_volume': 0.3,
      };
      for (final entry in markers.entries) {
        expect(await _launch({entry.key: entry.value}), BoardVideoPreset.none,
            reason: entry.key);
        expect(await _stored(), 'none', reason: entry.key);
      }
    });

    test('unrecognised stored value is rewritten as none', () async {
      expect(await _launch({_key: 'old_beach'}), BoardVideoPreset.none);
      expect(await _stored(), 'none');
    });

    test('unrelated preferences are not modified', () async {
      final initial = <String, Object>{
        'user_progress': '{"xp":40}',
        'theme_mode': 'dark',
        'sanctuary_volume': 0.3,
      };
      await _launch(initial);
      final prefs = await SharedPreferences.getInstance();
      for (final entry in initial.entries) {
        expect(prefs.get(entry.key), entry.value, reason: entry.key);
      }
      expect(prefs.getKeys(), {...initial.keys, _key});
    });
  });

  group('subsequent launches', () {
    test('migration is one-time: fresh default survives later writes',
        () async {
      await _launch({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_progress', '{}');
      await StorageService.hydrateBoardVideoPresetOnLaunch();
      expect(StorageService.boardVideoPreset.value, BoardVideoPreset.rainWindow);
    });

    test('choosing None persists explicitly and survives relaunch', () async {
      await _launch({});
      await StorageService().setBoardVideoPreset(BoardVideoPreset.none);
      expect(await _stored(), 'none');
      await StorageService.hydrateBoardVideoPresetOnLaunch();
      expect(StorageService.boardVideoPreset.value, BoardVideoPreset.none);
    });

    test('Reset Progress keeps explicit None and does not enable video',
        () async {
      SharedPreferences.setMockInitialValues({
        _key: 'none',
        'user_progress': '{"xp":120}',
        'daily_quests': '{}',
      });
      final user = UserProvider();
      await user.loadProgress();
      await user.resetProgress();
      expect(await _stored(), 'none');
      await StorageService.hydrateBoardVideoPresetOnLaunch();
      expect(StorageService.boardVideoPreset.value, BoardVideoPreset.none);
      user.dispose();
    });

    test('Reset Progress keeps a saved video preset', () async {
      SharedPreferences.setMockInitialValues({
        _key: 'campfire_glow',
        'user_progress': '{"xp":120}',
      });
      await StorageService().resetProgress();
      expect(await _stored(), 'campfire_glow');
    });
  });
}
