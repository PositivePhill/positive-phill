import 'dart:typed_data';

import 'share_png_download_stub.dart'
    if (dart.library.html) 'share_png_download_web.dart' as platform;

Future<bool> downloadPngBytes(Uint8List bytes, String filename) =>
    platform.downloadPngBytes(bytes, filename);
