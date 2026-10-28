import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

/// Album used in the device gallery for exported designs.
const String exportAlbumName = 'Pixel Canvas';

/// Renders the canvas inside [boundaryKey] at full document resolution and
/// saves it to the device gallery as a PNG.
///
/// The boundary must wrap only the document content. Selection frames and
/// the checkerboard are drawn outside it, so they never appear in the output.
///
/// Returns the temporary file path that was saved.
Future<String> exportCanvasToGallery(GlobalKey boundaryKey) async {
  // Let any pending frame (for example a freshly decoded image) finish first.
  await WidgetsBinding.instance.endOfFrame;

  final renderObject = boundaryKey.currentContext?.findRenderObject();
  if (renderObject is! RenderRepaintBoundary) {
    throw StateError('The canvas is not ready to export yet.');
  }

  // The boundary is laid out at document size, so a pixel ratio of 1 gives
  // exactly the document resolution.
  final image = await renderObject.toImage(pixelRatio: 1.0);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (data == null) {
    throw StateError('Could not encode the design as PNG.');
  }

  final dir = await getTemporaryDirectory();
  final file = File(
    '${dir.path}/pixel_canvas_${DateTime.now().millisecondsSinceEpoch}.png',
  );
  await file.writeAsBytes(data.buffer.asUint8List(), flush: true);

  if (!await Gal.hasAccess(toAlbum: true)) {
    final granted = await Gal.requestAccess(toAlbum: true);
    if (!granted) {
      throw StateError('Photo library access was denied.');
    }
  }
  await Gal.putImage(file.path, album: exportAlbumName);
  return file.path;
}
