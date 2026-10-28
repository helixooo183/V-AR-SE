import 'package:flutter/material.dart';

import '../../model/canvas_document.dart';
import '../../state/editor_controller.dart';

Future<void> showCanvasSizeSheet(
  BuildContext context,
  EditorController controller,
) async {
  controller.beginBatch();
  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => CanvasSizeSheet(controller: controller),
    );
  } finally {
    controller.endBatch();
  }
}

class CanvasSizeSheet extends StatefulWidget {
  const CanvasSizeSheet({super.key, required this.controller});

  final EditorController controller;

  @override
  State<CanvasSizeSheet> createState() => _CanvasSizeSheetState();
}

class _CanvasSizeSheetState extends State<CanvasSizeSheet> {
  late final TextEditingController _width;
  late final TextEditingController _height;
  String? _error;

  @override
  void initState() {
    super.initState();
    final doc = widget.controller.document;
    _width = TextEditingController(text: doc.width.round().toString());
    _height = TextEditingController(text: doc.height.round().toString());
  }

  @override
  void dispose() {
    _width.dispose();
    _height.dispose();
    super.dispose();
  }

  void _applyPreset(CanvasPreset preset) {
    if (preset == CanvasPreset.custom) return;
    widget.controller.resizeCanvas(preset.width, preset.height);
    _width.text = preset.width.round().toString();
    _height.text = preset.height.round().toString();
  }

  void _applyCustom() {
    final w = double.tryParse(_width.text.trim());
    final h = double.tryParse(_height.text.trim());
    final min = CanvasDocument.minSide.toInt();
    final max = CanvasDocument.maxSide.toInt();
    if (w == null || h == null || w < min || h < min || w > max || h > max) {
      setState(() => _error = 'Use values between $min and $max pixels.');
      return;
    }
    setState(() => _error = null);
    widget.controller.resizeCanvas(w, h);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final doc = widget.controller.document;
        final current = doc.width / doc.height;
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
          children: [
            Text('Canvas', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              '${doc.width.round()} × ${doc.height.round()} px',
              style: const TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 16),
            for (final preset in CanvasPreset.values)
              if (preset != CanvasPreset.custom)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _AspectIcon(
                    ratio: preset.width / preset.height,
                    selected: (current - preset.width / preset.height).abs() < 0.001,
                  ),
                  title: Text(preset.label),
                  subtitle: Text(
                    '${preset.width.round()} × ${preset.height.round()}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () => _applyPreset(preset),
                ),
            const Divider(height: 28),
            Text('Custom size', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _width,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Width (px)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('×'),
                ),
                Expanded(
                  child: TextField(
                    controller: _height,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Height (px)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _applyCustom,
              child: const Text('Apply custom size'),
            ),
          ],
        );
      },
    );
  }
}

class _AspectIcon extends StatelessWidget {
  const _AspectIcon({required this.ratio, required this.selected});

  final double ratio;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    const box = 40.0;
    final width = ratio >= 1 ? box : box * ratio;
    final height = ratio >= 1 ? box / ratio : box;
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Colors.white38;
    return SizedBox(
      width: box,
      height: box,
      child: Center(
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}
