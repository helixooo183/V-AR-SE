import 'package:flutter/material.dart';

import '../../state/editor_controller.dart';

/// Starter set of emoji stickers. Replace or extend with a PNG library later.
const List<String> stickerGlyphs = <String>[
  '😀', '😂', '😍', '🥰', '😎', '🤩', '🥳', '😇',
  '🔥', '✨', '⭐', '💫', '❤️', '💖', '💯', '👑',
  '🌈', '🌸', '🌺', '🌻', '🍀', '🌙', '☀️', '⚡',
  '🎉', '🎈', '🎁', '🏆', '🎵', '🎶', '📸', '💎',
  '👍', '🙌', '👀', '💬', '🐶', '🐱', '🦋', '🍕',
  '🍓', '☕', '🚀', '🛸', '🌊', '🏝️', '🎨', '✏️',
];

Future<void> showStickerSheet(
  BuildContext context,
  EditorController controller,
) async {
  controller.beginBatch();
  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * 0.6,
        child: GridView.count(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          crossAxisCount: 6,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            for (final glyph in stickerGlyphs)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  controller.addSticker(glyph);
                  Navigator.of(sheetContext).pop();
                },
                child: Center(
                  child: Text(glyph, style: const TextStyle(fontSize: 34)),
                ),
              ),
          ],
        ),
      ),
    );
  } finally {
    controller.endBatch();
  }
}
