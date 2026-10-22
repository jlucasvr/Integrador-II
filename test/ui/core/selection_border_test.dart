import 'dart:ui' as ui;

import 'package:apoio_app/ui/core/theme/selection_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final direction in TextDirection.values) {
    for (final selectedFirst in [true, false]) {
      test('borda acompanha a metade selecionada: $direction / $selectedFirst',
          () async {
        const light = Color(0xffd0d0d0);
        const dark = Color(0xff292929);
        final recorder = ui.PictureRecorder();
        final border = SelectionBorder(
            selectedFirst: selectedFirst,
            selectedColor: dark,
            side: const BorderSide(color: light));
        // SegmentedButton copies the shape before painting its outer border.
        border.copyWith(side: const BorderSide(color: light)).paint(
            Canvas(recorder), const Rect.fromLTWH(0, 0, 100, 48),
            textDirection: direction);
        final picture = recorder.endRecording();
        final image = await picture.toImage(100, 48);
        final data =
            (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
        Color pixel(int x) => Color.fromARGB(
            data.getUint8(x * 4 + 3),
            data.getUint8(x * 4),
            data.getUint8(x * 4 + 1),
            data.getUint8(x * 4 + 2));
        final selectedOnLeft =
            selectedFirst != (direction == TextDirection.rtl);
        expect(pixel(35), selectedOnLeft ? dark : light);
        expect(pixel(65), selectedOnLeft ? light : dark);
        image.dispose();
        picture.dispose();
      });
    }
  }
}
