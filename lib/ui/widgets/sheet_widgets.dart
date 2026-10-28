import 'package:flutter/material.dart';

/// Colours offered in every colour picker. A fixed palette keeps the UI quick
/// to use one-handed; a free-form picker can be added later.
const List<Color> paletteColors = <Color>[
  Color(0xFFFFFFFF),
  Color(0xFF000000),
  Color(0xFF9E9E9E),
  Color(0xFF424242),
  Color(0xFFE53935),
  Color(0xFFFB8C00),
  Color(0xFFFDD835),
  Color(0xFF43A047),
  Color(0xFFA5D6A7),
  Color(0xFF00897B),
  Color(0xFF1E88E5),
  Color(0xFF1A237E),
  Color(0xFF8E24AA),
  Color(0xFFEC407A),
  Color(0xFF6D4C41),
  Color(0xFFFFF8E1),
];

class ColorSwatches extends StatelessWidget {
  const ColorSwatches({
    super.key,
    required this.selected,
    required this.onChanged,
    this.colors = paletteColors,
  });

  final Color selected;
  final ValueChanged<Color> onChanged;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final color in colors)
          GestureDetector(
            onTap: () => onChanged(color),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: color == selected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white24,
                  width: color == selected ? 3 : 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class SheetSection extends StatelessWidget {
  const SheetSection({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.1,
                  color: Colors.white60,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class LabeledSlider extends StatelessWidget {
  const LabeledSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.valueLabel,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  /// Text shown at the right. Defaults to the rounded value.
  final String? valueLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(label, style: const TextStyle(fontSize: 14)),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max).toDouble(),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 52,
          child: Text(
            valueLabel ?? value.round().toString(),
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
        ),
      ],
    );
  }
}
