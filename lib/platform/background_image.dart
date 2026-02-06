import 'package:flutter/widgets.dart';
import 'package:positive_phill/platform/background_image_io.dart'
    if (dart.library.html) 'package:positive_phill/platform/background_image_web.dart' as impl;

Widget buildBackground(String path, {Alignment alignment = Alignment.center}) =>
    impl.buildBackground(path, alignment: alignment);

abstract class BackgroundImageBuilder {
  static Widget build(String path, {Alignment alignment = Alignment.center}) =>
      buildBackground(path, alignment: alignment);
}
