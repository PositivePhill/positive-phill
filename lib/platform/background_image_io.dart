import 'dart:io';
import 'package:flutter/widgets.dart';

Widget buildBackground(String path, {Alignment alignment = Alignment.center}) {
  return Image.file(
    File(path),
    fit: BoxFit.cover,
    width: double.infinity,
    height: double.infinity,
    alignment: alignment,
  );
}
