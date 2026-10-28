import 'package:flutter/material.dart';

/// Dark, editor-first theme. The canvas sits on a neutral dark surface so
/// the design's own colours read correctly.
ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF6C5CE7),
    brightness: Brightness.dark,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFF161618),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E21),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF1E1E21),
      showDragHandle: true,
    ),
    sliderTheme: const SliderThemeData(showValueIndicator: ShowValueIndicator.never),
  );
}
