import 'dart:ui' show Size;

import 'package:flutter/painting.dart';

import '../model/editor_layer.dart';
import '../model/font_catalog.dart';
import '../model/text_style_spec.dart';

/// Padding around text content, in canvas units. Used for the background box,
/// the selection frame and hit testing, so all three agree.
double layerPaddingFor(double fontSize) => fontSize * 0.12;

/// Builds the Flutter [TextStyle] for a text spec.
///
/// The same function feeds measurement and rendering. Keep them in sync.
TextStyle textStyleFor(
  TextStyleSpec spec, {
  bool stroke = false,
  bool withShadow = false,
}) {
  final family = FontCatalog.byId(spec.fontId).family;
  final shadows = withShadow && spec.hasShadow
      ? <Shadow>[
          Shadow(
            color: spec.shadowColor,
            offset: spec.shadowOffset,
            blurRadius: spec.shadowBlur,
          ),
        ]
      : null;

  if (stroke) {
    // A foreground paint and a colour cannot be combined in one TextStyle.
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = spec.strokeWidth
      ..strokeJoin = StrokeJoin.round
      ..color = spec.strokeColor;
    return TextStyle(
      fontFamily: family,
      fontSize: spec.fontSize,
      fontWeight: spec.bold ? FontWeight.w700 : FontWeight.w400,
      fontStyle: spec.italic ? FontStyle.italic : FontStyle.normal,
      letterSpacing: spec.letterSpacing,
      height: spec.lineHeight,
      foreground: outline,
      shadows: shadows,
    );
  }

  return TextStyle(
    fontFamily: family,
    fontSize: spec.fontSize,
    fontWeight: spec.bold ? FontWeight.w700 : FontWeight.w400,
    fontStyle: spec.italic ? FontStyle.italic : FontStyle.normal,
    letterSpacing: spec.letterSpacing,
    height: spec.lineHeight,
    color: spec.color,
    shadows: shadows,
  );
}

/// Text as displayed. An empty layer still needs one line of height so it can
/// be selected and measured.
String displayTextFor(String text, bool uppercase) {
  final value = uppercase ? text.toUpperCase() : text;
  return value.isEmpty ? ' ' : value;
}

/// Full on-canvas size of a text layer, including padding.
Size measureTextLayer(TextLayer layer) {
  final spec = layer.style;
  final pad = layerPaddingFor(spec.fontSize);
  final painter = TextPainter(
    text: TextSpan(
      text: displayTextFor(layer.text, spec.uppercase),
      style: textStyleFor(spec),
    ),
    textAlign: spec.align,
    textDirection: TextDirection.ltr,
  )..layout(minWidth: layer.boxWidth, maxWidth: layer.boxWidth);
  final size = Size(layer.boxWidth + pad * 2, painter.height + pad * 2);
  painter.dispose();
  return size;
}

/// Sticker glyph style, shared by measurement and rendering.
TextStyle stickerStyleFor(StickerLayer layer) =>
    TextStyle(fontSize: layer.fontSize, height: 1.2);

Size measureStickerLayer(StickerLayer layer) {
  final pad = layerPaddingFor(layer.fontSize);
  final painter = TextPainter(
    text: TextSpan(text: layer.glyph, style: stickerStyleFor(layer)),
    textDirection: TextDirection.ltr,
  )..layout();
  final size = Size(painter.width + pad * 2, painter.height + pad * 2);
  painter.dispose();
  return size;
}

/// Size of any layer in canvas units, before its transform is applied.
Size layerSize(EditorLayer layer) {
  return switch (layer) {
    TextLayer text => measureTextLayer(text),
    StickerLayer sticker => measureStickerLayer(sticker),
    ImageLayer image => image.size,
  };
}
