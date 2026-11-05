import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:positive_phill/models/affirmation.dart';
import 'package:positive_phill/services/affirmation_share_export_service.dart';

const shareAffirmation = Affirmation(
  id: 'share_1',
  text: 'I am calm, capable, and kind to myself.',
  categories: [AffirmationCategory.calm],
);

/// Outcome of a [AffirmationShareExportService.sharePngBestEffort] call,
/// including any error that escaped the method instead of becoming `false`.
class ShareOutcome {
  bool? result;
  Object? escapedError;
  bool get completed => result != null || escapedError != null;
}

/// Pumps a host app and runs the export. The service mixes fake-zone timers
/// (frame waits, settle delays) with real engine work (image capture), so
/// frames and fake time are advanced while real async work gets a chance to
/// run.
Future<ShareOutcome> runShareExport(WidgetTester tester) async {
  late BuildContext hostContext;
  await tester.pumpWidget(MaterialApp(
    home: Builder(builder: (context) {
      hostContext = context;
      return const Scaffold(body: SizedBox.expand());
    }),
  ));

  final outcome = ShareOutcome();
  AffirmationShareExportService.sharePngBestEffort(
    context: hostContext,
    affirmation: shareAffirmation,
    categoryLabel: 'Calm',
  ).then<void>(
    (value) {
      outcome.result = value;
    },
    onError: (Object error) {
      outcome.escapedError = error;
    },
  );

  for (var i = 0; i < 300 && !outcome.completed; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }
  expect(outcome.completed, isTrue, reason: 'export must settle');
  return outcome;
}
