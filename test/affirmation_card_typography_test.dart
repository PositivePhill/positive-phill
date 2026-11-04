import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:positive_phill/models/affirmation.dart';
import 'package:positive_phill/providers/tts_provider.dart';
import 'package:positive_phill/providers/user_provider.dart';
import 'package:positive_phill/widgets/affirmation_card.dart';

import 'helpers/test_harness.dart';

/// Longest affirmation shipped in the app (70 chars).
const _longest = Affirmation(
  id: 'longest',
  text: 'I craft quality with intention, without chasing impossible perfection.',
  categories: [AffirmationCategory.focus],
);

const _typical = Affirmation(
  id: 'typical',
  text: 'I am becoming a better version of myself every day.',
  categories: [AffirmationCategory.confidence],
);

final _cardText = find.byKey(const ValueKey('affirmation-card-text'));

Widget _app({
  required double scale,
  required Widget body,
  Brightness brightness = Brightness.light,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => UserProvider()),
      ChangeNotifierProvider(create: (_) => TtsProvider()),
    ],
    child: MaterialApp(
      theme: testTheme(brightness),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: Scaffold(body: body),
        ),
      ),
    ),
  );
}

/// Home and Rescue host the card in a 300px-tall PageView, inside Home's
/// horizontal insets.
Widget _homeDeck(Affirmation a) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: homeHorizontalInset),
      child: SizedBox(
        height: 300,
        child: PageView(children: [AffirmationCard(affirmation: a)]),
      ),
    );

void _expectReadableAndUnclipped(WidgetTester tester, {required double scale}) {
  expect(tester.takeException(), isNull, reason: 'no layout overflow');

  final text = tester.widget<Text>(_cardText);
  expect(text.maxLines, isNull, reason: 'no line cap');
  expect(text.overflow, isNull, reason: 'no ellipsis truncation');
  expect(text.style!.fontSize, greaterThanOrEqualTo(16),
      reason: 'font never drops below the 16px floor');

  // No FittedBox/Transform between the card and its text: glyphs render at
  // the computed size instead of being shrunk as a block.
  expect(
    find.ancestor(of: _cardText, matching: find.byType(FittedBox)),
    findsNothing,
  );

  final paragraph = tester.renderObject<RenderParagraph>(_cardText);
  expect(paragraph.didExceedMaxLines, isFalse);

  // Any overflow beyond the text viewport must be reachable by scrolling.
  final scrollView = find.ancestor(
    of: _cardText,
    matching: find.byType(SingleChildScrollView),
  );
  final viewportHeight = tester.getSize(scrollView).height;
  final position =
      tester.state<ScrollableState>(find.descendant(
        of: scrollView,
        matching: find.byType(Scrollable),
      )).position;
  expect(
    position.maxScrollExtent,
    closeTo(
      (paragraph.size.height - viewportHeight).clamp(0, double.infinity),
      0.5,
    ),
    reason: 'text is either fully visible or fully scrollable',
  );

  final card = tester.getRect(find.byType(AffirmationCard));
  final textRect = tester.getRect(_cardText);
  expect(textRect.left, greaterThanOrEqualTo(card.left));
  expect(textRect.right, lessThanOrEqualTo(card.right));
}

void main() {
  setUpAll(loadRealisticFont);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (_) async => null,
    );
  });

  const widths = [320.0, 360.0, 390.0];
  const scales = [1.0, 1.3, 2.0];

  for (final width in widths) {
    for (final scale in scales) {
      testWidgets(
          'Home/Rescue deck at ${width.toInt()}px, text x$scale: longest '
          'affirmation is readable and never clipped', (tester) async {
        setLogicalSize(tester, width);
        await tester.pumpWidget(_app(scale: scale, body: _homeDeck(_longest)));
        await tester.pump();
        _expectReadableAndUnclipped(tester, scale: scale);
      });
    }

    testWidgets(
        'typical affirmation at ${width.toInt()}px keeps full headline size',
        (tester) async {
      setLogicalSize(tester, width);
      await tester.pumpWidget(_app(scale: 1.0, body: _homeDeck(_typical)));
      await tester.pump();
      _expectReadableAndUnclipped(tester, scale: 1.0);
      expect(tester.widget<Text>(_cardText).style!.fontSize, 24,
          reason: 'headlineSmall size is kept when it fits');

      final paragraph = tester.renderObject<RenderParagraph>(_cardText);
      final card = tester.getSize(find.byType(AffirmationCard));
      expect(paragraph.size.width, greaterThan(card.width * 0.6),
          reason: 'text wraps at the card width instead of shrinking');
    });
  }

  testWidgets('dark theme deck at 360px, text x2.0 stays readable',
      (tester) async {
    setLogicalSize(tester, 360);
    await tester.pumpWidget(_app(
      scale: 2.0,
      brightness: Brightness.dark,
      body: _homeDeck(_longest),
    ));
    await tester.pump();
    _expectReadableAndUnclipped(tester, scale: 2.0);
  });

  testWidgets('Favorites list (unbounded height) lays out at full size',
      (tester) async {
    setLogicalSize(tester, 360);
    await tester.pumpWidget(_app(
      scale: 1.3,
      body: ListView(children: const [
        AffirmationCard(affirmation: _longest, textBacklightEnabled: false),
        AffirmationCard(affirmation: _typical, textBacklightEnabled: false),
      ]),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
    for (final style in tester
        .widgetList<Text>(_cardText)
        .map((t) => t.style!)) {
      expect(style.fontSize, 24);
    }
  });

  testWidgets('Session flow (card between Spacers) lays out at full size',
      (tester) async {
    setLogicalSize(tester, 360);
    await tester.pumpWidget(_app(
      scale: 1.0,
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(children: [
          Spacer(),
          AffirmationCard(affirmation: _longest),
          Spacer(),
          SizedBox(height: 48),
        ]),
      ),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(tester.widget<Text>(_cardText).style!.fontSize, 24);
  });

  ScrollPosition textScroll(WidgetTester tester) => tester
      .state<ScrollableState>(find.descendant(
        of: find.ancestor(
          of: _cardText,
          matching: find.byType(SingleChildScrollView),
        ),
        matching: find.byType(Scrollable),
      ))
      .position;

  testWidgets('overflowing text shows a scrollbar and reaches its last words',
      (tester) async {
    setLogicalSize(tester, 320);
    await tester.pumpWidget(_app(scale: 2.0, body: _homeDeck(_longest)));
    await tester.pumpAndSettle();

    final scrollbar = tester.widget<Scrollbar>(find.ancestor(
      of: _cardText,
      matching: find.byType(Scrollbar),
    ));
    expect(scrollbar.thumbVisibility, isTrue);
    final position = textScroll(tester);
    expect(position.maxScrollExtent, greaterThan(0),
        reason: 'precondition: this case overflows');

    await tester.drag(_cardText, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(position.pixels, position.maxScrollExtent);
    expect(tester.takeException(), isNull);
  });

  testWidgets('text that fits has nothing to scroll', (tester) async {
    setLogicalSize(tester, 390);
    await tester.pumpWidget(_app(scale: 1.0, body: _homeDeck(_longest)));
    await tester.pumpAndSettle();
    expect(textScroll(tester).maxScrollExtent, 0);
  });

  testWidgets('card actions remain at every scale', (tester) async {
    setLogicalSize(tester, 320);
    await tester.pumpWidget(_app(scale: 2.0, body: _homeDeck(_longest)));
    await tester.pump();
    expect(find.byTooltip('Favorite'), findsOneWidget);
    expect(find.byTooltip('Share'), findsOneWidget);
    expect(find.byTooltip('Speak'), findsOneWidget);
  });
}
