import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<String?> writeSharePngBytes(Uint8List bytes) async {
  try {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/positive_phill_share.png';
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  } catch (_) {
    return null;
  }
}
