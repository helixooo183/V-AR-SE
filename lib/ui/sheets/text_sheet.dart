import 'package:flutter/material.dart';

import '../../model/editor_layer.dart';
import '../../model/font_catalog.dart';
import '../../model/text_style_spec.dart';
import '../../state/editor_controller.dart';
import '../widgets/sheet_widgets.dart';

/// Opens the text editor for [layerId].
///
/// The whole session is one undo step: changes apply live, and the batch
/// closes when the sheet is dismissed.
Future<void> showTextEditor(
  BuildContext context,
  EditorController controller,
  String layerId,
) async {
  controller.beginBatch();
  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => TextEditorSheet(controller: controller, layerId: layerId),
    );
  } finally {
    controller.endBatch();
  }
}

class TextEditorSheet extends StatefulWidget {
  const TextEditorSheet({
    super.key,
    required this.controller,
    required this.layerId,
  });

  final EditorController controller;
  final String layerId;

  @override
  State<TextEditorSheet> createState() => _TextEditorSheetState();
}

class _TextEditorSheetState extends State<TextEditorSheet> {
  late final TextEditingController _text;

  @override
  void initState() {
    super.initState();
    final layer = widget.controller.document.findLayer(widget.layerId);
    final initial = layer is TextLayer ? layer.text : '';
    // Select everything so the first keystroke replaces the placeholder.
    _text = TextEditingController(
      text: initial,
    )..selection = TextSelection(baseOffset: 0, extentOffset: initial.length);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  /// Reads the latest style at call time so rapid slider changes never
  /// work from a stale copy.
  void _changeStyle(TextStyleSpec Function(TextStyleSpec current) change) {
    final layer = widget.controller.document.findLayer(widget.layerId);
    if (layer is! TextLayer) return;
    widget.controller.updateText(widget.layerId, style: change(layer.style));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final layer = widget.controller.document.findLayer(widget.layerId);
        if (layer is! TextLayer) return const SizedBox.shrink();
        final s = layer.style;
        final media = MediaQuery.of(context);

        return Padding(
          padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
          child: SizedBox(
            height: media.size.height * 0.72,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
              children: [
                TextField(
                  controller: _text,
                  autofocus: true,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (value) =>
                      widget.controller.updateText(widget.layerId, text: value),
                  decoration: InputDecoration(
                    hintText: 'Type your text',
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SheetSection(title: 'Font', child: _fontPicker(s)),
                SheetSection(
                  title: 'Text',
                  child: Column(
                    children: [
                      LabeledSlider(
                        label: 'Size',
                        value: s.fontSize,
                        min: 12,
                        max: 400,
                        onChanged: (v) =>
                            _changeStyle((c) => c.copyWith(fontSize: v)),
                      ),
                      LabeledSlider(
                        label: 'Letter space',
                        value: s.letterSpacing,
                        min: -4,
                        max: 40,
                        onChanged: (v) =>
                            _changeStyle((c) => c.copyWith(letterSpacing: v)),
                      ),
                      LabeledSlider(
                        label: 'Line height',
                        value: s.lineHeight,
                        min: 0.6,
                        max: 2.4,
                        valueLabel: s.lineHeight.toStringAsFixed(2),
                        onChanged: (v) =>
                            _changeStyle((c) => c.copyWith(lineHeight: v)),
                      ),
                      const SizedBox(height: 8),
                      _styleToggles(s),
                      const SizedBox(height: 12),
                      SegmentedButton<TextAlign>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: TextAlign.left,
                            icon: Icon(Icons.format_align_left),
                          ),
                          ButtonSegment(
                            value: TextAlign.center,
                            icon: Icon(Icons.format_align_center),
                          ),
                          ButtonSegment(
                            value: TextAlign.right,
                            icon: Icon(Icons.format_align_right),
                          ),
                        ],
                        selected: <TextAlign>{s.align},
                        onSelectionChanged: (selection) => _changeStyle(
                          (c) => c.copyWith(align: selection.first),
                        ),
                      ),
                    ],
                  ),
                ),
                SheetSection(
                  title: 'Fill colour',
                  child: ColorSwatches(
                    selected: s.color,
                    onChanged: (c) => _changeStyle((cur) => cur.copyWith(color: c)),
                  ),
                ),
                SheetSection(
                  title: 'Outline',
                  child: _effectBlock(
                    enabled: s.hasStroke,
                    onToggle: (on) =>
                        _changeStyle((c) => c.copyWith(hasStroke: on)),
                    controls: [
                      LabeledSlider(
                        label: 'Width',
                        value: s.strokeWidth,
                        min: 1,
                        max: 40,
                        onChanged: (v) =>
                            _changeStyle((c) => c.copyWith(strokeWidth: v)),
                      ),
                      const SizedBox(height: 8),
                      ColorSwatches(
                        selected: s.strokeColor,
                        onChanged: (c) =>
                            _changeStyle((cur) => cur.copyWith(strokeColor: c)),
                      ),
                    ],
                  ),
                ),
                SheetSection(
                  title: 'Shadow',
                  child: _effectBlock(
                    enabled: s.hasShadow,
                    onToggle: (on) =>
                        _changeStyle((c) => c.copyWith(hasShadow: on)),
                    controls: [
                      LabeledSlider(
                        label: 'Blur',
                        value: s.shadowBlur,
                        min: 0,
                        max: 60,
                        onChanged: (v) =>
                            _changeStyle((c) => c.copyWith(shadowBlur: v)),
                      ),
                      const SizedBox(height: 8),
                      ColorSwatches(
                        selected: s.shadowColor,
                        colors: const <Color>[
                          Color(0xCC000000),
                          Color(0x66000000),
                          Color(0xCCFFFFFF),
                          Color(0xCCE53935),
                          Color(0xCC1E88E5),
                        ],
                        onChanged: (c) =>
                            _changeStyle((cur) => cur.copyWith(shadowColor: c)),
                      ),
                    ],
                  ),
                ),
                SheetSection(
                  title: 'Background box',
                  child: _effectBlock(
                    enabled: s.hasBackground,
                    onToggle: (on) =>
                        _changeStyle((c) => c.copyWith(hasBackground: on)),
                    controls: [
                      ColorSwatches(
                        selected: s.backgroundColor,
                        onChanged: (c) => _changeStyle(
                          (cur) => cur.copyWith(backgroundColor: c),
                        ),
                      ),
                    ],
                  ),
                ),
                SheetSection(
                  title: 'Layer',
                  child: LabeledSlider(
                    label: 'Opacity',
                    value: layer.opacity * 100,
                    min: 0,
                    max: 100,
                    valueLabel: '${(layer.opacity * 100).round()}%',
                    onChanged: (v) =>
                        widget.controller.setLayerOpacity(widget.layerId, v / 100),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    widget.controller.deleteLayer(widget.layerId);
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete text'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _fontPicker(TextStyleSpec s) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: FontCatalog.all.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final font = FontCatalog.all[index];
          return ChoiceChip(
            label: Text(
              font.label,
              style: TextStyle(fontFamily: font.family, fontSize: 16),
            ),
            selected: font.id == s.fontId,
            onSelected: (_) =>
                _changeStyle((c) => c.copyWith(fontId: font.id)),
          );
        },
      ),
    );
  }

  Widget _styleToggles(TextStyleSpec s) {
    return Wrap(
      spacing: 8,
      children: [
        FilterChip(
          label: const Text('Bold', style: TextStyle(fontWeight: FontWeight.w700)),
          selected: s.bold,
          onSelected: (on) => _changeStyle((c) => c.copyWith(bold: on)),
        ),
        FilterChip(
          label: const Text('Italic', style: TextStyle(fontStyle: FontStyle.italic)),
          selected: s.italic,
          onSelected: (on) => _changeStyle((c) => c.copyWith(italic: on)),
        ),
        FilterChip(
          label: const Text('UPPERCASE'),
          selected: s.uppercase,
          onSelected: (on) => _changeStyle((c) => c.copyWith(uppercase: on)),
        ),
      ],
    );
  }

  /// A switch row that reveals its controls only when enabled.
  Widget _effectBlock({
    required bool enabled,
    required ValueChanged<bool> onToggle,
    required List<Widget> controls,
  }) {
    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(enabled ? 'On' : 'Off'),
          value: enabled,
          onChanged: onToggle,
        ),
        if (enabled) ...controls,
      ],
    );
  }
}
