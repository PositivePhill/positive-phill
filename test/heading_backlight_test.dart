import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:positive_phill/screens/home_screen.dart';
import 'package:positive_phill/widgets/sos_entry_card.dart';
import 'package:positive_phill/widgets/streak_display.dart';

import 'helpers/test_harness.dart';

const _blackBacklight = [
  Shadow(color: Color(0x99000000), offset: Offset(1, 1), blurRadius: 4),
];

bool _hasBlackShadow(List<Shadow>? shadows) =>
    shadows?.any((s) => s.color.r == 0 && s.color.g == 0 && s.color.b == 0) ??
    false;

Future<void> _pump(WidgetTester tester, Brightness brightness, Widget child) {
  setLogicalSize(tester, 390);
  return tester.pumpWidget(MaterialApp(
    theme: testTheme(brightness),
    home: Scaffold(body: Center(child: child)),
  ));
}

TextStyle _styleOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!;

void main() {
  setUpAll(loadRealisticFont);

  group('homeReadabilityTextShadows', () {
    test('plain light surface + backlight on: no shadow (no smudge)', () {
      expect(
        homeReadabilityTextShadows(
          needsReadabilityScrim: false,
          textBacklight: true,
          brightness: Brightness.light,
        ),
        isNull,
      );
    });

    test('plain dark surface + backlight on: backlight kept', () {
      final s = homeReadabilityTextShadows(
        needsReadabilityScrim: false,
        textBacklight: true,
        brightness: Brightness.dark,
      );
      expect(_hasBlackShadow(s), isTrue);
    });

    test('backlight off and no scrim: no shadow in either theme', () {
      for (final b in Brightness.values) {
        expect(
          homeReadabilityTextShadows(
            needsReadabilityScrim: false,
            textBacklight: false,
            brightness: b,
          ),
          isNull,
        );
      }
    });

    test('photo/video scrim: shadows kept in both themes, backlight on or off',
        () {
      for (final b in Brightness.values) {
        for (final backlight in [true, false]) {
          expect(
            _hasBlackShadow(homeReadabilityTextShadows(
              needsReadabilityScrim: true,
              textBacklight: backlight,
              brightness: b,
            )),
            isTrue,
            reason: '$b backlight=$backlight',
          );
        }
      }
    });
  });

  group('SosEntryCard heading', () {
    testWidgets('light theme: dark heading drops inherited black shadow',
        (tester) async {
      await _pump(tester, Brightness.light,
          const SosEntryCard(textShadows: _blackBacklight));
      expect(_styleOf(tester, 'Need a boost?').shadows, isNull);
    });

    testWidgets('dark theme: light heading keeps the backlight',
        (tester) async {
      await _pump(tester, Brightness.dark,
          const SosEntryCard(textShadows: _blackBacklight));
      expect(_styleOf(tester, 'Need a boost?').shadows, _blackBacklight);
    });
  });

  group('StreakDisplay', () {
    testWidgets('light theme, plain backdrop: no black shadow on dark text',
        (tester) async {
      await _pump(tester, Brightness.light,
          const StreakDisplay(streak: 3, textShadows: _blackBacklight));
      expect(_hasBlackShadow(_styleOf(tester, '3 Day Streak').shadows), isFalse);
      expect(_hasBlackShadow(_styleOf(tester, 'Keep it going!').shadows),
          isFalse);
    });

    testWidgets('dark theme, plain backdrop: backlight kept on light text',
        (tester) async {
      await _pump(tester, Brightness.dark,
          const StreakDisplay(streak: 3, textShadows: _blackBacklight));
      expect(_hasBlackShadow(_styleOf(tester, '3 Day Streak').shadows), isTrue);
    });

    testWidgets('light theme over photo/video: contrast shadows kept',
        (tester) async {
      await _pump(
        tester,
        Brightness.light,
        const StreakDisplay(
          streak: 0,
          textShadows: _blackBacklight,
          stressedBackdrop: true,
        ),
      );
      final title = _styleOf(tester, '0 Day Streak').shadows;
      expect(_hasBlackShadow(title), isTrue);
      expect(title!.any((s) => s.color.r == 1 && s.color.g == 1), isTrue,
          reason: 'white halo still applied over busy backdrops');
    });
  });
}
