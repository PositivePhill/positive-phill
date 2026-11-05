import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:positive_phill/models/affirmation.dart';
import 'package:positive_phill/models/board_video_preset.dart';
import 'package:positive_phill/models/daily_quests.dart';
import 'package:positive_phill/providers/quest_provider.dart';
import 'package:positive_phill/providers/tts_provider.dart';
import 'package:positive_phill/providers/user_provider.dart';
import 'package:positive_phill/screens/home_screen.dart';
import 'package:positive_phill/screens/session_flow_screen.dart';
import 'package:positive_phill/services/storage_service.dart';
import 'package:positive_phill/widgets/affirmation_card.dart';
import 'package:positive_phill/widgets/board_video_background.dart';
import 'package:positive_phill/widgets/board_video_poster.dart';
import 'package:positive_phill/widgets/celebration_animation.dart';
import 'package:positive_phill/widgets/daily_quest_card.dart';
import 'package:positive_phill/widgets/level_up_toast.dart';
import 'package:positive_phill/widgets/reduce_motion.dart';

import 'helpers/test_harness.dart';

const _key = 'reduce_motion';

void _setSystem(WidgetTester tester,
    {bool disableAnimations = false, bool reduceMotion = false}) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(
    disableAnimations: disableAnimations,
    reduceMotion: reduceMotion,
  );
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

/// Mirrors main.dart: scope above MaterialApp, appBuilder below it.
Widget _app(Widget home, {List<ChangeNotifierProvider>? providers}) {
  Widget app = ReduceMotion(
    child: MaterialApp(
      theme: testTheme(Brightness.light),
      builder: ReduceMotion.appBuilder,
      home: home,
    ),
  );
  if (providers != null) app = MultiProvider(providers: providers, child: app);
  return app;
}

class _Probe extends StatelessWidget {
  const _Probe(this.onBuild);
  final void Function(BuildContext context) onBuild;
  @override
  Widget build(BuildContext context) {
    onBuild(context);
    return const SizedBox.shrink();
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.reduceMotion.value = false;
    StorageService.boardVideoPreset.value = BoardVideoPreset.none;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
        const MethodChannel('flutter_tts'), (_) async => null);
    messenger.setMockMessageHandler('plugins.flutter.io/google_mobile_ads',
        (_) async => const StandardMethodCodec().encodeSuccessEnvelope(null));
  });

  group('effective policy', () {
    for (final sysDisable in [false, true]) {
      for (final sysReduce in [false, true]) {
        for (final user in [false, true]) {
          testWidgets(
              'disableAnimations=$sysDisable reduceMotion=$sysReduce '
              'user=$user', (tester) async {
            _setSystem(tester,
                disableAnimations: sysDisable, reduceMotion: sysReduce);
            StorageService.reduceMotion.value = user;
            late bool reduced, system, mediaQuery;
            await tester.pumpWidget(_app(_Probe((context) {
              reduced = ReduceMotion.of(context);
              system = ReduceMotion.systemRequestOf(context);
              mediaQuery = MediaQuery.disableAnimationsOf(context);
            })));
            expect(reduced, sysDisable || sysReduce || user);
            expect(system, sysDisable || sysReduce);
            expect(mediaQuery, reduced,
                reason: 'MediaQuery must mirror the effective value');
          });
        }
      }
    }

    testWidgets('follows live system accessibility changes', (tester) async {
      late bool reduced;
      await tester.pumpWidget(
          _app(_Probe((context) => reduced = ReduceMotion.of(context))));
      expect(reduced, isFalse);

      _setSystem(tester, reduceMotion: true);
      await tester.pump();
      expect(reduced, isTrue, reason: 'iOS-style reduceMotion');

      _setSystem(tester, disableAnimations: true);
      await tester.pump();
      expect(reduced, isTrue, reason: 'Android-style disableAnimations');

      tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      await tester.pump();
      expect(reduced, isFalse);
    });

    testWidgets('follows the in-app toggle and persists it', (tester) async {
      late bool reduced;
      await tester.pumpWidget(
          _app(_Probe((context) => reduced = ReduceMotion.of(context))));
      expect(reduced, isFalse);

      await tester.runAsync(() => StorageService().setReduceMotion(true));
      await tester.pump();
      expect(reduced, isTrue);
      var prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(_key), isTrue);

      await tester.runAsync(() => StorageService().setReduceMotion(false));
      await tester.pump();
      expect(reduced, isFalse);
      prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(_key), isFalse, reason: 'explicit off is stored');
    });

    testWidgets('route transitions are instant only when reduced',
        (tester) async {
      Future<AnimationStatus> pushAndSample() async {
        final navigator = tester.state<NavigatorState>(find.byType(Navigator));
        navigator.push(MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('next'))));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
        final route =
            ModalRoute.of(tester.element(find.text('next')))! as PageRoute;
        final status = route.animation!.status;
        await tester.pumpAndSettle();
        navigator.pop();
        await tester.pumpAndSettle();
        return status;
      }

      await tester.pumpWidget(_app(const Scaffold(body: Text('home'))));
      expect(await pushAndSample(), AnimationStatus.forward);

      StorageService.reduceMotion.value = true;
      await tester.pump();
      expect(await pushAndSample(), AnimationStatus.completed);
    });
  });

  group('persistence', () {
    test('first launch defaults to off without writing the key', () async {
      await StorageService.hydrateReduceMotionOnLaunch();
      expect(StorageService.reduceMotion.value, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(_key), isFalse);
    });

    test('saved preference is restored on launch', () async {
      SharedPreferences.setMockInitialValues({_key: true});
      await StorageService.hydrateReduceMotionOnLaunch();
      expect(StorageService.reduceMotion.value, isTrue);
    });

    test('toggle never touches the background preset or other keys', () async {
      SharedPreferences.setMockInitialValues({
        'board_video_preset': 'ocean_calm',
        'theme_mode': 'dark',
        'user_progress': '{"xp":40}',
      });
      await StorageService().setReduceMotion(true);
      await StorageService().setReduceMotion(false);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('board_video_preset'), 'ocean_calm');
      expect(prefs.getString('theme_mode'), 'dark');
      expect(prefs.getString('user_progress'), '{"xp":40}');
    });

    test('Reset Progress keeps the motion preference', () async {
      SharedPreferences.setMockInitialValues({
        _key: true,
        'user_progress': '{"xp":40}',
      });
      await StorageService().resetProgress();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(_key), isTrue);
    });

    test('a saved motion preference marks a returning install', () async {
      SharedPreferences.setMockInitialValues({_key: true});
      await StorageService.hydrateBoardVideoPresetOnLaunch();
      expect(StorageService.boardVideoPreset.value, BoardVideoPreset.none);
    });
  });

  group('Home background video', () {
    Future<void> pumpHome(WidgetTester tester, String preset) async {
      SharedPreferences.setMockInitialValues({'board_video_preset': preset});
      await tester.runAsync(StorageService.hydrateBoardVideoPresetOnLaunch);
      setLogicalSize(tester, 390, height: 1600);
      await tester.pumpWidget(_app(
        const HomeScreen(),
        providers: [
          ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
          ChangeNotifierProvider<TtsProvider>(create: (_) => TtsProvider()),
          ChangeNotifierProvider<QuestProvider>(create: (_) => QuestProvider()),
        ],
      ));
    }

    /// Pumps frame by frame, asserting the video is never built on any frame.
    Future<void> expectNoVideoFor(WidgetTester tester, Duration total) async {
      const step = Duration(milliseconds: 100);
      for (var t = Duration.zero; t < total; t += step) {
        await tester.pump(step);
        expect(find.byType(BoardVideoBackground), findsNothing,
            reason: 'video built at $t');
      }
    }

    Future<String?> storedPreset() async =>
        (await SharedPreferences.getInstance()).getString('board_video_preset');

    testWidgets('reduced motion shows the poster and never mounts video',
        (tester) async {
      StorageService.reduceMotion.value = true;
      await pumpHome(tester, 'rain_window');
      await expectNoVideoFor(tester, const Duration(seconds: 4));
      expect(find.byType(BoardVideoPoster), findsOneWidget);
      expect(await storedPreset(), 'rain_window');
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'toggling motion disposes and restores the video without '
        'duplicates or preference changes', (tester) async {
      await pumpHome(tester, 'ocean_calm');
      // Wait for the poster-gated mount (precache times out at 2 s in tests).
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byType(BoardVideoBackground).evaluate().isNotEmpty) break;
      }
      expect(find.byType(BoardVideoBackground), findsOneWidget);

      // Reduce Motion on mid-session: the video goes away before its
      // (test-platform) init failure can report back.
      StorageService.reduceMotion.value = true;
      await tester.pump();
      expect(find.byType(BoardVideoBackground), findsNothing);
      expect(find.byType(BoardVideoPoster), findsOneWidget);
      await expectNoVideoFor(tester, const Duration(seconds: 1));

      // Motion back on: exactly one fresh video layer for the saved preset.
      StorageService.reduceMotion.value = false;
      await tester.pump();
      expect(find.byType(BoardVideoBackground), findsOneWidget);
      final video = tester
          .widget<BoardVideoBackground>(find.byType(BoardVideoBackground));
      expect(video.preset, BoardVideoPreset.oceanCalm);

      expect(tester.takeException(), isNull);
      expect(await storedPreset(), 'ocean_calm');
      expect(StorageService.boardVideoPreset.value, BoardVideoPreset.oceanCalm);
    });

    testWidgets('session-only video failure is independent of the toggle',
        (tester) async {
      await pumpHome(tester, 'rain_window');
      // Let the test platform's video init fail and be recorded.
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(BoardVideoBackground), findsNothing);

      StorageService.reduceMotion.value = true;
      await tester.pump();
      StorageService.reduceMotion.value = false;
      await tester.pump();
      await tester.pump();
      expect(find.byType(BoardVideoBackground), findsNothing,
          reason: 'failed preset stays on its poster for the session');
      expect(find.byType(BoardVideoPoster), findsOneWidget);
      expect(await storedPreset(), 'rain_window');
    });

    testWidgets('explicit None stays None under reduced motion',
        (tester) async {
      StorageService.reduceMotion.value = true;
      await pumpHome(tester, 'none');
      await expectNoVideoFor(tester, const Duration(seconds: 3));
      expect(find.byType(BoardVideoPoster), findsNothing);
      expect(await storedPreset(), 'none');
    });
  });

  group('feedback without motion', () {
    testWidgets('level-up toast is static and stays readable', (tester) async {
      _setSystem(tester, disableAnimations: true);
      await tester.pumpWidget(_app(Builder(
        builder: (context) => TextButton(
          onPressed: () => LevelUpToast.show(context, 7),
          child: const Text('go'),
        ),
      )));
      await tester.tap(find.text('go'));
      await tester.pump(const Duration(milliseconds: 16));

      final opacity = tester.widget<Opacity>(find.ancestor(
          of: find.text('Level Up!'), matching: find.byType(Opacity)));
      expect(opacity.opacity, 1.0);
      final scale = tester.widget<Transform>(find
          .ancestor(
              of: find.text('Level Up!'), matching: find.byType(Transform))
          .first);
      expect(scale.transform.getMaxScaleOnAxis(), closeTo(1.0, 1e-9));

      // Platform "remove animations" would normally shorten the controller;
      // the toast must still be on screen well into its 2.5 s window.
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('You reached Level 7'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Level Up!'), findsNothing);
    });

    testWidgets('level-up toast still animates when motion is allowed',
        (tester) async {
      await tester.pumpWidget(_app(Builder(
        builder: (context) => TextButton(
          onPressed: () => LevelUpToast.show(context, 3),
          child: const Text('go'),
        ),
      )));
      await tester.tap(find.text('go'));
      await tester.pump(const Duration(milliseconds: 16));
      final opacity = tester.widget<Opacity>(find.ancestor(
          of: find.text('Level Up!'), matching: find.byType(Opacity)));
      expect(opacity.opacity, lessThan(1.0));
      await tester.pump(const Duration(seconds: 3));
    });

    for (final reduced in [true, false]) {
      testWidgets(
          'confetti ${reduced ? 'skipped' : 'plays'} when '
          'reduceMotion=$reduced', (tester) async {
        StorageService.reduceMotion.value = reduced;
        Widget celebration(bool trigger) => _app(CelebrationAnimation(
              trigger: trigger,
              child: const Text('done'),
            ));
        await tester.pumpWidget(celebration(false));
        await tester.pumpWidget(celebration(true));
        await tester.pump(const Duration(milliseconds: 50));
        final controller = tester
            .widget<ConfettiWidget>(find.byType(ConfettiWidget))
            .confettiController;
        expect(
            controller.state,
            reduced
                ? ConfettiControllerState.stopped
                : ConfettiControllerState.playing);
        expect(find.text('done'), findsOneWidget);
        await tester.pump(const Duration(seconds: 4));
      });
    }

    testWidgets('quest checkmark and session card switch instantly',
        (tester) async {
      StorageService.reduceMotion.value = true;
      setLogicalSize(tester, 390, height: 1200);
      await tester.pumpWidget(_app(
        Scaffold(
          body: Column(children: [
            const DailyQuestCard(),
            CategoryCard(
              category: AffirmationCategory.calm,
              isSelected: true,
              onTap: () {},
            ),
          ]),
        ),
        providers: [
          ChangeNotifierProvider<QuestProvider>(create: (_) => QuestProvider()),
        ],
      ));
      for (final s in tester
          .widgetList<AnimatedSwitcher>(find.byType(AnimatedSwitcher))) {
        expect(s.duration, Duration.zero);
      }
      expect(
          tester
              .widget<AnimatedContainer>(find.byType(AnimatedContainer))
              .duration,
          Duration.zero);
    });

    for (final reduced in [false, true]) {
      testWidgets(
          'favoriting awards the same XP and quest with reduceMotion=$reduced',
          (tester) async {
        StorageService.reduceMotion.value = reduced;
        final user = UserProvider();
        final quests = QuestProvider();
        setLogicalSize(tester, 390);
        await tester.pumpWidget(_app(
          const SizedBox(
            height: 500,
            child: AffirmationCard(
              affirmation: Affirmation(
                id: 'rm-1',
                text: 'I move at my own pace.',
                categories: [AffirmationCategory.calm],
              ),
            ),
          ),
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: user),
            ChangeNotifierProvider<TtsProvider>(create: (_) => TtsProvider()),
            ChangeNotifierProvider<QuestProvider>.value(value: quests),
          ],
        ));
        await tester.pump();
        final xpBefore = user.progress.xp;

        await tester.tap(find.byTooltip('Favorite'));
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump(const Duration(milliseconds: 100));

        final scale = tester.widget<ScaleTransition>(find.descendant(
            of: find.byType(AffirmationCard),
            matching: find.byType(ScaleTransition)));
        if (reduced) expect(scale.scale.value, 1.0);

        expect(user.isFavorite('rm-1'), isTrue);
        expect(user.progress.xp - xpBefore, 15,
            reason: '+10 favorite XP and +5 quest XP');
        expect(quests.quests.isCompleted(QuestType.favoriteOne), isTrue);
        await tester.pump(const Duration(seconds: 1));
      });
    }
  });
}
