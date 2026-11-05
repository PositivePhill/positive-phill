import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:positive_phill/models/board_video_preset.dart';
import 'package:positive_phill/widgets/board_video_background.dart';
import 'package:positive_phill/widgets/board_video_poster.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('BoardVideoPoster', () {
    testWidgets('paints the preset poster over its placeholder color',
        (tester) async {
      await tester.pumpWidget(
        _host(const BoardVideoPoster(preset: BoardVideoPreset.rainWindow)),
      );

      final box = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(BoardVideoPoster),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(box.color, BoardVideoPreset.rainWindow.posterPlaceholderColor);

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<AssetImage>());
      expect((image.image as AssetImage).assetName,
          'assets/images/posters/rain_window.jpg');
      expect(image.fit, BoxFit.cover);
      expect(image.excludeFromSemantics, isTrue);
    });

    testWidgets('falls back to the placeholder when the image fails',
        (tester) async {
      await tester.pumpWidget(
        _host(const BoardVideoPoster(preset: BoardVideoPreset.oceanCalm)),
      );
      final image = tester.widget<Image>(find.byType(Image));
      final fallback = image.errorBuilder!(
        tester.element(find.byType(Image)),
        Exception('missing'),
        null,
      );
      expect(fallback, isA<SizedBox>());
    });

    testWidgets('none renders only the placeholder', (tester) async {
      await tester.pumpWidget(
        _host(const BoardVideoPoster(preset: BoardVideoPreset.none)),
      );
      expect(find.byType(Image), findsNothing);
      expect(find.byType(ColoredBox), findsWidgets);
    });
  });

  group('BoardVideoBackground (native)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'board_video_preset': 'rain_window',
      });
    });

    testWidgets(
        'playback failure is reported once and never touches saved prefs',
        (tester) async {
      var unavailable = 0;
      await tester.pumpWidget(
        _host(
          BoardVideoBackground(
            preset: BoardVideoPreset.rainWindow,
            onPlaybackUnavailable: () => unavailable++,
          ),
        ),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(unavailable, 1);
      expect(
        find.descendant(
          of: find.byType(BoardVideoBackground),
          matching: find.byType(SizedBox),
        ),
        findsOneWidget,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('board_video_preset'), 'rain_window');
    });

    testWidgets(
        'unmounting before the deferred failure report suppresses the stale '
        'callback and does not throw', (tester) async {
      var unavailable = 0;
      await tester.pumpWidget(
        _host(
          BoardVideoBackground(
            preset: BoardVideoPreset.oceanCalm,
            onPlaybackUnavailable: () => unavailable++,
          ),
        ),
      );
      await tester.pumpWidget(_host(const SizedBox()));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(unavailable, 0);
      expect(tester.takeException(), isNull);
    });
  });
}
