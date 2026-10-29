
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_canvas/app.dart';
import 'package:pixel_canvas/model/canvas_document.dart';
import 'package:pixel_canvas/model/canvas_background.dart';
import 'package:pixel_canvas/ui/editor_page.dart';
import 'package:pixel_canvas/ui/theme.dart';

/// Presses the start page's "Create canvas" button. The button sits below the
/// fold of the scrollable start page, and a tap on an off-screen widget misses
/// silently in tests, so the callback is invoked directly. The route transition
/// is allowed to finish before the editor is inspected.
Future<void> createCanvas(WidgetTester tester) async {
  final button = tester.widget<FilledButton>(
    find.widgetWithText(FilledButton, 'Create canvas'),
  );
  button.onPressed!();
  await tester.pumpAndSettle();
}

/// Walks the main user path through real screens. Uses explicit pumps rather
/// than pumpAndSettle, because a focused text field keeps a cursor animating.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('create a canvas, add text, edit it, and open layers', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    await tester.pumpWidget(const PixelCanvasApp());
    await tester.pump();

    // Start screen: default preset and white background, then create.
    expect(find.text('Create canvas'), findsOneWidget);
    await createCanvas(tester);
    expect(find.byType(EditorPage), findsOneWidget);

    // Toolbar "Text" adds a layer and opens the text sheet.
    await tester.tap(find.text('Text'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Hello QA');
    await tester.pump();

    // Dismiss the sheet by tapping the barrier above it.
    await tester.tapAt(const Offset(10, 10));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Hello QA'), findsWidgets);
    expect(tester.takeException(), isNull);

    // Toolbar "Layers" lists the layer by its generated name.
    await tester.tap(find.text('Layers'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Text 1'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('canvas size sheet resizes the document', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    await tester.pumpWidget(const PixelCanvasApp());
    await tester.pump();

    await createCanvas(tester);

    await tester.tap(find.text('Canvas'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('16:9'), findsOneWidget);

    await tester.ensureVisible(find.text('16:9'));
    await tester.pump();
    await tester.tap(find.text('16:9'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('1920 × 1080 px'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editor opens directly and adds text', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: EditorPage(
          document: const CanvasDocument(
            width: 1080,
            height: 1080,
            background: SolidBackground(Color(0xFFFFFFFF)),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Text'), findsOneWidget);

    await tester.tap(find.text('Text'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Direct edit');
    await tester.pump();
    await tester.tapAt(const Offset(10, 10));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Direct edit'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
