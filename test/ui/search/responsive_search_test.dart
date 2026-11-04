import 'package:apoio_app/app/app.dart';
import 'package:apoio_app/data/repositories/mock_point_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../fixtures/location_service_fixture.dart';

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(740, 360)
  ]) {
    testWidgets('busca e filtros sem sobreposição em $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ApoioApp(
          repository: MockPointRepository(),
          locationService: FakeLocationService()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final submit = find.byKey(const ValueKey('search-submit'));
      final field = find.byKey(const ValueKey('search-term'));
      await tester.ensureVisible(find.text('Medicamentos'));
      await tester.tap(find.text('Medicamentos'));
      expect(
          tester.widget<TextFormField>(field).controller!.text, 'Medicamentos');
      tester.view.viewInsets =
          FakeViewPadding(bottom: size.height > 500 ? 250 : 120);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.getRect(submit).bottom,
          lessThanOrEqualTo(size.height - tester.view.viewInsets.bottom));
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      await tester.enterText(field, 'Água potável');
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final filter = find.text('Filtros');
      final title = find.text('Água potável').first;
      expect(tester.getRect(filter).bottom,
          lessThanOrEqualTo(tester.getRect(title).top));
      await tester.tap(filter);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Somente disponíveis'));
      await tester.tap(find.text('Somente disponíveis'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
