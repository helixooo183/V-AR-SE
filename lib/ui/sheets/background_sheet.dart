import 'package:flutter/material.dart';

import '../../model/canvas_background.dart';
import '../../services/image_import.dart';
import '../../state/editor_controller.dart';
import '../widgets/sheet_widgets.dart';

Future<void> showBackgroundSheet(
  BuildContext context,
  EditorController controller,
) async {
  controller.beginBatch();
  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BackgroundSheet(controller: controller),
    );
  } finally {
    controller.endBatch();
  }
}

enum _BackgroundKind { solid, gradient, image, transparent }

class BackgroundSheet extends StatefulWidget {
  const BackgroundSheet({super.key, required this.controller});

  final EditorController controller;

  @override
  State<BackgroundSheet> createState() => _BackgroundSheetState();
}

class _BackgroundSheetState extends State<BackgroundSheet> {
  late _BackgroundKind _kind;
  Color _solid = Colors.white;
  Color _gradientStart = const Color(0xFF6C5CE7);
  Color _gradientEnd = const Color(0xFFFD79A8);
  double _angle = 90;

  @override
  void initState() {
    super.initState();
    final bg = widget.controller.document.background;
    _kind = switch (bg) {
      SolidBackground() => _BackgroundKind.solid,
      GradientBackground() => _BackgroundKind.gradient,
      ImageBackground() => _BackgroundKind.image,
      TransparentBackground() => _BackgroundKind.transparent,
    };
    if (bg is SolidBackground) _solid = bg.color;
    if (bg is GradientBackground) {
      _gradientStart = bg.start;
      _gradientEnd = bg.end;
      _angle = bg.angleDegrees;
    }
  }

  void _apply(CanvasBackground background) {
    widget.controller.setBackground(background);
  }

  Future<void> _pickPhoto() async {
    final path = await pickImagePath();
    if (path == null) return;
    _apply(ImageBackground(path));
  }

  void _selectKind(_BackgroundKind kind) {
    setState(() => _kind = kind);
    switch (kind) {
      case _BackgroundKind.solid:
        _apply(SolidBackground(_solid));
      case _BackgroundKind.gradient:
        _apply(_gradientValue());
      case _BackgroundKind.image:
        _pickPhoto();
      case _BackgroundKind.transparent:
        _apply(const TransparentBackground());
    }
  }

  GradientBackground _gradientValue() => GradientBackground(
        start: _gradientStart,
        end: _gradientEnd,
        angleDegrees: _angle,
      );

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return SizedBox(
      height: media.size.height * 0.72,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
        children: [
          SegmentedButton<_BackgroundKind>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: _BackgroundKind.solid, label: Text('Solid')),
              ButtonSegment(
                value: _BackgroundKind.gradient,
                label: Text('Gradient'),
              ),
              ButtonSegment(value: _BackgroundKind.image, label: Text('Photo')),
              ButtonSegment(
                value: _BackgroundKind.transparent,
                label: Text('Clear'),
              ),
            ],
            selected: <_BackgroundKind>{_kind},
            onSelectionChanged: (selection) => _selectKind(selection.first),
          ),
          const SizedBox(height: 20),
          switch (_kind) {
            _BackgroundKind.solid => SheetSection(
                title: 'Colour',
                child: ColorSwatches(
                  selected: _solid,
                  onChanged: (c) {
                    setState(() => _solid = c);
                    _apply(SolidBackground(c));
                  },
                ),
              ),
            _BackgroundKind.gradient => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SheetSection(
                    title: 'Start colour',
                    child: ColorSwatches(
                      selected: _gradientStart,
                      onChanged: (c) {
                        setState(() => _gradientStart = c);
                        _apply(_gradientValue());
                      },
                    ),
                  ),
                  SheetSection(
                    title: 'End colour',
                    child: ColorSwatches(
                      selected: _gradientEnd,
                      onChanged: (c) {
                        setState(() => _gradientEnd = c);
                        _apply(_gradientValue());
                      },
                    ),
                  ),
                  SheetSection(
                    title: 'Direction',
                    child: LabeledSlider(
                      label: 'Angle',
                      value: _angle,
                      min: 0,
                      max: 360,
                      valueLabel: '${_angle.round()}°',
                      onChanged: (v) {
                        setState(() => _angle = v);
                        _apply(_gradientValue());
                      },
                    ),
                  ),
                ],
              ),
            _BackgroundKind.image => SheetSection(
                title: 'Photo',
                child: FilledButton.icon(
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Choose from gallery'),
                ),
              ),
            _BackgroundKind.transparent => const Text(
                'Transparent backgrounds show a checkerboard while editing and '
                'export as a PNG with real transparency.',
                style: TextStyle(color: Colors.white70),
              ),
          },
        ],
      ),
    );
  }
}
