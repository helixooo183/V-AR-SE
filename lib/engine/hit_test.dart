import 'dart:math' as math;
import 'dart:ui' show Offset;

import '../model/editor_layer.dart';
import 'text_metrics.dart';

/// Whether [point] (canvas units) lands inside [layer], accounting for its
/// position, rotation and scale.
bool layerContainsPoint(EditorLayer layer, Offset point) {
  final size = layerSize(layer);
  final t = layer.transform;

  // Map the point into the layer's un-transformed local space: undo the
  // translation, then the rotation (by -θ), then the scale.
  final dx = point.dx - t.position.dx;
  final dy = point.dy - t.position.dy;
  final cosA = math.cos(-t.rotation);
  final sinA = math.sin(-t.rotation);
  final localX = (dx * cosA - dy * sinA) / t.scale;
  final localY = (dx * sinA + dy * cosA) / t.scale;

  return localX.abs() <= size.width / 2 && localY.abs() <= size.height / 2;
}

/// Topmost visible, unlocked layer under [point], or `null`.
///
/// [layers] is bottom-to-top, so we scan from the end. Locked and hidden
/// layers are skipped, letting taps reach whatever is underneath them.
EditorLayer? topLayerAt(List<EditorLayer> layers, Offset point) {
  for (var i = layers.length - 1; i >= 0; i--) {
    final layer = layers[i];
    if (!layer.visible || layer.locked) continue;
    if (layerContainsPoint(layer, point)) return layer;
  }
  return null;
}
