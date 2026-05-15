// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:typed_data';

Future<bool> downloadPngBytes(Uint8List bytes, String filename) async {
  String? url;
  try {
    final blob = html.Blob([bytes], 'image/png');
    url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return true;
  } catch (_) {
    return false;
  } finally {
    final u = url;
    if (u != null) {
      html.Url.revokeObjectUrl(u);
    }
  }
}
