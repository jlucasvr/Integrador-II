import 'package:apoio_app/app/app.dart';
import 'package:apoio_app/data/repositories/mock_point_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/location_service_fixture.dart';

void main() {
  testWidgets('buscar água e abrir detalhes no celular', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ApoioApp(
        repository: MockPointRepository(),
        locationService: FakeLocationService()));
    final search = find.byTooltip('Buscar pontos de atendimento');
    await tester.ensureVisible(search);
    await tester.tap(search);
    await tester.pumpAndSettle();
    expect(find.text('Centro de Apoio Central'), findsOneWidget);
    expect(find.text('120 garrafas de 1 L disponíveis'), findsNothing);
    final details = find.text('Ver detalhes do ponto').first;
    await Scrollable.ensureVisible(tester.element(details), alignment: .35);
    await tester.tap(details);
    await tester.pumpAndSettle();
    expect(find.text('Ponto de atendimento'), findsOneWidget);
    expect(find.text('Endereço e atendimento'), findsOneWidget);
    expect(find.text('120 garrafas de 1 L disponíveis'), findsOneWidget);
  });
}
