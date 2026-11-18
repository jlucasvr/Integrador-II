import 'package:apoio_app/data/models/search_intent.dart';
import 'package:apoio_app/ui/core/theme/wireframe_theme.dart';
import 'package:apoio_app/ui/search/widgets/home_search_options.dart';
import 'package:apoio_app/ui/search/widgets/category_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('categorias têm o mesmo intervalo em x e y no $platform', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          theme: wireframeTheme().copyWith(
            platform: platform,
            materialTapTargetSize: MaterialTapTargetSize.padded,
            visualDensity: VisualDensity.standard,
          ),
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: CategoryPicker(onSelected: (value) => selected = value),
              ),
            ),
          ),
        ),
      );
      final buttons = find.byType(OutlinedButton);
      final surfaces = List.generate(
        buttons.evaluate().length,
        (index) => tester.getRect(
          find.descendant(
            of: buttons.at(index),
            matching: find.byType(Material),
          ),
        ),
      );
      final first = surfaces.first;
      final second = surfaces[1];
      final nextRow = surfaces.firstWhere((rect) => rect.top > first.top + 1);
      expect(first.height, 32);
      expect(tester.getSize(buttons.first).height, 32);
      expect(second.left - first.right, closeTo(12, .1));
      expect(nextRow.top - first.bottom, closeTo(12, .1));
      await tester.tap(find.text('Alimentos'));
      expect(selected, 'Alimentos');
      await tester.tap(find.text('Medicamentos'));
      expect(selected, 'Medicamentos');
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('categorias crescem com o texto ampliado sem cortar rótulos', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: wireframeTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: CategoryPicker(onSelected: (_) {}),
            ),
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(OutlinedButton).first).height,
      greaterThan(32),
    );
    expect(find.text('Medicamentos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('seleção tem superfície mais espessa que as categorias', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: wireframeTheme(),
        home: Scaffold(
          body: HomeSearchOptions(
            intent: SearchIntent.help,
            onIntentChanged: (_) {},
            onCategorySelected: (_) {},
          ),
        ),
      ),
    );
    // Measure the painted button surfaces, rather than padded touch targets.
    final categorySurface = find.descendant(
      of: find.widgetWithText(OutlinedButton, 'Água'),
      matching: find.byType(Material),
    );
    final selector = find.byKey(const ValueKey('intent-selector'));
    expect(tester.getSize(categorySurface).height, 32);
    expect(tester.getSize(selector).height, 48);
    expect(tester.takeException(), isNull);
  });
}
