
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_canvas/model/canvas_background.dart';
import 'package:pixel_canvas/model/canvas_document.dart';
import 'package:pixel_canvas/model/text_style_spec.dart';
import 'package:pixel_canvas/state/editor_controller.dart';
import 'package:pixel_canvas/ui/canvas_stage.dart';

const double _stageWidth = 360;
const double _stageHeight = 720;

EditorController _controllerWith() => EditorController(
      document: const CanvasDocument(
        width: 1080,
        height: 1080,
        background: SolidBackground(Color(0xFFFFFFFF)),
      ),
    );

Future<void> _pumpStage(WidgetTester tester, EditorController controller) async {
  await tester.binding.setSurfaceSize(const Size(400, 800));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: _stageWidth,
          height: _stageHeight,
          child: CanvasStage(
            controller: controller,
            boundaryKey: GlobalKey(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// On-screen rectangle of the canvas (the document drawn to fit the stage).
Rect _canvasRect(WidgetTester tester) {
  final finder = find.descendant(
    of: find.byType(CanvasStage),
    matching: find.byType(GestureDetector),
  );
  return tester.getRect(finder.first);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tapping a layer selects it', (tester) async {
    final controller = _controllerWith();
    final id = controller.addText(text: 'Hello');
    controller.select(null);
    await _pumpStage(tester, controller);

    final rect = _canvasRect(tester);
    final scale = rect.width / controller.document.width;
    final centre = rect.topLeft + controller.document.findLayer(id)!.transform.position * scale;

    await tester.tapAt(centre);
    // A tap waits out the double-tap window before it is recognised.
    await tester.pump(const Duration(milliseconds: 400));

    expect(controller.selectedId, id);
  });

  testWidgets('dragging moves a text layer and is one undo step', (tester) async {
    final controller = _controllerWith();
    final id = controller.addText(text: 'Drag me');
    await _pumpStage(tester, controller);

    final rect = _canvasRect(tester);
    final scale = rect.width / controller.document.width;
    final start = controller.document.findLayer(id)!.transform.position;
    final startScreen = rect.topLeft + start * scale;

    await tester.tapAt(startScreen);
    await tester.pump(const Duration(milliseconds: 400));
    expect(controller.selectedId, id);

    await tester.dragFrom(startScreen, const Offset(120, 60));
    await tester.pump(const Duration(milliseconds: 400));

    final moved = controller.document.findLayer(id)!.transform.position;
    // Touch slop eats the first few pixels, so assert a generous lower bound.
    expect(moved.dx, greaterThan(start.dx + 60 / scale));
    expect(moved.dy, greaterThan(start.dy + 30 / scale));

    controller.undo();
    expect(controller.document.findLayer(id)!.transform.position, start);
  });

  testWidgets('pinching scales the selected layer', (tester) async {
    final controller = _controllerWith();
    final id = controller.addText(text: 'Pinch');
    await _pumpStage(tester, controller);

    final rect = _canvasRect(tester);
    final scale = rect.width / controller.document.width;
    final centre = rect.topLeft +
        controller.document.findLayer(id)!.transform.position * scale;

    await tester.tapAt(centre);
    await tester.pump(const Duration(milliseconds: 400));
    final before = controller.document.findLayer(id)!.transform.scale;

    final f1 = await tester.startGesture(centre + const Offset(-20, 0), pointer: 1);
    final f2 = await tester.startGesture(centre + const Offset(20, 0), pointer: 2);
    await tester.pump();
    for (var i = 0; i < 10; i++) {
      await f1.moveBy(const Offset(-12, 0));
      await f2.moveBy(const Offset(12, 0));
      await tester.pump();
    }
    await f1.up();
    await f2.up();
    await tester.pump(const Duration(milliseconds: 400));

    final after = controller.document.findLayer(id)!.transform.scale;
    expect(after, greaterThan(before * 1.5));
    expect(after, lessThan(before * 20));
  });

  testWidgets('two-finger rotation turns the layer clockwise', (tester) async {
    final controller = _controllerWith();
    final id = controller.addText(text: 'Turn');
    await _pumpStage(tester, controller);

    final rect = _canvasRect(tester);
    final scale = rect.width / controller.document.width;
    final centre = rect.topLeft +
        controller.document.findLayer(id)!.transform.position * scale;

    await tester.tapAt(centre);
    await tester.pump(const Duration(milliseconds: 400));
    expect(controller.document.findLayer(id)!.transform.rotation, 0);

    // Two fingers, 40px apart on the x-axis, rotating a quarter turn
    // clockwise on screen (the second finger moves from +x towards +y).
    const radius = 20.0;
    Offset fingerAt(double angle, double side) {
      final x = side * radius * math.cos(angle);
      final y = side * radius * math.sin(angle);
      return centre + Offset(x, y);
    }

    final f1 = await tester.startGesture(fingerAt(0, -1), pointer: 1);
    final f2 = await tester.startGesture(fingerAt(0, 1), pointer: 2);
    await tester.pump();
    for (var step = 1; step <= 10; step++) {
      final angle = (math.pi / 2) * step / 10;
      await f1.moveTo(fingerAt(angle, -1));
      await f2.moveTo(fingerAt(angle, 1));
      await tester.pump();
    }
    await f1.up();
    await f2.up();
    await tester.pump(const Duration(milliseconds: 400));

    final rotation = controller.document.findLayer(id)!.transform.rotation;
    expect(rotation, greaterThan(1.0));
    expect(rotation, lessThan(1.9));
  });

  testWidgets('a full mix of layer types renders without errors', (tester) async {
    final controller = EditorController(
      document: const CanvasDocument(
        width: 1080,
        height: 1920,
        background: TransparentBackground(),
      ),
    );
    controller.addText(
      text: 'Styled',
      style: const TextStyleSpec(
        fontId: 'pacifico',
        fontSize: 120,
        hasStroke: true,
        hasShadow: true,
        hasBackground: true,
        bold: true,
        italic: true,
        uppercase: true,
        letterSpacing: 4,
        lineHeight: 1.4,
      ),
    );
    controller.addSticker('🔥');
    controller.addImage(
      path: '/does/not/exist.png',
      naturalSize: const Size(800, 600),
    );
    await _pumpStage(tester, controller);
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(controller.document.layers, hasLength(3));
  });

  testWidgets('a gradient background renders without errors', (tester) async {
    final controller = EditorController(
      document: const CanvasDocument(
        width: 1080,
        height: 1080,
        background: GradientBackground(
          start: Color(0xFF6C5CE7),
          end: Color(0xFFFD79A8),
          angleDegrees: 45,
        ),
      ),
    );
    controller.addText(text: 'On a gradient');
    await _pumpStage(tester, controller);
    expect(tester.takeException(), isNull);
  });
}
