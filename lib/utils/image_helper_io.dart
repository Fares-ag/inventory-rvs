import 'dart:io';
import 'package:flutter/material.dart';

Future<void> deleteLocalFile(String path) async {
  final file = File(path);
  if (await file.exists()) await file.delete();
}

Widget buildLocalFileWidget(
  String imagePath, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  return Image.file(
    File(imagePath),
    width: width,
    height: height,
    fit: fit,
    errorBuilder: errorBuilder ?? (context, error, stackTrace) {
      return Container(
        color: Colors.grey.shade200,
        child: Icon(Icons.broken_image, color: Colors.grey.shade400),
      );
    },
  );
}
