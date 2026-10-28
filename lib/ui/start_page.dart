import 'dart:io';

import 'package:flutter/material.dart';

import '../model/canvas_background.dart';
import '../model/canvas_document.dart';
import '../services/image_import.dart';
import 'canvas_stage.dart';
import 'editor_page.dart';

enum _BackgroundChoice { white, black, transparent, photo }

/// First screen: pick a size and a background, then open a blank canvas.
class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  CanvasPreset _preset = CanvasPreset.square;
  final TextEditingController _customWidth = TextEditingController(text: '1080');
  final TextEditingController _customHeight =
      TextEditingController(text: '1080');
  _BackgroundChoice _background = _BackgroundChoice.white;
  String? _photoPath;
  String? _error;

  @override
  void dispose() {
    _customWidth.dispose();
    _customHeight.dispose();
    super.dispose();
  }

  /// Width and height in pixels for the current choice. Falls back to a
  /// square when the custom fields are not valid numbers yet.
  (double, double) _currentSize() {
    if (_preset != CanvasPreset.custom) return (_preset.width, _preset.height);
    final w = double.tryParse(_customWidth.text.trim());
    final h = double.tryParse(_customHeight.text.trim());
    if (w == null || h == null || w <= 0 || h <= 0) return (1080.0, 1080.0);
    return (w, h);
  }

  Future<void> _pickPhoto() async {
    final path = await pickImagePath();
    if (path == null) return;
    setState(() {
      _photoPath = path;
      _background = _BackgroundChoice.photo;
      _error = null;
    });
  }

  void _create() {
    var (width, height) = _currentSize();

    if (_preset == CanvasPreset.custom) {
      final min = CanvasDocument.minSide;
      final max = CanvasDocument.maxSide;
      final outOfRange = width < min || width > max || height < min || height > max;
      if (outOfRange) {
        setState(() {
          _error = 'Custom sizes must be between ${min.round()} and ${max.round()} px.';
        });
        return;
      }
    }

    final photo = _photoPath;
    if (_background == _BackgroundChoice.photo && photo == null) {
      setState(() => _error = 'Choose a photo for the background first.');
      return;
    }

    final CanvasBackground background = switch (_background) {
      _BackgroundChoice.white => const SolidBackground(Color(0xFFFFFFFF)),
      _BackgroundChoice.black => const SolidBackground(Color(0xFF000000)),
      _BackgroundChoice.transparent => const TransparentBackground(),
      _BackgroundChoice.photo => ImageBackground(photo!),
    };

    width = CanvasDocument.clampSide(width);
    height = CanvasDocument.clampSide(height);

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EditorPage(
          document: CanvasDocument(
            width: width,
            height: height,
            background: background,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (width, height) = _currentSize();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Pixel Canvas')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Start a design', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          const Text(
            'Pick a canvas size and background. You can change both later.',
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 24),
          Text('Canvas size', style: theme.textTheme.titleSmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in CanvasPreset.values)
                ChoiceChip(
                  label: Text(preset.label),
                  selected: _preset == preset,
                  onSelected: (_) => setState(() {
                    _preset = preset;
                    _error = null;
                  }),
                ),
            ],
          ),
          if (_preset == CanvasPreset.custom) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customWidth,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Width (px)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _customHeight,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Height (px)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              height: 200,
              child: AspectRatio(
                aspectRatio: width / height,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: _previewBackground(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              '${width.round()} × ${height.round()} px',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
          Text('Background', style: theme.textTheme.titleSmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('White'),
                selected: _background == _BackgroundChoice.white,
                onSelected: (_) =>
                    setState(() => _background = _BackgroundChoice.white),
              ),
              ChoiceChip(
                label: const Text('Black'),
                selected: _background == _BackgroundChoice.black,
                onSelected: (_) =>
                    setState(() => _background = _BackgroundChoice.black),
              ),
              ChoiceChip(
                label: const Text('Transparent'),
                selected: _background == _BackgroundChoice.transparent,
                onSelected: (_) => setState(
                  () => _background = _BackgroundChoice.transparent,
                ),
              ),
              ChoiceChip(
                label: const Text('Photo'),
                selected: _background == _BackgroundChoice.photo,
                onSelected: (_) => _pickPhoto(),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _create,
            icon: const Icon(Icons.add),
            label: const Text('Create canvas'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewBackground() {
    switch (_background) {
      case _BackgroundChoice.white:
        return const ColoredBox(color: Colors.white);
      case _BackgroundChoice.black:
        return const ColoredBox(color: Colors.black);
      case _BackgroundChoice.transparent:
        return const CustomPaint(
          painter: CheckerboardPainter(cell: 10),
          child: SizedBox.expand(),
        );
      case _BackgroundChoice.photo:
        final path = _photoPath;
        if (path == null) return const ColoredBox(color: Colors.white10);
        return Image.file(File(path), fit: BoxFit.cover);
    }
  }
}
