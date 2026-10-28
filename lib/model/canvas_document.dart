import 'dart:math' as math;

import 'package:flutter/foundation.dart' show immutable;

import 'canvas_background.dart';
import 'editor_layer.dart';

/// Aspect-ratio presets. Sizes are the exported pixel dimensions.
enum CanvasPreset {
  square('1:1', 1080, 1080),
  portrait45('4:5', 1080, 1350),
  landscape169('16:9', 1920, 1080),
  portrait916('9:16', 1080, 1920),
  portrait34('3:4', 1080, 1440),
  custom('Custom', 1080, 1080);

  const CanvasPreset(this.label, this.width, this.height);

  final String label;
  final double width;
  final double height;
}

/// The whole design: canvas size, background, and layers bottom-to-top.
@immutable
class CanvasDocument {
  static const double minSide = 256;
  static const double maxSide = 4096;

  const CanvasDocument({
    required this.width,
    required this.height,
    required this.background,
    this.layers = const <EditorLayer>[],
  });

  final double width;
  final double height;
  final CanvasBackground background;

  /// Index 0 is the bottom-most layer; the last entry is drawn on top.
  final List<EditorLayer> layers;

  double get shortSide => math.min(width, height);

  CanvasDocument copyWith({
    double? width,
    double? height,
    CanvasBackground? background,
    List<EditorLayer>? layers,
  }) {
    return CanvasDocument(
      width: width ?? this.width,
      height: height ?? this.height,
      background: background ?? this.background,
      layers: List<EditorLayer>.unmodifiable(layers ?? this.layers),
    );
  }

  int indexOf(String id) => layers.indexWhere((layer) => layer.id == id);

  EditorLayer? findLayer(String id) {
    final index = indexOf(id);
    return index < 0 ? null : layers[index];
  }

  /// Clamps a requested dimension into the supported range.
  static double clampSide(double value) => value.clamp(minSide, maxSide).toDouble();
}
