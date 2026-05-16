import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path_provider/path_provider.dart';

Future<String?> writeSharePngBytes(Uint8List bytes) async {
  try {
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${dir.path}/positive_phill_share_$timestamp.png';
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  } catch (e, st) {
    debugPrint('writeSharePngBytes failed: $e\n$st');
    return null;
  }
}
