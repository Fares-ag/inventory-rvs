import 'package:flutter/material.dart';

// Stub for web - dart:io is not available. No-op since web has no local files.
Future<void> deleteLocalFile(String path) async {}

Widget buildLocalFileWidget(
  String imagePath, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  return Container(
    color: Colors.grey.shade200,
    child: Icon(Icons.broken_image, color: Colors.grey.shade400),
  );
}
