import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:positive_phill/models/affirmation.dart';
import 'package:positive_phill/screens/home_screen.dart';

import 'helpers/test_harness.dart';

String _label(AffirmationCategory c) => '${c.emoji} ${c.displayName}';

/// Mimics Home: a tall vertical page with the selector partway down.
class _Page extends StatefulWidget {
  const _Page({required this.pageController, this.initial});

  final ScrollController pageController;
  final AffirmationCategory? initial;

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  late AffirmationCategory? selected = widget.initial;
  final List<AffirmationCategory?> reported = [];

  void select(AffirmationCategory? c) => setState(() => selected = c);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        controller: widget.pageController,
        padding:
            const EdgeInsets.symmetric(horizontal: homeHorizontalInset),
        child: Column(
          children: [
            const SizedBox(height: 700),
            CategorySelector(
              selectedCategory: selected,
              onCategoryChanged: (c) async {
                reported.add(c);
                select(c);
              },
            ),
            const SizedBox(height: 1200),
          ],
        ),
      ),
    );
  }
}

Future<_PageState> _pump(
  WidgetTester tester, {
  required double width,
  required ScrollController page,
  AffirmationCategory? initial,
}) async {
  setLogicalSize(tester, width, height: 800);
  await tester.pumpWidget(MaterialApp(
    theme: testTheme(Brightness.light),
    home: _Page(pageController: page, initial: initial),
  ));
  await tester.pumpAndSettle();
  return tester.state<_PageState>(find.byType(_Page));
}

Rect _rowViewport(WidgetTester tester) => tester.getRect(find.descendant(
      of: find.byType(CategorySelector),
      matching: find.byType(SingleChildScrollView),
    ));

void main() {
  setUpAll(loadRealisticFont);

  group('mobile width (360px)', () {
    testWidgets(
        'selecting an off-screen category reveals its chip without '
        'scrolling the page', (tester) async {
      final page = ScrollController();
      final state = await _pump(tester, width: 360, page: page);

      page.jumpTo(400);
      await tester.pumpAndSettle();
      final pageOffsetBefore = page.offset;

      final last = AffirmationCategory.values.last;
      final viewport = _rowViewport(tester);
      expect(tester.getRect(find.text(_label(last))).left,
          greaterThan(viewport.right),
          reason: 'precondition: last chip starts off-screen');

      state.select(last);
      await tester.pumpAndSettle();

      final chip = tester.getRect(find.ancestor(
        of: find.text(_label(last)),
        matching: find.byType(FilterChip),
      ));
      expect(chip.left, greaterThanOrEqualTo(viewport.left - 0.5));
      expect(chip.right, lessThanOrEqualTo(viewport.right + 0.5));
      expect(page.offset, pageOffsetBefore,
          reason: 'Home page scroll position must not move');
      expect(tester.takeException(), isNull);
    });

    testWidgets('pre-selected off-screen category is visible on first build',
        (tester) async {
      final page = ScrollController();
      await _pump(tester, width: 360, page: page,
          initial: AffirmationCategory.values.last);
      final viewport = _rowViewport(tester);
      final chip = tester.getRect(find.text(_label(AffirmationCategory.values.last)));
      expect(chip.right, lessThanOrEqualTo(viewport.right + 0.5));
      expect(page.offset, 0);
    });

    testWidgets('scroll hint shows while more chips are off to the right',
        (tester) async {
      final page = ScrollController();
      await _pump(tester, width: 360, page: page);
      final hint = find.byKey(const ValueKey('category-scroll-hint'));
      expect(hint, findsOneWidget);

      await tester.drag(
          find.byType(CategorySelector), const Offset(-2000, 0));
      await tester.pumpAndSettle();
      expect(hint, findsNothing, reason: 'hint hides at the end of the row');
    });

    testWidgets('scroll hint is excluded from semantics and ignores taps',
        (tester) async {
      final handle = tester.ensureSemantics();
      final page = ScrollController();
      await _pump(tester, width: 360, page: page);
      final hint = find.byKey(const ValueKey('category-scroll-hint'));
      expect(
        find.ancestor(of: hint, matching: find.byType(IgnorePointer)),
        findsWidgets,
      );
      expect(
        find.ancestor(of: hint, matching: find.byType(ExcludeSemantics)),
        findsWidgets,
      );
      handle.dispose();
    });

    testWidgets('tapping an already-visible chip does not shift the row',
        (tester) async {
      final page = ScrollController();
      await _pump(tester, width: 360, page: page);
      final row = tester
          .widget<SingleChildScrollView>(find.descendant(
            of: find.byType(CategorySelector),
            matching: find.byType(SingleChildScrollView),
          ))
          .controller!;
      await tester.tap(find.text(_label(AffirmationCategory.confidence)));
      await tester.pumpAndSettle();
      expect(row.offset, 0);
    });

    testWidgets('tapping chips reports the category and All reports null',
        (tester) async {
      final page = ScrollController();
      final state = await _pump(tester, width: 360, page: page);
      await tester.tap(find.text(_label(AffirmationCategory.confidence)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      // A clipped chip gets centered, which can push "All" off the leading
      // edge; scrolling back must still allow selecting it.
      await tester.drag(
          find.byType(CategorySelector), const Offset(-2000, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_label(AffirmationCategory.values.last)));
      await tester.pumpAndSettle();
      await tester.drag(
          find.byType(CategorySelector), const Offset(2000, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(state.reported, [
        AffirmationCategory.confidence,
        null,
        AffirmationCategory.values.last,
        null,
      ]);
    });
  });

  group('desktop width (1024px)', () {
    testWidgets('all chips wrap into view with no scroll hint',
        (tester) async {
      final page = ScrollController();
      await _pump(tester, width: 1024, page: page);

      expect(find.descendant(
        of: find.byType(CategorySelector),
        matching: find.byType(Wrap),
      ), findsOneWidget);
      expect(find.byKey(const ValueKey('category-scroll-hint')), findsNothing);

      final selector = tester.getRect(find.byType(CategorySelector));
      for (final c in AffirmationCategory.values) {
        final r = tester.getRect(find.text(_label(c)));
        expect(r.left, greaterThanOrEqualTo(selector.left), reason: c.name);
        expect(r.right, lessThanOrEqualTo(selector.right), reason: c.name);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('selecting on desktop keeps page offset stable',
        (tester) async {
      final page = ScrollController();
      final state = await _pump(tester, width: 1024, page: page);
      page.jumpTo(300);
      await tester.pumpAndSettle();
      state.select(AffirmationCategory.money);
      await tester.pumpAndSettle();
      expect(page.offset, 300);
    });
  });
}
