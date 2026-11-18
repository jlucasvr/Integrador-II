import 'package:apoio_app/data/models/resource.dart';
import 'package:apoio_app/data/models/search_hit.dart';
import 'package:apoio_app/data/models/search_intent.dart';
import 'package:apoio_app/data/models/search_query.dart';
import 'package:apoio_app/data/models/support_point.dart';
import 'package:apoio_app/data/repositories/point_repository.dart';
import 'package:apoio_app/data/repositories/mock_point_repository.dart';
import 'package:apoio_app/app/app.dart';
import 'package:apoio_app/ui/management/views/management_page.dart';
import 'package:apoio_app/ui/core/theme/wireframe_theme.dart';
import 'package:apoio_app/ui/search/views/results_page.dart';
import 'package:apoio_app/ui/search/widgets/filter_pill.dart';
import 'package:apoio_app/ui/search/widgets/hit_tile.dart';
import 'package:apoio_app/ui/support_points/views/detail_page.dart';
import 'package:apoio_app/ui/support_points/widgets/resource_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../fixtures/location_service_fixture.dart';
import '../../fixtures/management_api_fixture.dart';

SupportPoint organization(int index) => SupportPoint(
  id: 'organization-$index',
  name: index == 1
      ? 'Associação de Apoio às Famílias do Bairro'
      : 'Organização $index',
  institution: 'Rede de apoio comunitário',
  address: 'Rua das Flores, 100 — Centro',
  region: 'Rio Verde - GO',
  hours: 'Segunda a sexta, das 8h às 17h',
  updatedAt: '18/11/2026',
  distanceKm: index + .4,
  resources: List.generate(
    index + 1,
    (item) => Resource(
      'Alimento ${item + 1}',
      'Alimentos',
      'pacotes',
      true,
      true,
      10 + item * 20,
    ),
  ),
);

class _Repository implements PointRepository {
  @override
  bool get isDemo => true;
  @override
  Future<List<SearchHit>> search(SearchQuery query) async =>
      List.generate(6, (index) {
        final point = organization(index);
        return SearchHit(point, point.resources.first, false);
      });
}

Widget results({double textScale = 1}) => MaterialApp(
  theme: wireframeTheme(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: ResultsPage(
    repository: _Repository(),
    query: const SearchQuery('Alimentos', SearchIntent.help),
    locationService: FakeLocationService(),
  ),
);

void main() {
  testWidgets('início e login alinham navegação ao conteúdo de 1200px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ApoioApp(
        repository: MockPointRepository(),
        locationService: FakeLocationService(),
      ),
    );
    await tester.pumpAndSettle();
    final progress = tester.getRect(find.byType(LinearProgressIndicator));
    expect(progress.left, closeTo(220, .1));
    expect(progress.right, closeTo(1380, .1));
    expect(tester.getRect(find.byTooltip('Gestão')).right, closeTo(1380, .1));
    final choice = tester.getRect(
      find.widgetWithText(FilledButton, 'Preciso de ajuda'),
    );
    expect(choice.width, lessThan(620));
    expect(choice.center.dx, closeTo(800, .1));
    final fixture = ApiFixture();
    addTearDown(fixture.api.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: wireframeTheme(),
        home: ManagementPage(api: fixture.api),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byTooltip('Voltar')).left, closeTo(220, .1));
    expect(
      tester.getRect(find.byKey(const ValueKey('login-email'))).left,
      closeTo(224, .1),
    );
    expect(tester.takeException(), isNull);
  });
  for (final entry in {
    390.0: 1,
    800.0: 2,
    1024.0: 2,
    1280.0: 3,
    1600.0: 3,
  }.entries) {
    testWidgets(
      'resultados em ${entry.value} colunas a ${entry.key}px sem cortar conteúdo',
      (tester) async {
        tester.view.physicalSize = Size(entry.key, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(results());
        await tester.pumpAndSettle();
        final cards = find.byType(HitTile);
        expect(cards, findsNWidgets(6));
        final first = tester.getRect(cards.first);
        for (var index = 1; index < entry.value; index++) {
          final next = tester.getRect(cards.at(index));
          expect(next.top, closeTo(first.top, .1));
          expect(next.left, greaterThan(first.left));
          expect(next.height, closeTo(first.height, .1));
          final firstButton = tester.getRect(
            find.descendant(
              of: cards.first,
              matching: find.byType(FilledButton),
            ),
          );
          final nextButton = tester.getRect(
            find.descendant(
              of: cards.at(index),
              matching: find.byType(FilledButton),
            ),
          );
          expect(nextButton.bottom, closeTo(firstButton.bottom, .1));
        }
        expect(
          tester.getRect(cards.at(entry.value)).top,
          greaterThanOrEqualTo(first.bottom - .1),
        );
        final filter = tester.getRect(find.byType(FilterPill));
        final rightmost = tester.getRect(cards.at(entry.value - 1));
        expect(filter.right, closeTo(rightmost.right, .1));
        if (entry.key >= 1024) {
          expect(
            tester.getRect(find.byTooltip('Gestão')).right,
            closeTo(rightmost.right, .1),
          );
        }
        if (entry.key == 1600) {
          expect(first.left, closeTo(220, .1));
          expect(rightmost.right, closeTo(1380, .1));
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('grade se reorganiza ao redimensionar e abrir uma organização', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(results());
    await tester.pumpAndSettle();
    final cards = find.byType(HitTile);
    expect(
      tester.getRect(cards.at(2)).top,
      greaterThan(tester.getRect(cards.first).top),
    );
    tester.view.physicalSize = const Size(1440, 1000);
    await tester.pumpAndSettle();
    expect(
      tester.getRect(cards.at(2)).top,
      closeTo(tester.getRect(cards.first).top, .1),
    );
    final button = find.descendant(
      of: cards.first,
      matching: find.byType(FilledButton),
    );
    await Scrollable.ensureVisible(tester.element(button), alignment: .35);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('organization-columns')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [390.0, 800.0, 1024.0, 1440.0]) {
    testWidgets(
      'organização mantém hierarquia e acesso aos itens em ${width}px',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: wireframeTheme(),
            home: DetailPage(point: organization(5)),
          ),
        );
        await tester.pumpAndSettle();
        final items = tester.getRect(find.text('Itens e doações'));
        final location = tester.getRect(find.text('Onde fica'));
        if (width >= 1024) {
          expect(location.left, greaterThan(items.right));
          final hours = tester.getRect(find.text('Quando ir'));
          final contact = tester.getRect(find.text('Entre em contato'));
          expect(hours.top, lessThan(items.top));
          expect(contact.top, greaterThan(hours.bottom));
          expect(location.top, greaterThan(contact.bottom));
          expect(find.text('Ver itens'), findsNothing);
          expect(find.text('Como chegar'), findsNothing);
          expect(find.text('Contato'), findsNothing);
        } else {
          expect(location.top, greaterThan(items.bottom));
          expect(
            find.byKey(const ValueKey('organization-columns')),
            findsNothing,
          );
        }
        expect(find.byType(ResourceCard), findsNWidgets(6));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('texto ampliado reduz colunas e mantém conteúdo acessível', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(results(textScale: 2));
    await tester.pumpAndSettle();
    final cards = find.byType(HitTile);
    expect(
      tester.getRect(cards.at(1)).top,
      greaterThan(tester.getRect(cards.first).bottom),
    );
    expect(tester.takeException(), isNull);
  });
}
