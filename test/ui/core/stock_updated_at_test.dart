import 'package:apoio_app/ui/core/widgets/stock_updated_at.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

void main() {
  testWidgets('tooltip de atualização responde apenas ao hover na data', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: StockUpdatedAt(value: '18/11/2026')),
        ),
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byIcon(Icons.update_rounded)));
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.text('Última atualização do estoque: 18/11/2026'),
      findsNothing,
    );
    await mouse.moveTo(tester.getCenter(find.text('18/11/2026')));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(
      find.text('Última atualização do estoque: 18/11/2026'),
      findsOneWidget,
    );
  });
  test('data de atualização aceita formato público e ISO sem horário', () {
    expect(stockUpdateDate('14/10/2026, às 10h'), '14/10/2026');
    expect(stockUpdateDate('1/2/2026'), '01/02/2026');
    expect(stockUpdateDate('2026-11-18T12:30:00'), '18/11/2026');
    expect(stockUpdateDate('Não informado'), 'Data não informada');
    expect(stockUpdateDate('31/02/2026, às 10h'), 'Data não informada');
  });
}
