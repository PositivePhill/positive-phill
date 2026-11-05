import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:positive_phill/models/board_video_preset.dart';
import 'package:positive_phill/providers/quest_provider.dart';
import 'package:positive_phill/providers/tts_provider.dart';
import 'package:positive_phill/providers/user_provider.dart';
import 'package:positive_phill/screens/home_screen.dart';
import 'package:positive_phill/services/storage_service.dart';
import 'package:positive_phill/widgets/board_video_background.dart';
import 'package:positive_phill/widgets/board_video_poster.dart';
import 'package:positive_phill/widgets/reduce_motion.dart';

import 'helpers/test_harness.dart';

// The test platform has no video implementation, so the mounted player's
// init fails asynchronously after its first frame: an idle-time failure.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(
        {'board_video_preset': 'rain_window'});
    StorageService.reduceMotion.value = false;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
        const MethodChannel('flutter_tts'), (_) async => null);
    messenger.setMockMessageHandler('plugins.flutter.io/google_mobile_ads',
        (_) async => const StandardMethodCodec().encodeSuccessEnvelope(null));
  });

  Widget home() => MultiProvider(
        providers: [
          ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
          ChangeNotifierProvider<TtsProvider>(create: (_) => TtsProvider()),
          ChangeNotifierProvider<QuestProvider>(create: (_) => QuestProvider()),
        ],
        child: ReduceMotion(
          child: MaterialApp(
            theme: testTheme(Brightness.light),
            builder: ReduceMotion.appBuilder,
            home: const HomeScreen(),
          ),
        ),
      );

  Future<void> pumpUntilVideoMounted(WidgetTester tester) async {
    await tester.runAsync(StorageService.hydrateBoardVideoPresetOnLaunch);
    setLogicalSize(tester, 390, height: 1600);
    await tester.pumpWidget(home());
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(BoardVideoBackground).evaluate().isNotEmpty) return;
    }
    fail('video layer never mounted');
  }

  Future<String?> storedPreset() async =>
      (await SharedPreferences.getInstance()).getString('board_video_preset');

  testWidgets(
      'an idle-time playback failure requests its own frame and falls back '
      'to the poster without user interaction', (tester) async {
    await pumpUntilVideoMounted(tester);

    // Let the failing init settle without drawing a frame.
    await tester.idle();
    expect(tester.binding.hasScheduledFrame, isTrue,
        reason: 'the failure must schedule the frame that reports it');

    // Frame-only pumps: no time advance, taps or other input.
    await tester.pump();
    await tester.pump();
    expect(find.byType(BoardVideoBackground), findsNothing);
    expect(find.byType(BoardVideoPoster), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(await storedPreset(), 'rain_window');
    expect(StorageService.boardVideoPreset.value, BoardVideoPreset.rainWindow);
  });

  testWidgets('a failure reported after Home unmounts changes nothing',
      (tester) async {
    await pumpUntilVideoMounted(tester);

    // Unmount before the deferred failure report can run.
    await tester.pumpWidget(const SizedBox.shrink());
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
    expect(await storedPreset(), 'rain_window');
    expect(StorageService.boardVideoPreset.value, BoardVideoPreset.rainWindow);
  });
}
