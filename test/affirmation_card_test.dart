import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:positive_phill/models/accent_preset.dart';
import 'package:positive_phill/models/affirmation.dart';
import 'package:positive_phill/providers/tts_provider.dart';
import 'package:positive_phill/providers/user_provider.dart';
import 'package:positive_phill/widgets/affirmation_card.dart';

import 'helpers/test_harness.dart';

const _affirmation = Affirmation(
  id: 'test_1',
  text: 'I am calm, capable, and kind to myself.',
  categories: [AffirmationCategory.calm],
);

Future<void> _pumpCard(
  WidgetTester tester, {
  required Brightness brightness,
  required bool backlight,
  AccentPreset accent = AccentPreset.lavender,
}) async {
  setLogicalSize(tester, 390);
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => UserProvider()),
      ChangeNotifierProvider(create: (_) => TtsProvider()),
    ],
    child: MaterialApp(
      theme: testTheme(brightness, accent: accent),
      home: Scaffold(
        body: SizedBox(
          height: 300,
          child: AffirmationCard(
            affirmation: _affirmation,
            textBacklightEnabled: backlight,
          ),
        ),
      ),
    ),
  ));
  await tester.pump();
}

List<Shadow>? _shadowsOf(WidgetTester tester) =>
    tester.widget<Text>(find.text(_affirmation.text)).style?.shadows;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (_) async => null,
    );
  });

  for (final accent in AccentPreset.values) {
    testWidgets('light mode (${accent.name}): no smudge shadow on dark card text',
        (tester) async {
      await _pumpCard(tester,
          brightness: Brightness.light, backlight: true, accent: accent);
      expect(_shadowsOf(tester), isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dark mode (${accent.name}): soft backlight on light card text',
        (tester) async {
      await _pumpCard(tester,
          brightness: Brightness.dark, backlight: true, accent: accent);
      final shadows = _shadowsOf(tester);
      expect(shadows, isNotNull);
      expect(shadows, hasLength(1));
      expect(shadows!.single.color.a, closeTo(0.45, 0.01));
      expect(shadows.single.blurRadius, 3);
    });
  }

  testWidgets('backlight off: no shadow in dark mode', (tester) async {
    await _pumpCard(tester, brightness: Brightness.dark, backlight: false);
    expect(_shadowsOf(tester), isNull);
  });

  testWidgets('card actions remain available (favorite, share, speak)',
      (tester) async {
    await _pumpCard(tester, brightness: Brightness.light, backlight: true);
    expect(find.byTooltip('Favorite'), findsOneWidget);
    expect(find.byTooltip('Share'), findsOneWidget);
    expect(find.byTooltip('Speak'), findsOneWidget);
  });
}
