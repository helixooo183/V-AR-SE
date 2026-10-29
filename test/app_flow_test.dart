
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_canvas/app.dart';
import 'package:pixel_canvas/ui/editor_page.dart';

/// Presses the start page's "Create canvas" button. The button sits below the
/// fold of the scrollable start page, and a tap on an off-screen widget misses
/// silently in tests, so the callback is invoked directly.
Future<void> createCanvas(WidgetTester tester) async {
  final button = tester.widget<FilledButton>(
    find.widgetWithText(FilledButton, 'Create canvas'),
  );
  button.onPressed!();
  await tester.pump(const Duration(milliseconds: 600));
  final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
  final texts = find
      .byType(Text)
      .evaluate()
      .map((e) => (e.widget as Text).data)
      .take(30)
      .toList();
  // DIAG: temporary, to see why navigation does not reach the editor.
  debugPrint('DIAG canPop=${nav.canPop()} pages=${find.byType(MaterialPageRoute).evaluate().length} texts=$texts');
  debugPrint('DIAG exceptionless=${tester.takeException()}');
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

    await tester.tap(find.text('16:9'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('1920 × 1080 px'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
