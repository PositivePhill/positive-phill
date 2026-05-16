import 'dart:typed_data';

import 'package:positive_phill/services/share_png_download_stub.dart'
    if (dart.library.html) 'package:positive_phill/services/share_png_download_web.dart'
    as platform;

Future<bool> downloadPngBytes(Uint8List bytes, String filename) =>
    platform.downloadPngBytes(bytes, filename);
