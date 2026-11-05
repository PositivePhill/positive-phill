import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:positive_phill/models/background_gradient_preset.dart';
import 'package:positive_phill/services/storage_service.dart';
import 'package:positive_phill/widgets/background_style_sheet.dart';
import 'package:positive_phill/widgets/reduce_motion.dart';

import 'helpers/test_harness.dart';

/// Mirrors main.dart: scope above MaterialApp, appBuilder below it.
Widget _app(Widget Function(BuildContext context) body) => ReduceMotion(
      child: MaterialApp(
        theme: testTheme(Brightness.light),
        builder: ReduceMotion.appBuilder,
        home: Scaffold(body: Builder(builder: body)),
      ),
    );

Widget _button(String label, void Function(BuildContext) onPressed) => Builder(
      builder: (context) => TextButton(
        onPressed: () => onPressed(context),
        child: Text(label),
      ),
    );

ModalRoute<dynamic> _routeOf(WidgetTester tester, Finder finder) =>
    ModalRoute.of(tester.element(finder))!;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.reduceMotion.value = false;
    StorageService.backgroundGradientPreset.value =
        BackgroundGradientPreset.none;
  });

  group('bottom sheets', () {
    Future<void> openSheet(WidgetTester tester) async {
      setLogicalSize(tester, 390, height: 900);
      await tester.pumpWidget(_app((context) => _button(
            'open',
            (ctx) => showBackgroundStyleSheet(
              ctx,
              initial: BackgroundGradientPreset.none,
              onPickImage: () async {},
            ),
          )));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
    }

    testWidgets('reduced: opens and closes instantly and stays interactive',
        (tester) async {
      StorageService.reduceMotion.value = true;
      await openSheet(tester);
      final route = _routeOf(tester, find.text('Background style'));
      expect(route.animation!.status, AnimationStatus.completed);

      // Still interactive: choosing a gradient persists as before.
      final target =
          find.text(BackgroundGradientPreset.values.last.displayName);
      await tester.scrollUntilVisible(target, 200,
          scrollable: find
              .descendant(
                  of: find.byType(BottomSheet),
                  matching: find.byType(Scrollable))
              .first);
      await tester.tap(target);
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
      expect(StorageService.backgroundGradientPreset.value,
          BackgroundGradientPreset.values.last);

      Navigator.of(tester.element(find.text('Background style'))).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('Background style'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('motion allowed: keeps the framework slide', (tester) async {
      await openSheet(tester);
      final route = _routeOf(tester, find.text('Background style'));
      expect(route.animation!.status, AnimationStatus.forward);
      await tester.pumpAndSettle();
    });

    testWidgets('a live toggle applies to the next sheet', (tester) async {
      await openSheet(tester);
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.text('Background style'))).pop();
      await tester.pumpAndSettle();

      StorageService.reduceMotion.value = true;
      await tester.pump();
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(_routeOf(tester, find.text('Background style')).animation!.status,
          AnimationStatus.completed);
    });
  });

  group('dialogs', () {
    Future<void> openDialog(WidgetTester tester) async {
      await tester.pumpWidget(_app((context) => _button(
            'open',
            (ctx) => showDialog<void>(
              context: ctx,
              animationStyle: ReduceMotion.animationStyleOf(ctx),
              builder: (dialogContext) => AlertDialog(
                title: const Text('Reset Progress'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          )));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
    }

    testWidgets('reduced: appears and dismisses without animation',
        (tester) async {
      StorageService.reduceMotion.value = true;
      await openDialog(tester);
      expect(_routeOf(tester, find.text('Reset Progress')).animation!.status,
          AnimationStatus.completed);
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('Reset Progress'), findsNothing);
    });

    testWidgets('motion allowed: keeps the framework transition',
        (tester) async {
      await openDialog(tester);
      expect(_routeOf(tester, find.text('Reset Progress')).animation!.status,
          AnimationStatus.forward);
      await tester.pumpAndSettle();
    });
  });

  group('snackbars', () {
    Future<void> show(WidgetTester tester, String text) async {
      ScaffoldMessenger.of(tester.element(find.text('open')))
          .showMotionAwareSnackBar(SnackBar(content: Text(text)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
    }

    double animationOf(WidgetTester tester, String text) => tester
        .widget<SnackBar>(
            find.ancestor(of: find.text(text), matching: find.byType(SnackBar)))
        .animation!
        .value;

    Future<void> pumpHost(WidgetTester tester) =>
        tester.pumpWidget(_app((context) => _button('open', (_) {})));

    testWidgets('reduced: fully visible at once and keeps its 4 s duration',
        (tester) async {
      StorageService.reduceMotion.value = true;
      await pumpHost(tester);
      await show(tester, 'Saved');
      expect(animationOf(tester, 'Saved'), 1.0);
      await tester.pump(const Duration(milliseconds: 3800));
      expect(find.text('Saved'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(find.text('Saved'), findsNothing);
    });

    testWidgets('motion allowed: keeps the framework entrance', (tester) async {
      await pumpHost(tester);
      await show(tester, 'Saved');
      expect(animationOf(tester, 'Saved'), lessThan(1.0));
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('live flips while a snackbar is visible stay safe',
        (tester) async {
      await pumpHost(tester);
      await show(tester, 'first');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('first'), findsOneWidget);

      StorageService.reduceMotion.value = true;
      await tester.pump();
      await show(tester, 'second');
      expect(tester.takeException(), isNull);
      expect(find.text('first'), findsNothing);
      expect(animationOf(tester, 'second'), 1.0);

      StorageService.reduceMotion.value = false;
      await tester.pump();
      await show(tester, 'third');
      expect(tester.takeException(), isNull);
      expect(animationOf(tester, 'third'), lessThan(1.0),
          reason: 'animation restored after Reduce Motion is turned off');
      // Step frames continuously: the visible timer starts when the entrance
      // animation completes on a drawn frame.
      for (var i = 0; i < 14; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(find.text('third'), findsOneWidget, reason: 'normal visible time');
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(find.text('third'), findsNothing);
    });
  });
}
