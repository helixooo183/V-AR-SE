import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' show immutable;

/// What sits behind every layer on the canvas.
@immutable
sealed class CanvasBackground {
  const CanvasBackground();
}

@immutable
final class SolidBackground extends CanvasBackground {
  const SolidBackground(this.color);

  final Color color;
}

/// Two-stop linear gradient. [angleDegrees] 0 = left to right, 90 = top to
/// bottom, following the usual screen convention.
@immutable
final class GradientBackground extends CanvasBackground {
  const GradientBackground({
    required this.start,
    required this.end,
    this.angleDegrees = 90,
  });

  final Color start;
  final Color end;
  final double angleDegrees;
}

@immutable
final class ImageBackground extends CanvasBackground {
  const ImageBackground(this.path);

  /// Local file path; the image is drawn with BoxFit.cover.
  final String path;
}

/// Checkerboard in the editor; exported as a transparent PNG.
@immutable
final class TransparentBackground extends CanvasBackground {
  const TransparentBackground();
}
