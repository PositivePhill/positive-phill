@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:positive_phill/services/affirmation_share_export_service.dart';

import 'helpers/share_export_harness.dart';

const _pathProvider = MethodChannel('plugins.flutter.io/path_provider');
const _share = MethodChannel('dev.fluttercommunity.plus/share');

/// google_fonts 6.3.3 looks for `<family>_<variant>_<fileHash>.ttf` in the
/// application support directory before fetching over the network. Seeding
/// those names (with the SDK's Roboto bytes) keeps ShareCardCanvas offline.
const _interCacheFiles = [
  'Inter_700_b7e339223d56e8c4210c86f1ba87b3d43d6c47e03956ea56f0a7a938ae61b2a3.ttf',
  'Inter_600_d7ba633bab7f40576e539a7e934a1301d7618dceea59c743de477c2c493462fc.ttf',
  'Inter_500_492dec3bc33255f9d81bd5fb18704ad72f96f9b9318e4171bc9f9be9dd4bf44b.ttf',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late Directory fontCacheDir;
  final shareCalls = <MethodCall>[];
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUpAll(() {
    fontCacheDir = Directory.systemTemp.createTempSync('pp_font_cache_');
    final roboto = File(
      '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/'
      'material_fonts/roboto-regular.ttf',
    ).readAsBytesSync();
    for (final name in _interCacheFiles) {
      File('${fontCacheDir.path}/$name').writeAsBytesSync(roboto);
    }
  });

  tearDownAll(() {
    if (fontCacheDir.existsSync()) fontCacheDir.deleteSync(recursive: true);
  });

  void mockPathProvider({String? tempPath}) {
    messenger.setMockMethodCallHandler(_pathProvider, (call) async {
      switch (call.method) {
        case 'getApplicationSupportDirectory':
          return fontCacheDir.path;
        case 'getTemporaryDirectory':
          if (tempPath == null) {
            throw PlatformException(code: 'no_temp_dir');
          }
          return tempPath;
      }
      return null;
    });
  }

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('pp_share_test_');
    shareCalls.clear();
    mockPathProvider(tempPath: tempDir.path);
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(_pathProvider, null);
    messenger.setMockMethodCallHandler(_share, null);
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('share text body format is unchanged', () {
    expect(
      AffirmationShareExportService.shareTextBody(shareAffirmation),
      '${shareAffirmation.text}\n\n— Positive Phill by Possum Mattern Studios',
    );
  });

  testWidgets('native success: writes a PNG, opens share, returns true',
      (tester) async {
    messenger.setMockMethodCallHandler(_share, (call) async {
      shareCalls.add(call);
      return 'dev.fluttercommunity.plus/share/unavailable';
    });

    final outcome = await runShareExport(tester);

    expect(outcome.escapedError, isNull);
    expect(outcome.result, isTrue);
    final pngs = tempDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.png'))
        .toList();
    expect(pngs, hasLength(1));
    expect(pngs.single.readAsBytesSync().take(8).toList(),
        [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
        reason: 'PNG signature');
    expect(shareCalls, isNotEmpty, reason: 'share sheet was invoked');
  });

  testWidgets('native async failure: share rejection returns false, no throw',
      (tester) async {
    messenger.setMockMethodCallHandler(_share, (call) async {
      throw PlatformException(code: 'share_failed', message: 'boom');
    });

    final outcome = await runShareExport(tester);

    expect(outcome.escapedError, isNull);
    expect(outcome.result, isFalse);
  });

  testWidgets('native failure: no temp directory returns false, no throw',
      (tester) async {
    mockPathProvider(tempPath: null);

    final outcome = await runShareExport(tester);

    expect(outcome.escapedError, isNull);
    expect(outcome.result, isFalse);
  });
}
