import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../engine/hit_test.dart';
import '../model/canvas_background.dart';
import '../model/canvas_document.dart';
import '../model/editor_layer.dart';
import '../model/text_style_spec.dart';

/// Owns the document, the selection and the undo/redo history.
///
/// Undo works on whole-document snapshots. Because every document is
/// immutable, a snapshot is just a reference, so history is cheap.
///
/// Continuous interactions (dragging, pinching, slider scrubbing) are wrapped
/// in [beginBatch]/[endBatch]. The whole interaction becomes one undo step
/// instead of one per frame.
class EditorController extends ChangeNotifier {
  EditorController({required CanvasDocument document}) : _document = document;

  static const int historyLimit = 100;

  /// Canvas units used when a new layer is added.
  static const double defaultTextWidthFactor = 0.8;
  static const double defaultImageFitFactor = 0.8;
  static const double duplicateOffset = 40;

  CanvasDocument _document;
  String? _selectedId;
  final List<CanvasDocument> _undoStack = <CanvasDocument>[];
  final List<CanvasDocument> _redoStack = <CanvasDocument>[];
  CanvasDocument? _batchBase;
  bool _batchDirty = false;
  int _idSeed = 0;

  CanvasDocument get document => _document;
  String? get selectedId => _selectedId;
  EditorLayer? get selectedLayer {
    final id = _selectedId;
    return id == null ? null : _document.findLayer(id);
  }

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  bool get isBatching => _batchBase != null;

  // ---------------------------------------------------------------------------
  // History
  // ---------------------------------------------------------------------------

  /// Starts grouping edits into one undo step. No-op if already batching.
  void beginBatch() {
    if (_batchBase != null) return;
    _batchBase = _document;
    _batchDirty = false;
  }

  /// Ends the current batch and records one undo step if anything changed.
  void endBatch() {
    final base = _batchBase;
    if (base == null) return;
    if (_batchDirty) _pushUndo(base);
    _batchBase = null;
    _batchDirty = false;
  }

  void undo() {
    if (_batchBase != null || _undoStack.isEmpty) return;
    _redoStack.add(_document);
    _document = _undoStack.removeLast();
    _ensureSelectionValid();
    notifyListeners();
  }

  void redo() {
    if (_batchBase != null || _redoStack.isEmpty) return;
    _undoStack.add(_document);
    _document = _redoStack.removeLast();
    _ensureSelectionValid();
    notifyListeners();
  }

  void _pushUndo(CanvasDocument snapshot) {
    _undoStack.add(snapshot);
    if (_undoStack.length > historyLimit) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  /// Single funnel for every document change.
  void _apply(CanvasDocument next, {bool recordHistory = true}) {
    if (_batchBase != null) {
      _batchDirty = true;
    } else if (recordHistory) {
      _pushUndo(_document);
    }
    _document = next;
    _ensureSelectionValid();
    notifyListeners();
  }

  void _ensureSelectionValid() {
    final id = _selectedId;
    if (id != null && _document.findLayer(id) == null) _selectedId = null;
  }

  String _nextId() {
    _idSeed++;
    return 'layer-${DateTime.now().microsecondsSinceEpoch}-$_idSeed';
  }

  // ---------------------------------------------------------------------------
  // Selection
  // ---------------------------------------------------------------------------

  void select(String? id) {
    if (_selectedId == id) return;
    _selectedId = id;
    notifyListeners();
  }

  /// Topmost visible, unlocked layer at [canvasPoint], if any.
  EditorLayer? layerAt(Offset canvasPoint) =>
      topLayerAt(_document.layers, canvasPoint);

  // ---------------------------------------------------------------------------
  // Canvas
  // ---------------------------------------------------------------------------

  void setBackground(CanvasBackground background) {
    _apply(_document.copyWith(background: background));
  }

  /// Changes the canvas size. Layer positions scale proportionally so the
  /// composition keeps its relative layout.
  void resizeCanvas(double width, double height) {
    final doc = _document;
    final newWidth = CanvasDocument.clampSide(width);
    final newHeight = CanvasDocument.clampSide(height);
    if (newWidth == doc.width && newHeight == doc.height) return;

    final sx = newWidth / doc.width;
    final sy = newHeight / doc.height;
    final layers = doc.layers.map((layer) {
      final p = layer.transform.position;
      return layer.copyBase(
        transform: layer.transform.copyWith(
          position: Offset(p.dx * sx, p.dy * sy),
        ),
      );
    }).toList();

    _apply(doc.copyWith(width: newWidth, height: newHeight, layers: layers));
  }

  // ---------------------------------------------------------------------------
  // Adding layers
  // ---------------------------------------------------------------------------

  int _countOf<T extends EditorLayer>() =>
      _document.layers.whereType<T>().length;

  /// Adds a text layer centred on the canvas and selects it.
  String addText({String text = 'Your text', TextStyleSpec? style}) {
    final doc = _document;
    final id = _nextId();
    final spec =
        style ?? TextStyleSpec(fontSize: (doc.shortSide * 0.09).roundToDouble());
    _selectedId = id;
    _apply(
      doc.copyWith(
        layers: [
          ...doc.layers,
          TextLayer(
            id: id,
            name: 'Text ${_countOf<TextLayer>() + 1}',
            transform: LayerTransform(
              position: Offset(doc.width / 2, doc.height / 2),
            ),
            opacity: 1,
            visible: true,
            locked: false,
            text: text,
            style: spec,
            boxWidth: doc.width * defaultTextWidthFactor,
          ),
        ],
      ),
    );
    return id;
  }

  /// Adds an image layer, scaled down to fit inside the canvas if needed.
  String addImage({required String path, required Size naturalSize}) {
    final doc = _document;
    final id = _nextId();
    final width = naturalSize.width > 0 ? naturalSize.width : 1.0;
    final height = naturalSize.height > 0 ? naturalSize.height : 1.0;
    final fit = math.min(
      1.0,
      math.min(
        doc.width * defaultImageFitFactor / width,
        doc.height * defaultImageFitFactor / height,
      ),
    );
    _selectedId = id;
    _apply(
      doc.copyWith(
        layers: [
          ...doc.layers,
          ImageLayer(
            id: id,
            name: 'Image ${_countOf<ImageLayer>() + 1}',
            transform: LayerTransform(
              position: Offset(doc.width / 2, doc.height / 2),
            ),
            opacity: 1,
            visible: true,
            locked: false,
            path: path,
            size: Size(width * fit, height * fit),
          ),
        ],
      ),
    );
    return id;
  }

  /// Adds an emoji sticker centred on the canvas and selects it.
  String addSticker(String glyph) {
    final doc = _document;
    final id = _nextId();
    _selectedId = id;
    _apply(
      doc.copyWith(
        layers: [
          ...doc.layers,
          StickerLayer(
            id: id,
            name: 'Sticker ${_countOf<StickerLayer>() + 1}',
            transform: LayerTransform(
              position: Offset(doc.width / 2, doc.height / 2),
            ),
            opacity: 1,
            visible: true,
            locked: false,
            glyph: glyph,
            fontSize: (doc.shortSide * 0.2).roundToDouble(),
          ),
        ],
      ),
    );
    return id;
  }

  // ---------------------------------------------------------------------------
  // Editing layers
  // ---------------------------------------------------------------------------

  /// Replaces one layer by applying [update]. No-op for unknown ids.
  void updateLayer(
    String id,
    EditorLayer Function(EditorLayer layer) update, {
    bool recordHistory = true,
  }) {
    final doc = _document;
    final index = doc.indexOf(id);
    if (index < 0) return;
    final layers = List<EditorLayer>.of(doc.layers);
    layers[index] = update(layers[index]);
    _apply(doc.copyWith(layers: layers), recordHistory: recordHistory);
  }

  void setLayerTransform(String id, LayerTransform transform) {
    updateLayer(id, (layer) => layer.copyBase(transform: transform));
  }

  void setLayerOpacity(String id, double opacity) {
    updateLayer(
      id,
      (layer) => layer.copyBase(opacity: opacity.clamp(0.0, 1.0).toDouble()),
    );
  }

  void updateText(String id, {String? text, TextStyleSpec? style}) {
    updateLayer(id, (layer) {
      if (layer is! TextLayer) return layer;
      return layer.copyWith(text: text, style: style);
    });
  }

  void toggleVisibility(String id) {
    updateLayer(id, (layer) => layer.copyBase(visible: !layer.visible));
  }

  void toggleLock(String id) {
    updateLayer(id, (layer) => layer.copyBase(locked: !layer.locked));
  }

  void deleteLayer(String id) {
    final doc = _document;
    if (doc.indexOf(id) < 0) return;
    _apply(
      doc.copyWith(
        layers: doc.layers.where((layer) => layer.id != id).toList(),
      ),
    );
  }

  /// Inserts a copy just above the original and selects it.
  void duplicateLayer(String id) {
    final doc = _document;
    final index = doc.indexOf(id);
    if (index < 0) return;
    final original = doc.layers[index];
    final copyId = _nextId();
    final copy = original.copyBase(
      id: copyId,
      name: '${original.name} copy',
      transform: original.transform.copyWith(
        position: original.transform.position +
            const Offset(duplicateOffset, duplicateOffset),
      ),
    );
    final layers = List<EditorLayer>.of(doc.layers)..insert(index + 1, copy);
    _selectedId = copyId;
    _apply(doc.copyWith(layers: layers));
  }

  // ---------------------------------------------------------------------------
  // Stacking order
  // ---------------------------------------------------------------------------

  /// Moves the layer at [from] to [to] in the bottom-to-top order.
  /// [to] is the index in the list after removal.
  void moveLayer(int from, int to) {
    final doc = _document;
    if (from < 0 || from >= doc.layers.length) return;
    final layers = List<EditorLayer>.of(doc.layers);
    final item = layers.removeAt(from);
    final target = to.clamp(0, layers.length).toInt();
    layers.insert(target, item);
    if (target == from) return;
    _apply(doc.copyWith(layers: layers));
  }

  /// Moves a layer one step up ([delta] = 1) or down ([delta] = -1).
  void stackLayer(String id, int delta) {
    final index = _document.indexOf(id);
    if (index < 0) return;
    moveLayer(index, index + delta);
  }
}
