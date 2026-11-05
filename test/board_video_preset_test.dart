import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:positive_phill/models/board_video_preset.dart';

void main() {
  final videoPresets =
      BoardVideoPreset.values.where((p) => p != BoardVideoPreset.none);

  test('none has no video or poster', () {
    expect(BoardVideoPreset.none.bundledAssetPath(), isNull);
    expect(BoardVideoPreset.none.posterAssetPath(), isNull);
  });

  test('every video preset maps to a bundled video and poster on disk', () {
    for (final preset in videoPresets) {
      final video = preset.bundledAssetPath();
      final poster = preset.posterAssetPath();
      expect(video, isNotNull, reason: preset.name);
      expect(poster, isNotNull, reason: preset.name);
      expect(File(video!).existsSync(), isTrue, reason: video);
      expect(File(poster!).existsSync(), isTrue, reason: poster);
      expect(poster, 'assets/images/posters/${preset.storageId}.jpg');
      expect(File(poster).lengthSync(), lessThan(200 * 1024), reason: poster);
    }
  });

  test('poster directory is registered in pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('- assets/images/posters/'));
  });

  test('placeholder colors are opaque', () {
    for (final preset in BoardVideoPreset.values) {
      expect(preset.posterPlaceholderColor.a, 1.0, reason: preset.name);
    }
  });

  test('storage ids round-trip, including explicit none', () {
    for (final preset in BoardVideoPreset.values) {
      expect(BoardVideoPreset.fromStorageId(preset.storageId), preset);
    }
    expect(BoardVideoPreset.fromStorageId('none'), BoardVideoPreset.none);
    expect(BoardVideoPreset.fromStorageId('forestlight'),
        BoardVideoPreset.forestLight);
  });

  test('fresh-install default is Rain Window', () {
    expect(BoardVideoPreset.freshInstallDefault, BoardVideoPreset.rainWindow);
  });
}
