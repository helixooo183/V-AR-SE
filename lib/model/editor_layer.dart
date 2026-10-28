import 'dart:ui' show Offset, Size;

import 'package:flutter/foundation.dart' show immutable;

import 'text_style_spec.dart';

/// Where a layer sits on the canvas.
///
/// [position] is the layer's centre in canvas units. [rotation] is in radians,
/// positive = clockwise on screen. [scale] is uniform.
@immutable
class LayerTransform {
  const LayerTransform({
    this.position = Offset.zero,
    this.rotation = 0,
    this.scale = 1,
  });

  final Offset position;
  final double rotation;
  final double scale;

  LayerTransform copyWith({Offset? position, double? rotation, double? scale}) {
    return LayerTransform(
      position: position ?? this.position,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
    );
  }
}

/// A single item on the canvas. Everything the user adds is a layer.
///
/// Layers are immutable. Edits produce new instances via [copyWith] or
/// [copyBase], which keeps undo/redo snapshots trivially correct.
@immutable
sealed class EditorLayer {
  const EditorLayer({
    required this.id,
    required this.name,
    required this.transform,
    required this.opacity,
    required this.visible,
    required this.locked,
  });

  final String id;
  final String name;
  final LayerTransform transform;

  /// 0..1
  final double opacity;

  /// Hidden layers are not drawn and cannot be selected.
  final bool visible;

  /// Locked layers are drawn but cannot be selected or moved on the canvas.
  final bool locked;

  /// Copies only the fields shared by every layer type.
  EditorLayer copyBase({
    String? id,
    String? name,
    LayerTransform? transform,
    double? opacity,
    bool? visible,
    bool? locked,
  });
}

/// Text layer: wrapped text box with a full style set.
@immutable
final class TextLayer extends EditorLayer {
  const TextLayer({
    required super.id,
    required super.name,
    required super.transform,
    required super.opacity,
    required super.visible,
    required super.locked,
    required this.text,
    required this.style,
    required this.boxWidth,
  });

  final String text;
  final TextStyleSpec style;

  /// Wrap width in canvas units. Height is derived from the text content.
  final double boxWidth;

  TextLayer copyWith({
    String? id,
    String? name,
    LayerTransform? transform,
    double? opacity,
    bool? visible,
    bool? locked,
    String? text,
    TextStyleSpec? style,
    double? boxWidth,
  }) {
    return TextLayer(
      id: id ?? this.id,
      name: name ?? this.name,
      transform: transform ?? this.transform,
      opacity: opacity ?? this.opacity,
      visible: visible ?? this.visible,
      locked: locked ?? this.locked,
      text: text ?? this.text,
      style: style ?? this.style,
      boxWidth: boxWidth ?? this.boxWidth,
    );
  }

  @override
  TextLayer copyBase({
    String? id,
    String? name,
    LayerTransform? transform,
    double? opacity,
    bool? visible,
    bool? locked,
  }) {
    return copyWith(
      id: id,
      name: name,
      transform: transform,
      opacity: opacity,
      visible: visible,
      locked: locked,
    );
  }
}

/// Image layer, e.g. a photo picked from the gallery.
@immutable
final class ImageLayer extends EditorLayer {
  const ImageLayer({
    required super.id,
    required super.name,
    required super.transform,
    required super.opacity,
    required super.visible,
    required super.locked,
    required this.path,
    required this.size,
  });

  final String path;

  /// Displayed size in canvas units.
  final Size size;

  ImageLayer copyWith({
    String? id,
    String? name,
    LayerTransform? transform,
    double? opacity,
    bool? visible,
    bool? locked,
    String? path,
    Size? size,
  }) {
    return ImageLayer(
      id: id ?? this.id,
      name: name ?? this.name,
      transform: transform ?? this.transform,
      opacity: opacity ?? this.opacity,
      visible: visible ?? this.visible,
      locked: locked ?? this.locked,
      path: path ?? this.path,
      size: size ?? this.size,
    );
  }

  @override
  ImageLayer copyBase({
    String? id,
    String? name,
    LayerTransform? transform,
    double? opacity,
    bool? visible,
    bool? locked,
  }) {
    return copyWith(
      id: id,
      name: name,
      transform: transform,
      opacity: opacity,
      visible: visible,
      locked: locked,
    );
  }
}

/// Sticker layer. For now stickers are emoji glyphs; a PNG sticker library
/// can reuse this type later by adding an image-backed variant.
@immutable
final class StickerLayer extends EditorLayer {
  const StickerLayer({
    required super.id,
    required super.name,
    required super.transform,
    required super.opacity,
    required super.visible,
    required super.locked,
    required this.glyph,
    required this.fontSize,
  });

  final String glyph;
  final double fontSize;

  StickerLayer copyWith({
    String? id,
    String? name,
    LayerTransform? transform,
    double? opacity,
    bool? visible,
    bool? locked,
    String? glyph,
    double? fontSize,
  }) {
    return StickerLayer(
      id: id ?? this.id,
      name: name ?? this.name,
      transform: transform ?? this.transform,
      opacity: opacity ?? this.opacity,
      visible: visible ?? this.visible,
      locked: locked ?? this.locked,
      glyph: glyph ?? this.glyph,
      fontSize: fontSize ?? this.fontSize,
    );
  }

  @override
  StickerLayer copyBase({
    String? id,
    String? name,
    LayerTransform? transform,
    double? opacity,
    bool? visible,
    bool? locked,
  }) {
    return copyWith(
      id: id,
      name: name,
      transform: transform,
      opacity: opacity,
      visible: visible,
      locked: locked,
    );
  }
}
