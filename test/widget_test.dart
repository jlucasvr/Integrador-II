import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:apoio_app/main.dart';
import 'package:apoio_app/data.dart';

void main() {
  testWidgets('buscar água e abrir detalhes no celular', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ApoioApp(repository: MockPointRepository()));
    final search = find.text('Buscar pontos de atendimento');
    await tester.ensureVisible(search);
    await tester.tap(search);
    await tester.pumpAndSettle();
    expect(find.text('Centro de Apoio Central'), findsOneWidget);
    final details = find.text('Ver detalhes do ponto').first;
    await tester.ensureVisible(details);
    await tester.tap(details);
    await tester.pumpAndSettle();
    expect(find.text('Ponto de atendimento'), findsOneWidget);
    expect(find.text('Endereço e atendimento'), findsOneWidget);
  });
}
