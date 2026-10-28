import 'package:flutter/material.dart';

import '../model/canvas_document.dart';
import '../model/editor_layer.dart';
import '../services/export_service.dart';
import '../services/image_import.dart';
import '../state/editor_controller.dart';
import 'canvas_stage.dart';
import 'sheets/background_sheet.dart';
import 'sheets/canvas_size_sheet.dart';
import 'sheets/layer_sheet.dart';
import 'sheets/sticker_sheet.dart';
import 'sheets/text_sheet.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({super.key, required this.document});

  final CanvasDocument document;

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  late final EditorController _controller =
      EditorController(document: widget.document);
  final GlobalKey _boundaryKey = GlobalKey();
  bool _exporting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _export() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      await exportCanvasToGallery(_boundaryKey);
      _showMessage('Saved to your gallery in "$exportAlbumName"');
    } on Object catch (error) {
      _showMessage('Export failed: $error');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  /// Adds a text layer and opens the editor. The add and the edits form one
  /// undo step.
  Future<void> _addText() async {
    _controller.beginBatch();
    final id = _controller.addText();
    await showTextEditor(context, _controller, id);
    _controller.endBatch();
  }

  Future<void> _addImage() async {
    final path = await pickImagePath();
    if (path == null) return;
    try {
      final size = await readImageSize(path);
      _controller.addImage(path: path, naturalSize: size);
    } on Object {
      _showMessage('That image could not be read.');
    }
  }

  void _openTextEditor(String id) {
    showTextEditor(context, _controller, id);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final doc = _controller.document;
        final selected = _controller.selectedLayer;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              '${doc.width.round()} × ${doc.height.round()}',
              style: const TextStyle(fontSize: 16),
            ),
            actions: [
              IconButton(
                tooltip: 'Undo',
                icon: const Icon(Icons.undo),
                onPressed: _controller.canUndo ? _controller.undo : null,
              ),
              IconButton(
                tooltip: 'Redo',
                icon: const Icon(Icons.redo),
                onPressed: _controller.canRedo ? _controller.redo : null,
              ),
              IconButton(
                tooltip: 'Save to gallery',
                icon: _exporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.file_download_outlined),
                onPressed: _exporting ? null : _export,
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: Container(
                  color: const Color(0xFF0C0C0E),
                  padding: const EdgeInsets.all(12),
                  child: CanvasStage(
                    controller: _controller,
                    boundaryKey: _boundaryKey,
                    onEditText: _openTextEditor,
                  ),
                ),
              ),
              if (selected != null) _selectionBar(selected),
              _mainToolbar(),
            ],
          ),
        );
      },
    );
  }

  /// Shown only while a layer is selected.
  Widget _selectionBar(EditorLayer layer) {
    final doc = _controller.document;
    final index = doc.indexOf(layer.id);
    final count = doc.layers.length;
    return Material(
      color: const Color(0xFF1E1E21),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  layer.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (layer is TextLayer)
                IconButton(
                  tooltip: 'Edit text',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _openTextEditor(layer.id),
                ),
              IconButton(
                tooltip: 'Duplicate',
                icon: const Icon(Icons.copy_outlined),
                onPressed: () => _controller.duplicateLayer(layer.id),
              ),
              IconButton(
                tooltip: 'Bring forward',
                icon: const Icon(Icons.arrow_upward),
                onPressed: index < count - 1
                    ? () => _controller.stackLayer(layer.id, 1)
                    : null,
              ),
              IconButton(
                tooltip: 'Send backward',
                icon: const Icon(Icons.arrow_downward),
                onPressed: index > 0
                    ? () => _controller.stackLayer(layer.id, -1)
                    : null,
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _controller.deleteLayer(layer.id),
              ),
              IconButton(
                tooltip: 'Deselect',
                icon: const Icon(Icons.close),
                onPressed: () => _controller.select(null),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mainToolbar() {
    return Material(
      color: const Color(0xFF1E1E21),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 76,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            children: [
              _toolButton(Icons.text_fields, 'Text', _addText),
              _toolButton(Icons.image_outlined, 'Image', _addImage),
              _toolButton(
                Icons.emoji_emotions_outlined,
                'Sticker',
                () => showStickerSheet(context, _controller),
              ),
              _toolButton(
                Icons.wallpaper_outlined,
                'Background',
                () => showBackgroundSheet(context, _controller),
              ),
              _toolButton(
                Icons.aspect_ratio,
                'Canvas',
                () => showCanvasSizeSheet(context, _controller),
              ),
              _toolButton(
                Icons.layers_outlined,
                'Layers',
                () => showLayerSheet(context, _controller),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
