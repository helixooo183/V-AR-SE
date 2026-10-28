import 'dart:io';
import 'dart:ui' as ui;

import 'package:image_picker/image_picker.dart';

final ImagePicker _picker = ImagePicker();

/// Lets the user pick one photo from the gallery. Returns `null` if cancelled.
Future<String?> pickImagePath() async {
  final file = await _picker.pickImage(source: ImageSource.gallery);
  return file?.path;
}

/// Reads an image's pixel dimensions without decoding the full bitmap.
Future<ui.Size> readImageSize(String path) async {
  final bytes = await File(path).readAsBytes();
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  final descriptor = await ui.ImageDescriptor.encoded(buffer);
  final size = ui.Size(descriptor.width.toDouble(), descriptor.height.toDouble());
  descriptor.dispose();
  buffer.dispose();
  return size;
}
