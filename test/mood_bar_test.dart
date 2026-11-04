import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:positive_phill/widgets/mood_bar.dart';

import 'helpers/test_harness.dart';

Widget _harness({
  required double scale,
  required DailyMood? selected,
  required Future<void> Function(DailyMood) onSelected,
}) {
  return MaterialApp(
    theme: testTheme(Brightness.light),
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: homeHorizontalInset,
            ),
            child: MoodBar(
              selectedMood: selected,
              onMoodSelected: onSelected,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(loadRealisticFont);

  const widths = [320.0, 360.0, 390.0];
  const scales = [1.0, 1.3, 2.0];

  for (final width in widths) {
    for (final scale in scales) {
      for (final selected in [null, DailyMood.overwhelmed]) {
        testWidgets(
          'all mood labels render in full at ${width.toInt()}px, '
          'text x$scale, selected=${selected?.name}',
          (tester) async {
            setLogicalSize(tester, width);
            await tester.pumpWidget(_harness(
              scale: scale,
              selected: selected,
              onSelected: (_) async {},
            ));
            await tester.pumpAndSettle();

            expect(tester.takeException(), isNull,
                reason: 'no RenderFlex or layout overflow');

            for (final mood in DailyMood.values) {
              final label = '${mood.emoji} ${mood.label}';
              final textFinder = find.text(label);
              expect(textFinder, findsOneWidget, reason: label);

              final paragraph =
                  tester.renderObject<RenderParagraph>(textFinder);
              expect(paragraph.didExceedMaxLines, isFalse,
                  reason: '"$label" must not be truncated');

              final chipRect = tester.getRect(find.ancestor(
                of: textFinder,
                matching: find.byType(ChoiceChip),
              ));
              expect(chipRect.left, greaterThanOrEqualTo(0), reason: label);
              expect(chipRect.right, lessThanOrEqualTo(width), reason: label);

              final textRect = tester.getRect(textFinder);
              expect(textRect.left, greaterThanOrEqualTo(chipRect.left - 0.5),
                  reason: '"$label" text stays inside its chip');
              expect(textRect.right, lessThanOrEqualTo(chipRect.right + 0.5),
                  reason: '"$label" text stays inside its chip');
            }
          },
        );
      }
    }
  }

  testWidgets('tapping a mood reports that mood (selection semantics kept)',
      (tester) async {
    setLogicalSize(tester, 360);
    DailyMood? reported;
    await tester.pumpWidget(_harness(
      scale: 1.0,
      selected: null,
      onSelected: (m) async => reported = m,
    ));
    await tester.tap(find.text('${DailyMood.tired.emoji} ${DailyMood.tired.label}'));
    await tester.pump();
    expect(reported, DailyMood.tired);
  });

  testWidgets('mood chips stay keyboard-focusable and announce selection',
      (tester) async {
    setLogicalSize(tester, 360);
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_harness(
      scale: 1.0,
      selected: DailyMood.calm,
      onSelected: (_) async {},
    ));
    final calm = '${DailyMood.calm.emoji} ${DailyMood.calm.label}';
    expect(
      tester.getSemantics(find.text(calm)),
      isSemantics(
        label: calm,
        isSelected: true,
        isFocusable: true,
        hasTapAction: true,
        isEnabled: true,
      ),
    );
    handle.dispose();
  });
}
