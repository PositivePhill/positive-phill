import 'dart:typed_data';

/// Non-web: PNG download is not used (native uses share sheet).
Future<bool> downloadPngBytes(Uint8List bytes, String filename) async {
  return false;
}
