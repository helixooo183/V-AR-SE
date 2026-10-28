
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_canvas/app.dart';
import 'package:pixel_canvas/ui/editor_page.dart';

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
    // The start page is a scrollable list; the button starts off-screen.
    await tester.ensureVisible(find.text('Create canvas'));
    await tester.pump();
    await tester.tap(find.text('Create canvas'));
    await tester.pump(const Duration(milliseconds: 600));
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

    // The start page is a scrollable list; the button starts off-screen.
    await tester.ensureVisible(find.text('Create canvas'));
    await tester.pump();
    await tester.tap(find.text('Create canvas'));
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.text('Canvas'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('16:9'), findsOneWidget);

    await tester.tap(find.text('16:9'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('1920 × 1080 px'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
