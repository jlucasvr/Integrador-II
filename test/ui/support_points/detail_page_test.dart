import 'package:apoio_app/data/models/resource.dart';
import 'package:apoio_app/data/models/support_point.dart';
import 'package:apoio_app/ui/core/theme/wireframe_theme.dart';
import 'package:apoio_app/ui/support_points/formatters/resource_availability.dart';
import 'package:apoio_app/ui/support_points/views/detail_page.dart';
import 'package:apoio_app/ui/support_points/widgets/point_actions.dart';
import 'package:apoio_app/ui/support_points/widgets/resource_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const point = SupportPoint(
  id: 'test',
  name: 'Organização do bairro',
  institution: 'Associação local',
  address: 'Rua das Flores, 10',
  contact: '(11) 99999-1111',
  hours: 'Segunda a sexta, das 8h às 18h',
  updatedAt: '17/11/2026',
  distanceKm: null,
  resources: [
    Resource('Água', 'Água', 'garrafas', true, true, 120),
    Resource('Alimentos', 'Alimentos', 'cestas', true, false, 25),
    Resource('Higiene', 'Higiene', 'kits', true, true, 5),
    Resource('Cobertor', 'Abrigo', 'unidades', false, true, 0),
    Resource('Roupas', 'Roupas', 'unidades', true, true, null),
  ],
);

void main() {
  test('faixas respeitam limites e não estimam quantidade privada', () {
    Resource item(int? quantity, {bool available = true}) =>
        Resource('Água', 'Água', 'garrafas', available, true, quantity);
    for (final entry in {
      0: ResourceAvailability.empty,
      1: ResourceAvailability.low,
      10: ResourceAvailability.low,
      11: ResourceAvailability.medium,
      50: ResourceAvailability.medium,
      51: ResourceAvailability.high,
    }.entries) {
      expect(ResourceAvailability.of(item(entry.key)), entry.value);
    }
    expect(
      ResourceAvailability.of(item(null)),
      ResourceAvailability.undisclosed,
    );
    expect(
      ResourceAvailability.of(item(120, available: false)),
      ResourceAvailability.unavailable,
    );
  });

  test('Maps usa endereço como alternativa quando não há coordenadas', () {
    expect(
      mapsDirections(point).queryParameters['destination'],
      'Rua das Flores, 10',
    );
  });

  for (final width in [320.0, 620.0]) {
    testWidgets('detalhes acessíveis e sem números exatos em $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: wireframeTheme(),
          home: const DetailPage(point: point),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Boa disponibilidade'), findsOneWidget);
      expect(find.text('Estoque moderado'), findsOneWidget);
      expect(find.text('Poucas unidades'), findsOneWidget);
      expect(find.text('Sem estoque'), findsNWidgets(2));
      expect(find.text('Baixa'), findsOneWidget);
      expect(find.text('Disponível · confirme no contato'), findsOneWidget);
      expect(find.textContaining('120'), findsNothing);
      expect(find.textContaining('25'), findsNothing);
      expect(find.text('Receber'), findsNothing);
      expect(find.text('Doar'), findsNothing);
      expect(find.byType(ResourceCard), findsNWidgets(5));
      final foodCard = find.ancestor(
        of: find.text('Alimentos'),
        matching: find.byType(ResourceCard),
      );
      expect(
        find.descendant(of: foodCard, matching: find.text('Estoque moderado')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: foodCard,
          matching: find.text('Não recebe doação deste item'),
        ),
        findsOneWidget,
      );
      final blanketCard = find.ancestor(
        of: find.text('Cobertor'),
        matching: find.byType(ResourceCard),
      );
      expect(
        find.descendant(of: blanketCard, matching: find.text('Sem estoque')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: blanketCard,
          matching: find.text('Aceita doação deste item'),
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Abrir no mapa'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.text('Localização no mapa ainda não informada.'),
        findsOneWidget,
      );
      await Scrollable.ensureVisible(
        tester.element(find.text('Contato')),
        alignment: .35,
      );
      await tester.tap(find.text('Contato'));
      await tester.pumpAndSettle();
      expect(find.text('(11) 99999-1111'), findsOneWidget);
      expect(find.text('Ligar para a organização'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('lista única mantém estoque e doações visíveis juntos', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: wireframeTheme(),
        home: const DetailPage(point: point),
      ),
    );
    expect(find.text('Itens e doações'), findsOneWidget);
    expect(find.text('Alimentos'), findsOneWidget);
    expect(find.text('Sem estoque'), findsNWidgets(2));
    expect(find.text('Aceita doação deste item'), findsNWidgets(4));
    expect(find.text('Não recebe doação deste item'), findsOneWidget);
  });
}
