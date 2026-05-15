import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:positive_phill/models/affirmation.dart';
import 'package:positive_phill/services/share_png_download.dart';
import 'package:positive_phill/services/share_temp_file_stub.dart'
    if (dart.library.io) 'package:positive_phill/services/share_temp_file_io.dart'
        as share_temp;
import 'package:positive_phill/widgets/share_card_canvas.dart';
import 'package:share_plus/share_plus.dart';

/// Best-effort PNG export for affirmations (vector card only).
class AffirmationShareExportService {
  AffirmationShareExportService._();

  static String shareTextBody(Affirmation affirmation) =>
      '${affirmation.text}\n\n— Positive Phill by Possum Mattern Studios';

  static Future<Uint8List?> renderSharePng({
    required BuildContext context,
    required Affirmation affirmation,
    String? categoryLabel,
  }) async {
    final overlayState = Overlay.of(context, rootOverlay: true);
    final key = GlobalKey();
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        left: -5000,
        top: 0,
        child: Material(
          color: Colors.transparent,
          child: RepaintBoundary(
            key: key,
            child: SizedBox(
              width: 360,
              height: 450,
              child: ShareCardCanvas(
                affirmation: affirmation,
                categoryLabel: categoryLabel,
                colorScheme: Theme.of(context).colorScheme,
              ),
            ),
          ),
        ),
      ),
    );
    overlayState.insert(entry);
    await Future<void>.delayed(Duration.zero);
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 40));

    Uint8List? bytes;
    try {
      final ro = key.currentContext?.findRenderObject();
      final boundary = ro is RenderRepaintBoundary ? ro : null;
      if (boundary == null) {
        entry.remove();
        return null;
      }
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      bytes = byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('AffirmationShareExportService: capture failed: $e');
      bytes = null;
    }
    entry.remove();
    return bytes;
  }

  static Future<bool> sharePngBestEffort({
    required BuildContext context,
    required Affirmation affirmation,
    String? categoryLabel,
  }) async {
    final bytes = await renderSharePng(
      context: context,
      affirmation: affirmation,
      categoryLabel: categoryLabel,
    );
    if (bytes == null || bytes.isEmpty) return false;

    try {
      if (kIsWeb) {
        return downloadPngBytes(bytes, 'positive_phill_affirmation.png');
      }
      final path = await share_temp.writeSharePngBytes(bytes);
      if (path == null) return false;
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(path, mimeType: 'image/png', name: 'positive_phill.png'),
          ],
          text: shareTextBody(affirmation),
        ),
      );
      return true;
    } catch (e) {
      debugPrint('AffirmationShareExportService: share failed: $e');
      return false;
    }
  }
}
