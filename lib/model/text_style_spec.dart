import 'dart:ui' show Color, Offset, TextAlign;

import 'package:flutter/foundation.dart' show immutable;

/// Everything that controls how a text layer looks.
///
/// Pure, immutable data. All lengths are in canvas units (the document
/// resolution), never screen pixels, so a layer looks identical at any zoom
/// level and in the exported PNG.
@immutable
class TextStyleSpec {
  const TextStyleSpec({
    this.fontId = 'inter',
    this.fontSize = 96,
    this.color = const Color(0xFFFFFFFF),
    this.bold = false,
    this.italic = false,
    this.uppercase = false,
    this.align = TextAlign.center,
    this.letterSpacing = 0,
    this.lineHeight = 1.15,
    this.hasStroke = false,
    this.strokeWidth = 6,
    this.strokeColor = const Color(0xFF000000),
    this.hasShadow = false,
    this.shadowColor = const Color(0x99000000),
    this.shadowBlur = 12,
    this.shadowOffset = const Offset(0, 6),
    this.hasBackground = false,
    this.backgroundColor = const Color(0xFF000000),
  });

  /// Key into [FontCatalog]; never a raw family name.
  final String fontId;
  final double fontSize;
  final Color color;
  final bool bold;
  final bool italic;
  final bool uppercase;
  final TextAlign align;
  final double letterSpacing;

  /// Line height as a multiple of [fontSize].
  final double lineHeight;

  final bool hasStroke;
  final double strokeWidth;
  final Color strokeColor;

  final bool hasShadow;
  final Color shadowColor;
  final double shadowBlur;
  final Offset shadowOffset;

  /// Solid box drawn behind the text (the "highlight" look).
  final bool hasBackground;
  final Color backgroundColor;

  TextStyleSpec copyWith({
    String? fontId,
    double? fontSize,
    Color? color,
    bool? bold,
    bool? italic,
    bool? uppercase,
    TextAlign? align,
    double? letterSpacing,
    double? lineHeight,
    bool? hasStroke,
    double? strokeWidth,
    Color? strokeColor,
    bool? hasShadow,
    Color? shadowColor,
    double? shadowBlur,
    Offset? shadowOffset,
    bool? hasBackground,
    Color? backgroundColor,
  }) {
    return TextStyleSpec(
      fontId: fontId ?? this.fontId,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      uppercase: uppercase ?? this.uppercase,
      align: align ?? this.align,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      lineHeight: lineHeight ?? this.lineHeight,
      hasStroke: hasStroke ?? this.hasStroke,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      strokeColor: strokeColor ?? this.strokeColor,
      hasShadow: hasShadow ?? this.hasShadow,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowBlur: shadowBlur ?? this.shadowBlur,
      shadowOffset: shadowOffset ?? this.shadowOffset,
      hasBackground: hasBackground ?? this.hasBackground,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }
}
