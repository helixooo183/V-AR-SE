import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_canvas/engine/hit_test.dart';
import 'package:pixel_canvas/engine/text_metrics.dart';
import 'package:pixel_canvas/model/editor_layer.dart';
import 'package:pixel_canvas/model/text_style_spec.dart';

ImageLayer _image({
  required String id,
  required Offset position,
  double rotation = 0,
  double scale = 1,
  Size size = const Size(200, 100),
}) {
  return ImageLayer(
    id: id,
    name: id,
    transform: LayerTransform(
      position: position,
      rotation: rotation,
      scale: scale,
    ),
    opacity: 1,
    visible: true,
    locked: false,
    path: 'unused.png',
    size: size,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('layerContainsPoint', () {
    test('matches the untransformed rectangle', () {
      final layer = _image(id: 'a', position: const Offset(500, 500));
      expect(layerContainsPoint(layer, const Offset(590, 500)), isTrue);
      expect(layerContainsPoint(layer, const Offset(610, 500)), isFalse);
      expect(layerContainsPoint(layer, const Offset(500, 549)), isTrue);
      expect(layerContainsPoint(layer, const Offset(500, 551)), isFalse);
    });

    test('follows a 90 degree clockwise rotation', () {
      // Rotated, the 200-wide image becomes 100 wide and 200 tall.
      final layer = _image(
        id: 'a',
        position: const Offset(500, 500),
        rotation: math.pi / 2,
      );
      expect(layerContainsPoint(layer, const Offset(500, 590)), isTrue);
      expect(layerContainsPoint(layer, const Offset(590, 500)), isFalse);
      expect(layerContainsPoint(layer, const Offset(549, 500)), isTrue);
    });

    test('follows scale', () {
      final layer = _image(
        id: 'a',
        position: const Offset(500, 500),
        scale: 2,
      );
      // Half-width is 100 * 2 = 200 now.
      expect(layerContainsPoint(layer, const Offset(690, 500)), isTrue);
      expect(layerContainsPoint(layer, const Offset(710, 500)), isFalse);
    });

    test('combined rotation and scale', () {
      final layer = _image(
        id: 'a',
        position: const Offset(0, 0),
        rotation: math.pi / 4,
        scale: 0.5,
      );
      // A point 40 units along the rotated x-axis is inside (half-width 50).
      final along = Offset(40 * math.cos(math.pi / 4), 40 * math.sin(math.pi / 4));
      expect(layerContainsPoint(layer, along), isTrue);
      final far = Offset(80 * math.cos(math.pi / 4), 80 * math.sin(math.pi / 4));
      expect(layerContainsPoint(layer, far), isFalse);
    });
  });

  group('topLayerAt', () {
    test('returns the front-most layer that contains the point', () {
      final back = _image(id: 'back', position: const Offset(100, 100));
      final front = _image(id: 'front', position: const Offset(120, 100));
      final hit = topLayerAt([back, front], const Offset(110, 100));
      expect(hit?.id, 'front');
    });

    test('skips hidden layers', () {
      final back = _image(id: 'back', position: const Offset(100, 100));
      const front = ImageLayer(
        id: 'front',
        name: 'front',
        transform: LayerTransform(position: Offset(100, 100)),
        opacity: 1,
        visible: false,
        locked: false,
        path: 'x',
        size: const Size(200, 100),
      );
      expect(topLayerAt([back, front], const Offset(100, 100))?.id, 'back');
    });
  });

  group('text measurement', () {
    TextLayer textLayer({required String text, double boxWidth = 400}) {
      return TextLayer(
        id: 't',
        name: 't',
        transform: const LayerTransform(),
        opacity: 1,
        visible: true,
        locked: false,
        text: text,
        style: const TextStyleSpec(fontSize: 60),
        boxWidth: boxWidth,
      );
    }

    test('width includes padding around the box', () {
      final layer = textLayer(text: 'Hi');
      final size = measureTextLayer(layer);
      expect(size.width, closeTo(400 + 2 * layerPaddingFor(60), 0.001));
      expect(size.height, greaterThan(0));
    });

    test('empty text still has a height so it can be selected', () {
      final size = measureTextLayer(textLayer(text: ''));
      expect(size.height, greaterThan(2 * layerPaddingFor(60)));
    });

    test('more lines mean a taller layer', () {
      final one = measureTextLayer(textLayer(text: 'one'));
      final many = measureTextLayer(
        textLayer(text: 'one two three four five six seven eight nine ten'),
      );
      expect(many.height, greaterThan(one.height));
    });
  });
}
