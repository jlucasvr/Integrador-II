import 'package:apoio_app/data/models/resource.dart';
import 'package:apoio_app/data/models/search_hit.dart';
import 'package:apoio_app/data/models/search_intent.dart';
import 'package:apoio_app/data/models/search_query.dart';
import 'package:apoio_app/ui/search/view_models/result_resources.dart';
import 'package:apoio_app/data/models/support_point.dart';
import 'package:apoio_app/ui/core/theme/wireframe_theme.dart';
import 'package:apoio_app/ui/search/widgets/hit_tile.dart';
import 'package:apoio_app/ui/search/widgets/result_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

SearchHit hit(
  Resource resource, {
  double? distance = 1.2,
  String region = 'Centro',
}) => SearchHit(
  SupportPoint(
    id: 'central',
    name: 'Centro de Apoio do Bairro',
    institution: 'Associação local',
    address: 'Rua Exemplo, 10',
    region: region,
    hours: '8h às 18h',
    updatedAt: '13/10/2026, às 9h',
    distanceKm: distance,
    resources: [resource],
  ),
  resource,
  false,
);

Widget card(
  SearchHit hit, {
  SearchIntent intent = SearchIntent.help,
  VoidCallback? onOpen,
  List<Resource>? resources,
}) => MaterialApp(
  theme: wireframeTheme(),
  home: Scaffold(
    body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: HitTile(
          hit: hit,
          intent: intent,
          resources: resources,
          onOpen: onOpen ?? () {},
        ),
      ),
    ),
  ),
);

void main() {
  for (final city in [
    'São Vicente',
    'São José dos Campos e região metropolitana',
  ]) {
    testWidgets('cidade usa o espaço restante antes de truncar: $city', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        card(
          hit(
            const Resource('Água', 'Água', 'garrafas', true, true, 120),
            region: city,
          ),
        ),
      );
      final label = find.text(city);
      final paragraph = tester.renderObject<RenderParagraph>(label);
      final badge = find.ancestor(
        of: label,
        matching: find.byType(ResultBadge),
      );
      expect(tester.getSize(badge).width, greaterThan(155));
      if (city == 'São Vicente') {
        expect(paragraph.didExceedMaxLines, isFalse);
      } else {
        expect(paragraph.didExceedMaxLines, isTrue);
        expect(
          tester.getRect(badge).right,
          closeTo(tester.getRect(find.byType(FilledButton)).right, 1),
        );
      }
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'itens correspondentes ficam juntos com divisor e sem itens alheios à busca',
    (tester) async {
      const water = Resource(
        'Água potável',
        'Água',
        'garrafas',
        true,
        true,
        120,
      );
      const mineral = Resource(
        'Água mineral',
        'Água',
        'garrafas',
        true,
        true,
        5,
      );
      const food = Resource(
        'Cesta básica',
        'Alimentos',
        'cestas',
        true,
        true,
        25,
      );
      final result = SearchHit(
        const SupportPoint(
          id: 'multi',
          name: 'Ponto',
          institution: 'Instituição',
          address: 'Rua',
          hours: '8h',
          updatedAt: '18/11/2026',
          distanceKm: 1,
          resources: [water, mineral, food],
        ),
        water,
        false,
      );
      final items = resultResources(
        result,
        const SearchQuery('Água', SearchIntent.help),
      );
      expect(items, [water, mineral]);
      await tester.pumpWidget(card(result, resources: items));
      expect(find.text('Água potável'), findsOneWidget);
      expect(find.text('Água mineral'), findsOneWidget);
      expect(find.text('Cesta básica'), findsNothing);
      expect(find.byType(Divider), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'estoque ao lado do item, distância clara e atualização só com data',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var opened = false;
      await tester.pumpWidget(
        card(
          hit(
            const Resource(
              'Água potável',
              'Água',
              'garrafas',
              true,
              true,
              120,
              updatedAt: '14/10/2026, às 10h',
            ),
          ),
          onOpen: () => opened = true,
        ),
      );
      expect(find.text('Estoque bom'), findsOneWidget);
      expect(tester.getSize(find.byType(FilledButton)).height, 48);
      expect(find.text('1,2 km'), findsOneWidget);
      expect(
        tester.getRect(find.text('1,2 km')).top,
        tester.getRect(find.text('Centro')).top,
      );
      expect(find.text('14/10/2026'), findsOneWidget);
      expect(find.textContaining('10h'), findsNothing);
      expect(find.textContaining('120'), findsNothing);
      expect(
        tester.getRect(find.text('Água potável')).right,
        lessThan(tester.getRect(find.byType(LinearProgressIndicator)).left),
      );
      await tester.tap(find.text('Ver detalhes do ponto'));
      expect(opened, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  for (final available in [true, false]) {
    testWidgets('quantidade privada usa status com cor: $available', (
      tester,
    ) async {
      await tester.pumpWidget(
        card(
          hit(
            Resource('Água', 'Água', 'garrafas', available, true, null),
            distance: null,
          ),
        ),
      );
      expect(find.byType(LinearProgressIndicator), findsNothing);
      final status = find.text(available ? 'Disponível' : 'Indisponível');
      expect(status, findsOneWidget);
      expect(
        tester.widget<Text>(status).style!.color,
        available ? const Color(0xff23804b) : const Color(0xffc3473b),
      );
      expect(find.textContaining('km de você'), findsNothing);
      expect(find.text('Sem estoque'), findsNothing);
    });
  }

  testWidgets(
    'saldo zero aceita doação sem confundir com baixa disponibilidade',
    (tester) async {
      await tester.pumpWidget(
        card(
          hit(const Resource('Água', 'Água', 'garrafas', false, true, 0)),
          intent: SearchIntent.donate,
        ),
      );
      expect(find.text('Sem estoque'), findsOneWidget);
      expect(find.text('Poucas unidades'), findsNothing);
      expect(find.text('Aceita sua doação'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        0,
      );
    },
  );

  testWidgets('saldo pequeno fica vermelho e se distingue de estoque vazio', (
    tester,
  ) async {
    await tester.pumpWidget(
      card(hit(const Resource('Água', 'Água', 'garrafas', true, true, 5))),
    );
    expect(find.text('Poucas unidades'), findsOneWidget);
    expect(find.text('Sem estoque'), findsNothing);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .color,
      const Color(0xffc3473b),
    );
  });

  testWidgets('320 px e texto ampliado mantêm informações e botão acessíveis', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      card(
        hit(
          const Resource(
            'Kit de higiene para a família',
            'Higiene',
            'kits',
            true,
            true,
            5,
          ),
          distance: .04,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('0,04 km'), findsOneWidget);
    await tester.ensureVisible(find.text('Ver detalhes do ponto'));
    expect(find.text('Ver detalhes do ponto').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
