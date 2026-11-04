import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:positive_phill/models/accent_preset.dart';
import 'package:positive_phill/theme.dart';

/// Loads the SDK-bundled Roboto so text widths are realistic. The default
/// test font renders every glyph as a 1em box, which overstates label width.
Future<void> loadRealisticFont() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) {
    fail('FLUTTER_ROOT is not set; run tests with `flutter test`.');
  }
  final dir = '$root/bin/cache/artifacts/material_fonts';
  final loader = FontLoader('Roboto');
  for (final file in ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf']) {
    final bytes = File('$dir/$file').readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

/// App color schemes without GoogleFonts (no network in tests).
ThemeData testTheme(Brightness brightness, {AccentPreset accent = AccentPreset.lavender}) {
  final base = brightness == Brightness.light
      ? const ColorScheme.light(
          primary: LightModeColors.lightPrimary,
          onPrimary: LightModeColors.lightOnPrimary,
          primaryContainer: LightModeColors.lightPrimaryContainer,
          onPrimaryContainer: LightModeColors.lightOnPrimaryContainer,
          surface: LightModeColors.lightSurface,
          onSurface: LightModeColors.lightOnSurface,
        )
      : const ColorScheme.dark(
          primary: DarkModeColors.darkPrimary,
          onPrimary: DarkModeColors.darkOnPrimary,
          primaryContainer: DarkModeColors.darkPrimaryContainer,
          onPrimaryContainer: DarkModeColors.darkOnPrimaryContainer,
          surface: DarkModeColors.darkSurface,
          onSurface: DarkModeColors.darkOnSurface,
        );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'Roboto',
    colorScheme: colorSchemeWithAccent(base, accent, brightness),
  );
}

/// Sizes the test view to [width] logical pixels at DPR 1.
void setLogicalSize(WidgetTester tester, double width, {double height = 900}) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.reset);
}

/// Matches Home's horizontal insets: lane padding 16 + content padding lg.
const double homeHorizontalInset = 16 + AppSpacing.lg;
