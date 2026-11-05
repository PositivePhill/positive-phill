import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:positive_phill/models/daily_quests.dart';
import 'package:positive_phill/models/user_progress.dart';
import 'package:positive_phill/providers/quest_provider.dart';
import 'package:positive_phill/services/fortune_service.dart';
import 'package:positive_phill/widgets/daily_fortune_card.dart';
import 'package:positive_phill/widgets/daily_quest_card.dart';
import 'package:positive_phill/widgets/streak_display.dart';
import 'package:positive_phill/widgets/xp_progress_bar.dart';

import 'helpers/test_harness.dart';

const _widths = [320.0, 360.0, 390.0];
const _scales = [1.0, 1.3, 1.5, 2.0];

const _subjectKey = ValueKey('large-text-subject');

/// Longest entries from FortuneService's list (title and message).
const _longestFortunes = [
  DailyFortune(
    energy: 'Sunrise Energy',
    luckyFocus: 'Confidence',
    message: 'A fresh day is a fresh canvas. Today belongs to you.',
  ),
  DailyFortune(
    energy: 'Honest Ground',
    luckyFocus: 'Healing',
    message: 'Progress built on truth lasts longer than progress built on '
        'pretending.',
  ),
];

/// Home lane: horizontal insets plus a vertical scroll, as on the real screen.
Widget _host({
  required double scale,
  required Widget child,
  QuestProvider? quests,
}) {
  Widget app = MaterialApp(
    theme: testTheme(Brightness.light),
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: homeHorizontalInset),
              child: KeyedSubtree(key: _subjectKey, child: child),
            ),
          ),
        ),
      ),
    ),
  );
  if (quests != null) {
    app =
        ChangeNotifierProvider<QuestProvider>.value(value: quests, child: app);
  }
  return app;
}

Rect _globalRect(RenderBox box) => box.localToGlobal(Offset.zero) & box.size;

/// No overflow, no truncated paragraph, nothing outside the card or screen,
/// and every paragraph honors the ambient accessibility text scale.
void _expectFullyLaidOut(WidgetTester tester, double width, double scale) {
  expect(tester.takeException(), isNull);

  final subject = tester.renderObject<RenderBox>(find.byKey(_subjectKey));
  final bounds = _globalRect(subject);
  expect(bounds.right, lessThanOrEqualTo(width + 0.5));

  final paragraphs = find.descendant(
    of: find.byKey(_subjectKey),
    matching: find.byWidgetPredicate((w) => w is RichText),
  );
  expect(paragraphs, findsWidgets);
  for (final element in paragraphs.evaluate()) {
    final p = element.renderObject! as RenderParagraph;
    final text = p.text.toPlainText();
    expect(p.didExceedMaxLines, isFalse, reason: 'truncated: "$text"');
    final isIconGlyph = element.findAncestorWidgetOfExactType<Icon>() != null;
    if (!isIconGlyph && text.isNotEmpty) {
      expect(p.textScaler, TextScaler.linear(scale),
          reason: 'ignores text scale: "$text"');
    }
    final rect = _globalRect(p);
    expect(rect.left, greaterThanOrEqualTo(bounds.left - 0.5),
        reason: 'clipped left: "$text"');
    expect(rect.right, lessThanOrEqualTo(bounds.right + 0.5),
        reason: 'clipped right: "$text"');
    // U+FFFC is the placeholder for inline WidgetSpans, not part of a word.
    for (final word in RegExp(r'[^\s\uFFFC]+').allMatches(text)) {
      final lineTops = p
          .getBoxesForSelection(
              TextSelection(baseOffset: word.start, extentOffset: word.end))
          .map((b) => b.top.round())
          .toSet();
      expect(lineTops.length, lessThanOrEqualTo(1),
          reason: 'word split across lines: "${word.group(0)}" in "$text"');
    }
  }
}

Future<QuestProvider> _questsWith(
  WidgetTester tester,
  Iterable<QuestType> done,
) async {
  late QuestProvider provider;
  await tester.runAsync(() async {
    provider = QuestProvider();
    for (final t in done) {
      await provider.markCompleted(t);
    }
  });
  return provider;
}

void main() {
  setUpAll(loadRealisticFont);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (_) async => null);
  });

  void matrix(
    String name,
    Future<void> Function(WidgetTester tester, double scale) pump,
    void Function() expectContent,
  ) {
    group(name, () {
      for (final width in _widths) {
        for (final scale in _scales) {
          testWidgets('w=${width.toInt()} x$scale', (tester) async {
            setLogicalSize(tester, width, height: 2400);
            await pump(tester, scale);
            await tester.pump(const Duration(milliseconds: 300));
            _expectFullyLaidOut(tester, width, scale);
            expectContent();
          });
        }
      }
    });
  }

  matrix(
    'XpProgressBar, large values',
    (tester, scale) => tester.pumpWidget(_host(
      scale: scale,
      child: const XpProgressBar(
        progress: UserProgress(xp: 19999, level: 100, streak: 365),
      ),
    )),
    () {
      expect(find.text('Level 100'), findsOneWidget);
      expect(find.text('199/200 XP'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    },
  );

  group('XpProgressBar layout invariants', () {
    const progress = UserProgress(xp: 4170, level: 21);

    testWidgets('1.0x keeps level and XP on one row with exact progress',
        (tester) async {
      setLogicalSize(tester, 390);
      await tester.pumpWidget(_host(
        scale: 1.0,
        child: const XpProgressBar(progress: progress),
      ));
      final level = tester.getRect(find.text('Level 21'));
      final xp = tester.getRect(find.text('170/200 XP'));
      final bar = tester.getRect(find.byType(LinearProgressIndicator));
      expect(level.center.dy, closeTo(xp.center.dy, 0.5));
      expect(level.left, closeTo(bar.left, 0.5));
      expect(xp.right, closeTo(bar.right, 0.5));
      expect(
        tester
            .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator))
            .value,
        progress.progressToNextLevel,
      );
    });

    testWidgets('2.0x at 320 moves XP below the level instead of clipping',
        (tester) async {
      setLogicalSize(tester, 320);
      await tester.pumpWidget(_host(
        scale: 2.0,
        child: const XpProgressBar(progress: progress),
      ));
      expect(tester.takeException(), isNull);
      final level = tester.getRect(find.text('Level 21'));
      final xp = tester.getRect(find.text('170/200 XP'));
      expect(xp.top, greaterThanOrEqualTo(level.bottom));
      expect(
        tester
            .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator))
            .value,
        progress.progressToNextLevel,
      );
    });
  });

  matrix(
    'XpProgressBar, new user',
    (tester, scale) => tester.pumpWidget(_host(
      scale: scale,
      child: const XpProgressBar(progress: UserProgress()),
    )),
    () {
      expect(find.text('Level 1'), findsOneWidget);
      expect(find.text('0/200 XP'), findsOneWidget);
    },
  );

  matrix(
    'StreakDisplay, long streak on a scrimmed backdrop',
    (tester, scale) => tester.pumpWidget(_host(
      scale: scale,
      child: const Center(
        child: StreakDisplay(streak: 1234, stressedBackdrop: true),
      ),
    )),
    () {
      expect(find.text('1234 Day Streak'), findsOneWidget);
      expect(find.text('Keep it going!'), findsOneWidget);
      expect(find.text('🔥'), findsOneWidget);
    },
  );

  group('StreakDisplay layout invariants', () {
    testWidgets('1.0x keeps the flame beside the title', (tester) async {
      setLogicalSize(tester, 390);
      await tester.pumpWidget(_host(
        scale: 1.0,
        child: const Center(child: StreakDisplay(streak: 12)),
      ));
      final flame = tester.getRect(find.text('🔥'));
      final title = tester.getRect(find.text('12 Day Streak'));
      expect(title.left, greaterThan(flame.right));
      expect(title.top, lessThan(flame.bottom));
      expect(title.bottom, greaterThan(flame.top));
    });

    testWidgets('2.0x at 320 stacks the title under the flame', (tester) async {
      setLogicalSize(tester, 320);
      await tester.pumpWidget(_host(
        scale: 2.0,
        child: const Center(child: StreakDisplay(streak: 1234)),
      ));
      expect(tester.takeException(), isNull);
      final flame = tester.getRect(find.text('🔥'));
      final title = tester.getRect(find.text('1234 Day Streak'));
      expect(title.top, greaterThanOrEqualTo(flame.bottom));
    });
  });

  matrix(
    'StreakDisplay, no streak yet',
    (tester, scale) => tester.pumpWidget(_host(
      scale: scale,
      child: const Center(child: StreakDisplay(streak: 0)),
    )),
    () {
      expect(find.text('0 Day Streak'), findsOneWidget);
      expect(find.text('Start today!'), findsOneWidget);
    },
  );

  matrix(
    "DailyFortuneCard, today's fortune",
    (tester, scale) => tester.pumpWidget(_host(
      scale: scale,
      child: const DailyFortuneCard(),
    )),
    () => expect(find.text("TODAY'S ENERGY"), findsOneWidget),
  );

  for (final fortune in _longestFortunes) {
    matrix(
      'DailyFortuneCard, "${fortune.energy}"',
      (tester, scale) => tester.pumpWidget(_host(
        scale: scale,
        child: DailyFortuneCard(fortune: fortune),
      )),
      () {
        expect(find.text("TODAY'S ENERGY"), findsOneWidget);
        expect(find.text(fortune.energy), findsOneWidget);
        expect(find.text(fortune.message), findsOneWidget);
        expect(
          find.text('Lucky Focus: ${fortune.luckyFocus}', findRichText: true),
          findsOneWidget,
        );
      },
    );
  }

  matrix(
    'DailyQuestCard, none complete',
    (tester, scale) async => tester.pumpWidget(_host(
      scale: scale,
      quests: await _questsWith(tester, const []),
      child: const DailyQuestCard(),
    )),
    () {
      expect(find.text('Daily Quests'), findsOneWidget);
      for (final t in QuestType.values) {
        expect(
            find.textContaining(t.label, findRichText: true), findsOneWidget);
      }
      expect(find.text('+5 XP'), findsNWidgets(QuestType.values.length));
    },
  );

  testWidgets('DailyQuestCard 1.0x keeps +5 XP right-aligned on the label row',
      (tester) async {
    setLogicalSize(tester, 390);
    final quests = await _questsWith(tester, const []);
    await tester.pumpWidget(_host(
      scale: 1.0,
      quests: quests,
      child: const DailyQuestCard(),
    ));
    final count = tester.getRect(find.text('0/5'));
    for (final t in QuestType.values) {
      final labelFinder = find.textContaining(t.label, findRichText: true);
      final label = tester.getRect(labelFinder);
      final row =
          find.ancestor(of: labelFinder, matching: find.byType(Row)).first;
      final xp = tester
          .getRect(find.descendant(of: row, matching: find.text('+5 XP')));
      expect(xp.center.dy, closeTo(label.center.dy, 1.0), reason: t.label);
      expect(xp.right, closeTo(count.right, 0.5), reason: t.label);
    }
  });

  matrix(
    'DailyQuestCard, all complete with bonus',
    (tester, scale) async => tester.pumpWidget(_host(
      scale: scale,
      quests: await _questsWith(tester, QuestType.values),
      child: const DailyQuestCard(),
    )),
    () {
      expect(find.text('5/5'), findsOneWidget);
      expect(find.text('All quests done! +15 XP bonus earned'), findsOneWidget);
    },
  );
}
