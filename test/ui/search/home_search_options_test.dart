import 'package:apoio_app/data/models/search_intent.dart';
import 'package:apoio_app/ui/core/theme/wireframe_theme.dart';
import 'package:apoio_app/ui/search/widgets/home_search_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('seleção tem superfície mais espessa que as categorias',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        theme: wireframeTheme(),
        home: Scaffold(
            body: HomeSearchOptions(
                intent: SearchIntent.help,
                onIntentChanged: (_) {},
                onCategorySelected: (_) {}))));
    // Measure the painted button surfaces, rather than padded touch targets.
    final categorySurface = find.descendant(
        of: find.widgetWithText(OutlinedButton, 'Água'),
        matching: find.byType(Material));
    final selector = find.byKey(const ValueKey('intent-selector'));
    expect(tester.getSize(categorySurface).height, 32);
    expect(tester.getSize(selector).height, 48);
    expect(tester.takeException(), isNull);
  });
}
