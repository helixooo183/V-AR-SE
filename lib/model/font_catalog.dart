import 'package:flutter/foundation.dart' show immutable;

/// A font the user can pick for text layers.
@immutable
class FontOption {
  const FontOption({required this.id, required this.label, this.family});

  /// Stable key stored in projects.
  final String id;

  /// Name shown in the picker.
  final String label;

  /// Family name declared in pubspec.yaml. `null` means the platform default.
  final String? family;
}

/// All fonts shipped with the app. Every family here is bundled as an asset
/// (SIL Open Font License, see assets/fonts/licenses), so it renders offline.
abstract final class FontCatalog {
  static const List<FontOption> all = <FontOption>[
    FontOption(id: 'inter', label: 'Inter', family: 'Inter'),
    FontOption(id: 'system', label: 'System', family: null),
    FontOption(id: 'playfair', label: 'Playfair', family: 'PlayfairDisplay'),
    FontOption(id: 'oswald', label: 'Oswald', family: 'Oswald'),
    FontOption(id: 'anton', label: 'Anton', family: 'Anton'),
    FontOption(id: 'bebas', label: 'Bebas Neue', family: 'BebasNeue'),
    FontOption(id: 'bangers', label: 'Bangers', family: 'Bangers'),
    FontOption(id: 'righteous', label: 'Righteous', family: 'Righteous'),
    FontOption(id: 'marker', label: 'Marker', family: 'PermanentMarker'),
    FontOption(id: 'dancing', label: 'Dancing Script', family: 'DancingScript'),
    FontOption(id: 'lobster', label: 'Lobster', family: 'Lobster'),
    FontOption(id: 'pacifico', label: 'Pacifico', family: 'Pacifico'),
  ];

  /// Falls back to the first font for unknown ids (e.g. from an older file).
  static FontOption byId(String id) {
    for (final option in all) {
      if (option.id == id) return option;
    }
    return all.first;
  }
}
