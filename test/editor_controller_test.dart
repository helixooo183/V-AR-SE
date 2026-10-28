import 'dart:ui' show Color, Offset, Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_canvas/model/canvas_background.dart';
import 'package:pixel_canvas/model/canvas_document.dart';
import 'package:pixel_canvas/model/editor_layer.dart';
import 'package:pixel_canvas/state/editor_controller.dart';

CanvasDocument _blankDocument() => const CanvasDocument(
      width: 1080,
      height: 1080,
      background: SolidBackground(Color(0xFFFFFFFF)),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('history', () {
    test('adding a text layer is undoable and redoable', () {
      final c = EditorController(document: _blankDocument());
      expect(c.canUndo, isFalse);

      c.addText(text: 'Hello');
      expect(c.document.layers, hasLength(1));
      expect(c.canUndo, isTrue);

      c.undo();
      expect(c.document.layers, isEmpty);
      expect(c.canRedo, isTrue);

      c.redo();
      expect(c.document.layers, hasLength(1));
      expect((c.document.layers.single as TextLayer).text, 'Hello');
    });

    test('a batch collapses many changes into one undo step', () {
      final c = EditorController(document: _blankDocument());
      final id = c.addImage(
        path: '/tmp/a.png',
        naturalSize: const Size(400, 300),
      );
      c.beginBatch();
      for (var i = 0; i < 25; i++) {
        c.setLayerTransform(
          id,
          LayerTransform(position: Offset(i * 10.0, 5), scale: 1 + i * 0.01),
        );
      }
      c.endBatch();

      final movedTo = c.document.findLayer(id)!.transform.position;
      expect(movedTo, const Offset(240, 5));

      c.undo();
      expect(c.document.findLayer(id)!.transform.position, isNot(movedTo));
      // The undo should land on the state before the batch, not mid-drag.
      expect(
        c.document.findLayer(id)!.transform.position,
        const Offset(540, 540),
      );
    });

    test('an empty batch records no history', () {
      final c = EditorController(document: _blankDocument());
      c.addText();
      final undoBefore = c.canUndo;
      c.beginBatch();
      c.endBatch();
      expect(c.canUndo, undoBefore);
      c.undo();
      expect(c.document.layers, isEmpty);
    });

    test('a new edit after undo clears the redo stack', () {
      final c = EditorController(document: _blankDocument());
      c.addText();
      c.undo();
      expect(c.canRedo, isTrue);
      c.addSticker('⭐');
      expect(c.canRedo, isFalse);
    });

    test('history is capped', () {
      final c = EditorController(document: _blankDocument());
      for (var i = 0; i < EditorController.historyLimit + 20; i++) {
        c.setBackground(SolidBackground(Color(0xFF000000 + i)));
      }
      var undos = 0;
      while (c.canUndo) {
        c.undo();
        undos++;
      }
      expect(undos, EditorController.historyLimit);
    });
  });

  group('layer ordering', () {
    test('new layers are added on top and selected', () {
      final c = EditorController(document: _blankDocument());
      final a = c.addText(text: 'A');
      final b = c.addSticker('⭐');
      expect(c.document.layers.map((l) => l.id).toList(), [a, b]);
      expect(c.selectedId, b);
    });

    test('moveLayer reorders bottom-to-top indices', () {
      final c = EditorController(document: _blankDocument());
      final a = c.addText(text: 'A');
      final b = c.addText(text: 'B');
      final d = c.addText(text: 'C');

      c.moveLayer(2, 0); // C to the bottom
      expect(c.document.layers.map((l) => l.id).toList(), [d, a, b]);
    });

    test('stackLayer moves one step and stops at the edges', () {
      final c = EditorController(document: _blankDocument());
      final a = c.addText(text: 'A');
      final b = c.addText(text: 'B');

      c.stackLayer(a, 1);
      expect(c.document.layers.map((l) => l.id).toList(), [b, a]);

      c.stackLayer(a, 1); // already on top, no-op
      expect(c.document.layers.map((l) => l.id).toList(), [b, a]);
    });

    test('duplicate sits just above the original and is selected', () {
      final c = EditorController(document: _blankDocument());
      final a = c.addText(text: 'A');
      c.addText(text: 'B');
      c.duplicateLayer(a);

      // Original stays at index 0, the copy goes right above it, then B.
      final ids = c.document.layers.map((l) => l.id).toList();
      expect(ids, hasLength(3));
      expect(ids[0], a);
      expect(ids[1], isNot(a));
      expect(c.selectedId, ids[1]);
      expect(c.document.layers[1].name, endsWith('copy'));
    });
  });

  group('editing', () {
    test('deleting the selected layer clears the selection', () {
      final c = EditorController(document: _blankDocument());
      final id = c.addText();
      expect(c.selectedId, id);
      c.deleteLayer(id);
      expect(c.document.layers, isEmpty);
      expect(c.selectedId, isNull);
    });

    test('hidden and locked layers cannot be hit', () {
      final c = EditorController(document: _blankDocument());
      final id = c.addImage(path: 'x', naturalSize: const Size(200, 200));
      final centre = c.document.findLayer(id)!.transform.position;

      expect(c.layerAt(centre)?.id, id);

      c.toggleVisibility(id);
      expect(c.layerAt(centre), isNull);
      c.toggleVisibility(id);

      c.toggleLock(id);
      expect(c.layerAt(centre), isNull);
      expect(c.document.findLayer(id)!.locked, isTrue);
    });

    test('a tap goes through a locked layer to the one underneath', () {
      final c = EditorController(document: _blankDocument());
      final under = c.addImage(path: 'a', naturalSize: const Size(200, 200));
      final over = c.addImage(path: 'b', naturalSize: const Size(200, 200));
      final centre = c.document.findLayer(over)!.transform.position;
      c.toggleLock(over);
      expect(c.layerAt(centre)?.id, under);
    });

    test('resizing the canvas scales positions proportionally', () {
      final c = EditorController(document: _blankDocument());
      final id = c.addText(text: 'A');
      c.resizeCanvas(2160, 1080);

      expect(c.document.width, 2160);
      expect(c.document.height, 1080);
      final pos = c.document.findLayer(id)!.transform.position;
      expect(pos, const Offset(1080, 540));
    });

    test('resizing clamps to the supported range', () {
      final c = EditorController(document: _blankDocument());
      c.resizeCanvas(10, 100000);
      expect(c.document.width, CanvasDocument.minSide);
      expect(c.document.height, CanvasDocument.maxSide);
    });

    test('opacity is clamped to 0..1', () {
      final c = EditorController(document: _blankDocument());
      final id = c.addText();
      c.setLayerOpacity(id, 3);
      expect(c.document.findLayer(id)!.opacity, 1);
      c.setLayerOpacity(id, -1);
      expect(c.document.findLayer(id)!.opacity, 0);
    });

    test('updateText changes only the text content', () {
      final c = EditorController(document: _blankDocument());
      final id = c.addText(text: 'Before');
      final before = c.document.findLayer(id)! as TextLayer;
      c.updateText(id, text: 'After');
      final after = c.document.findLayer(id)! as TextLayer;
      expect(after.text, 'After');
      expect(after.style.fontSize, before.style.fontSize);
      expect(after.boxWidth, before.boxWidth);
    });
  });
}
