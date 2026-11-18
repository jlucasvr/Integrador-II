import 'package:apoio_app/ui/search/widgets/filter_pill.dart';
import '../../helpers/search_steps.dart';
import 'package:apoio_app/app/app.dart';
import 'package:apoio_app/data/repositories/mock_point_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../fixtures/location_service_fixture.dart';

void main() {
  void expectSearchButtonInsets(WidgetTester tester) {
    final field = tester.getRect(find.byKey(const ValueKey('search-term')));
    final button = tester.getRect(find.byKey(const ValueKey('search-submit')));
    expect(button.size, const Size(48, 48));
    expect(button.top - field.top, closeTo(field.bottom - button.bottom, 1));
    expect(button.top - field.top, closeTo(field.right - button.right, 1));
  }

  setUp(() {
    final dispatcher =
        TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher;
    dispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
    addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
  });
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(740, 360),
  ]) {
    testWidgets('busca e filtros sem sobreposição em $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ApoioApp(
          repository: MockPointRepository(),
          locationService: FakeLocationService(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Demonstração · dados fictícios'), findsOneWidget);
      expect(find.byKey(const ValueKey('location-control')), findsNothing);
      await tapSearchControl(tester, find.text('Preciso de ajuda'));
      await tapSearchControl(tester, find.text('Medicamentos'));
      final field = find.byKey(const ValueKey('search-term'));
      expectSearchButtonInsets(tester);
      expect(
        tester.widget<TextFormField>(field).controller!.text,
        'Medicamentos',
      );
      await tester.enterText(field, 'Água potável');
      await tapSearchControl(
        tester,
        find.byKey(const ValueKey('search-submit')),
      );
      await tapSearchControl(
        tester,
        find.byKey(const ValueKey('wizard-locate')),
      );
      await tapSearchControl(
        tester,
        find.byKey(const ValueKey('search-submit')),
      );
      expect(tester.takeException(), isNull);
      final filter = find.text('Filtros');
      expectSearchButtonInsets(tester);
      expect(
        tester.getRect(find.text('3 resultados para')).top,
        closeTo(tester.getRect(find.byType(FilterPill)).top, .1),
      );
      await tester.tap(filter);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Distância máxima'), findsNothing);
      await tester.ensureVisible(find.text('Somente disponíveis'));
      await tester.tap(find.text('Somente disponíveis'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
