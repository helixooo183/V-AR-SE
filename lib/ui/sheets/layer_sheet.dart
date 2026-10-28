import 'package:flutter/material.dart';

import '../../model/editor_layer.dart';
import '../../state/editor_controller.dart';

Future<void> showLayerSheet(BuildContext context, EditorController controller) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => LayerSheet(controller: controller),
  );
}

/// Lists layers top-to-bottom, the way they look on the canvas.
///
/// Internally layers are stored bottom-to-top, so indices are mirrored when
/// reordering.
class LayerSheet extends StatelessWidget {
  const LayerSheet({super.key, required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final layers = controller.document.layers;
        final displayed = layers.reversed.toList(growable: false);
        final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

        return SizedBox(
          height: maxHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Row(
                  children: [
                    Text(
                      'Layers (${layers.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    const Text(
                      'Drag ≡ to reorder',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: displayed.isEmpty
                    ? const Center(
                        child: Text(
                          'No layers yet.\nUse the toolbar to add text, images or stickers.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : ReorderableListView.builder(
                        buildDefaultDragHandles: false,
                        itemCount: displayed.length,
                        // newIndex is already adjusted for the removed item.
                        onReorderItem: (oldIndex, newIndex) {
                          final n = displayed.length;
                          controller.moveLayer(n - 1 - oldIndex, n - 1 - newIndex);
                        },
                        itemBuilder: (context, index) {
                          final layer = displayed[index];
                          return _LayerTile(
                            key: ValueKey(layer.id),
                            index: index,
                            layer: layer,
                            selected: layer.id == controller.selectedId,
                            controller: controller,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LayerTile extends StatelessWidget {
  const _LayerTile({
    super.key,
    required this.index,
    required this.layer,
    required this.selected,
    required this.controller,
  });

  final int index;
  final EditorLayer layer;
  final bool selected;
  final EditorController controller;

  IconData get _typeIcon => switch (layer) {
        TextLayer() => Icons.text_fields,
        ImageLayer() => Icons.image_outlined,
        StickerLayer() => Icons.emoji_emotions_outlined,
      };

  String get _typeLabel => switch (layer) {
        TextLayer() => 'Text',
        ImageLayer() => 'Image',
        StickerLayer() => 'Sticker',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dimmed = !layer.visible;
    final subtitle = [
      _typeLabel,
      if (layer.locked) 'locked',
      if (!layer.visible) 'hidden',
    ].join(' · ');

    return ListTile(
      selected: selected,
      selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.12),
      leading: CircleAvatar(
        backgroundColor: Colors.white10,
        child: Icon(_typeIcon,
            size: 20, color: dimmed ? Colors.white30 : Colors.white),
      ),
      title: Text(
        layer.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: dimmed ? Colors.white38 : null),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      onTap: () {
        controller.select(layer.id);
        Navigator.of(context).pop();
      },
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: layer.visible ? 'Hide' : 'Show',
            icon: Icon(layer.visible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined),
            onPressed: () => controller.toggleVisibility(layer.id),
          ),
          IconButton(
            tooltip: layer.locked ? 'Unlock' : 'Lock',
            icon: Icon(layer.locked
                ? Icons.lock_outline
                : Icons.lock_open_outlined),
            onPressed: () => controller.toggleLock(layer.id),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => controller.deleteLayer(layer.id),
          ),
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(Icons.drag_handle),
            ),
          ),
        ],
      ),
    );
  }
}
