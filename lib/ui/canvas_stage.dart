import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../engine/text_metrics.dart';
import '../model/canvas_background.dart';
import '../model/canvas_document.dart';
import '../model/editor_layer.dart';
import '../state/editor_controller.dart';

const double _minLayerScale = 0.05;
const double _maxLayerScale = 20;
const Color selectionColor = Color(0xFF3D8BFD);

/// Renders the design and handles direct manipulation of layers.
///
/// Everything is laid out in canvas units and then scaled to fit the screen
/// with a [FittedBox]. Hit testing, gestures and rendering therefore share one
/// coordinate system, and the export captures the same pixels the user sees.
class CanvasStage extends StatefulWidget {
  const CanvasStage({
    super.key,
    required this.controller,
    required this.boundaryKey,
    this.onEditText,
  });

  final EditorController controller;

  /// Wraps only the document content. Used by the exporter.
  final GlobalKey boundaryKey;

  /// Called on double-tap of a text layer.
  final ValueChanged<String>? onEditText;

  @override
  State<CanvasStage> createState() => _CanvasStageState();
}

class _CanvasStageState extends State<CanvasStage> {
  /// Screen pixels per canvas unit, refreshed on every layout.
  double _displayScale = 1;
  Offset _lastDoubleTapCanvas = Offset.zero;

  String? _gestureLayerId;
  Offset _gestureStartFocal = Offset.zero;
  LayerTransform _gestureStartTransform = const LayerTransform();

  @override
  void dispose() {
    if (_gestureLayerId != null) widget.controller.endBatch();
    super.dispose();
  }

  Offset _toCanvas(Offset local) => local / _displayScale;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final doc = widget.controller.document;
        return LayoutBuilder(
          builder: (context, constraints) {
            final fit = math.min(
              constraints.maxWidth / doc.width,
              constraints.maxHeight / doc.height,
            );
            final scale = fit.isFinite && fit > 0 ? fit : 1.0;
            _displayScale = scale;
            return Center(
              child: SizedBox(
                width: doc.width * scale,
                height: doc.height * scale,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: _handleTapUp,
                  onDoubleTapDown: (details) {
                    _lastDoubleTapCanvas = _toCanvas(details.localPosition);
                  },
                  onDoubleTap: _handleDoubleTap,
                  onScaleStart: _handleScaleStart,
                  onScaleUpdate: _handleScaleUpdate,
                  onScaleEnd: _handleScaleEnd,
                  child: _buildCanvas(context, doc, scale),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCanvas(BuildContext context, CanvasDocument doc, double scale) {
    final selected = widget.controller.selectedLayer;
    return MediaQuery(
      // Keep text metrics identical to the measurement code, whatever the
      // user's system font size is.
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          if (doc.background is TransparentBackground)
            const Positioned.fill(
              child: CustomPaint(painter: CheckerboardPainter()),
            ),
          FittedBox(
            fit: BoxFit.fill,
            child: SizedBox(
              width: doc.width,
              height: doc.height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  RepaintBoundary(
                    key: widget.boundaryKey,
                    child: SizedBox(
                      width: doc.width,
                      height: doc.height,
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          _backgroundView(doc.background),
                          for (final layer in doc.layers)
                            if (layer.visible) _positionedLayer(layer),
                        ],
                      ),
                    ),
                  ),
                  // Outside the boundary, so it is never exported.
                  if (selected != null && selected.visible)
                    _selectionOverlay(selected, scale),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Gestures
  // ---------------------------------------------------------------------------

  void _handleTapUp(TapUpDetails details) {
    final hit = widget.controller.layerAt(_toCanvas(details.localPosition));
    widget.controller.select(hit?.id);
  }

  void _handleDoubleTap() {
    final hit = widget.controller.layerAt(_lastDoubleTapCanvas);
    if (hit == null) return;
    widget.controller.select(hit.id);
    if (hit is TextLayer) widget.onEditText?.call(hit.id);
  }

  void _handleScaleStart(ScaleStartDetails details) {
    final focal = _toCanvas(details.localFocalPoint);
    final hit = widget.controller.layerAt(focal);
    if (hit == null) {
      _gestureLayerId = null;
      return;
    }
    widget.controller.select(hit.id);
    widget.controller.beginBatch();
    _gestureLayerId = hit.id;
    _gestureStartFocal = focal;
    _gestureStartTransform = hit.transform;
  }

  /// Pan, pinch and rotate in one step.
  ///
  /// The point under the fingers stays under the fingers: the layer centre is
  /// placed so the start focal point maps to the current focal point after
  /// scaling and rotating around it.
  void _handleScaleUpdate(ScaleUpdateDetails details) {
    final id = _gestureLayerId;
    if (id == null) return;

    final focal = _toCanvas(details.localFocalPoint);
    final start = _gestureStartTransform;
    final newScale = math.max(
      _minLayerScale,
      math.min(_maxLayerScale, start.scale * details.scale),
    );
    final ratio = newScale / start.scale;

    final fromCentre = _gestureStartFocal - start.position;
    final cosR = math.cos(details.rotation);
    final sinR = math.sin(details.rotation);
    final rotated = Offset(
          fromCentre.dx * cosR - fromCentre.dy * sinR,
          fromCentre.dx * sinR + fromCentre.dy * cosR,
        ) *
        ratio;

    widget.controller.setLayerTransform(
      id,
      LayerTransform(
        position: focal - rotated,
        rotation: start.rotation + details.rotation,
        scale: newScale,
      ),
    );
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    if (_gestureLayerId == null) return;
    _gestureLayerId = null;
    widget.controller.endBatch();
  }

  // ---------------------------------------------------------------------------
  // Rendering
  // ---------------------------------------------------------------------------

  Widget _backgroundView(CanvasBackground background) {
    return switch (background) {
      SolidBackground b => ColoredBox(
          color: b.color,
          child: const SizedBox.expand(),
        ),
      GradientBackground b => DecoratedBox(
          decoration: BoxDecoration(gradient: _gradientFor(b)),
          child: const SizedBox.expand(),
        ),
      ImageBackground b => SizedBox.expand(
          child: Image.file(
            File(b.path),
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) => const ColoredBox(
              color: Color(0xFF2A2A2E),
              child: SizedBox.expand(),
            ),
          ),
        ),
      TransparentBackground() => const SizedBox.expand(),
    };
  }

  LinearGradient _gradientFor(GradientBackground b) {
    final radians = b.angleDegrees * math.pi / 180;
    return LinearGradient(
      begin: Alignment(-math.cos(radians), -math.sin(radians)),
      end: Alignment(math.cos(radians), math.sin(radians)),
      colors: [b.start, b.end],
    );
  }

  /// Matrix that places a layer's content: scale and rotate around the
  /// content centre. Applied after the content is shifted so its centre sits
  /// at the origin.
  Matrix4 _placementMatrix(LayerTransform t) {
    return Matrix4.identity()
      ..rotateZ(t.rotation)
      ..scale(t.scale);
  }

  /// Must be a direct child of the Stack, so it is returned as [Positioned].
  Widget _positionedLayer(EditorLayer layer) {
    final t = layer.transform;
    Widget content = _layerContent(layer);
    if (layer.opacity < 1) {
      content = Opacity(
        opacity: layer.opacity.clamp(0.0, 1.0).toDouble(),
        child: content,
      );
    }
    return Positioned(
      left: t.position.dx,
      top: t.position.dy,
      child: Transform(
        transform: _placementMatrix(t),
        alignment: Alignment.topLeft,
        child: FractionalTranslation(
          translation: const Offset(-0.5, -0.5),
          child: content,
        ),
      ),
    );
  }

  Widget _selectionOverlay(EditorLayer layer, double scale) {
    final t = layer.transform;
    final size = layerSize(layer);
    final frameWidth = 2.5 / scale;
    final handle = 14 / scale;
    final half = handle / 2;

    return Positioned(
      left: t.position.dx,
      top: t.position.dy,
      child: Transform(
        transform: _placementMatrix(t),
        alignment: Alignment.topLeft,
        child: FractionalTranslation(
          translation: const Offset(-0.5, -0.5),
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: IgnorePointer(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selectionColor,
                          width: frameWidth,
                        ),
                      ),
                    ),
                  ),
                  Positioned(left: -half, top: -half, child: _handleDot(handle)),
                  Positioned(right: -half, top: -half, child: _handleDot(handle)),
                  Positioned(left: -half, bottom: -half, child: _handleDot(handle)),
                  Positioned(right: -half, bottom: -half, child: _handleDot(handle)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _handleDot(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: selectionColor, width: size * 0.18),
      ),
    );
  }

  Widget _layerContent(EditorLayer layer) {
    return switch (layer) {
      TextLayer text => _textContent(text),
      StickerLayer sticker => _stickerContent(sticker),
      ImageLayer image => SizedBox(
          width: image.size.width,
          height: image.size.height,
          child: Image.file(
            File(image.path),
            fit: BoxFit.fill,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) => const ColoredBox(
              color: Color(0x33FFFFFF),
              child: Center(child: Icon(Icons.broken_image_outlined)),
            ),
          ),
        ),
    };
  }

  /// Mirrors [measureTextLayer]: same padding, style and box width.
  Widget _textContent(TextLayer layer) {
    final spec = layer.style;
    final pad = layerPaddingFor(spec.fontSize);
    final text = displayTextFor(layer.text, spec.uppercase);

    final Widget body;
    if (spec.hasStroke) {
      // The outline sits underneath, the fill on top.
      body = Stack(
        fit: StackFit.passthrough,
        children: [
          Text(
            text,
            textAlign: spec.align,
            style: textStyleFor(spec, stroke: true, withShadow: true),
          ),
          Text(text, textAlign: spec.align, style: textStyleFor(spec)),
        ],
      );
    } else {
      body = Text(
        text,
        textAlign: spec.align,
        style: textStyleFor(spec, withShadow: true),
      );
    }

    Widget content = Padding(
      padding: EdgeInsets.all(pad),
      child: SizedBox(width: layer.boxWidth, child: body),
    );
    if (spec.hasBackground) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          color: spec.backgroundColor,
          borderRadius: BorderRadius.circular(pad * 1.5),
        ),
        child: content,
      );
    }
    return content;
  }

  Widget _stickerContent(StickerLayer layer) {
    return Padding(
      padding: EdgeInsets.all(layerPaddingFor(layer.fontSize)),
      child: Text(layer.glyph, style: stickerStyleFor(layer)),
    );
  }
}

/// Transparency indicator for the editor. Not part of the export.
class CheckerboardPainter extends CustomPainter {
  const CheckerboardPainter({this.cell = 16});

  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final light = Paint()..color = const Color(0xFFFFFFFF);
    final dark = Paint()..color = const Color(0xFFD9D9DE);
    canvas.drawRect(Offset.zero & size, light);
    var row = 0;
    for (var y = 0.0; y < size.height; y += cell) {
      final start = row.isEven ? 0.0 : cell;
      for (var x = start; x < size.width; x += cell * 2) {
        canvas.drawRect(Rect.fromLTWH(x, y, cell, cell), dark);
      }
      row++;
    }
  }

  @override
  bool shouldRepaint(covariant CheckerboardPainter oldDelegate) {
    return oldDelegate.cell != cell;
  }
}
