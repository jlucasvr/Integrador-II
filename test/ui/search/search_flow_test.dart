import 'package:apoio_app/ui/search/widgets/category_picker.dart';
import 'package:apoio_app/ui/core/widgets/action_glow.dart';
import 'package:apoio_app/ui/core/widgets/navigation_surface.dart';
import 'dart:async';
import 'package:apoio_app/app/app.dart';
import 'package:apoio_app/core/errors/location_failure.dart';
import 'package:apoio_app/data/models/geo_coordinates.dart';
import 'package:apoio_app/data/models/search_hit.dart';
import 'package:apoio_app/data/models/search_query.dart';
import 'package:apoio_app/data/models/search_intent.dart';
import 'package:apoio_app/data/repositories/mock_point_repository.dart';
import 'package:apoio_app/ui/search/widgets/location_pill.dart';
import 'package:apoio_app/ui/search/widgets/filter_pill.dart';
import 'package:apoio_app/ui/search/widgets/result_filters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../fixtures/location_service_fixture.dart';
import '../../helpers/search_steps.dart';

class RecordingPointRepository extends MockPointRepository {
  @override
  bool get isDemo => false;
  final List<SearchQuery> queries = [];
  @override
  Future<List<SearchHit>> search(SearchQuery query) {
    queries.add(query);
    return super.search(query);
  }
}

void main() {
  setUp(() {
    final dispatcher =
        TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher;
    dispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
    addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
  });
  for (final granted in [true, false]) {
    testWidgets('captura ao entrar na localização só com permissão: $granted', (
      tester,
    ) async {
      final location = FakeLocationService()..permissionGranted = granted;
      await tester.pumpWidget(
        ApoioApp(
          repository: RecordingPointRepository(),
          locationService: location,
        ),
      );
      expect(location.calls, 0);
      await tapSearchControl(tester, find.text('Preciso de ajuda'));
      expect(location.calls, 0);
      await chooseSearchItem(tester);
      expect(find.text('Onde buscar?'), findsOneWidget);
      expect(location.calls, granted ? 1 : 0);
      expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('search-submit')))
            .onPressed,
        granted ? isNotNull : isNull,
      );
    });
  }
  testWidgets('permissão tardia não captura depois de sair da etapa', (
    tester,
  ) async {
    final permission = Completer<bool>();
    final location = FakeLocationService()..permissionPending = permission;
    await tester.pumpWidget(
      ApoioApp(
        repository: RecordingPointRepository(),
        locationService: location,
      ),
    );
    await chooseSearchItem(tester);
    await tapSearchControl(tester, find.byTooltip('Voltar'));
    permission.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('O que você procura?'), findsOneWidget);
    expect(location.calls, 0);
    expect(tester.takeException(), isNull);
  });
  testWidgets('falha na captura automática permite tentar pelo botão', (
    tester,
  ) async {
    final location = FakeLocationService()
      ..permissionGranted = true
      ..failure = const LocationFailure('Ative a localização do dispositivo.');
    await tester.pumpWidget(
      ApoioApp(
        repository: RecordingPointRepository(),
        locationService: location,
      ),
    );
    await chooseSearchItem(tester);
    expect(location.calls, 1);
    expect(find.text('Ative a localização do dispositivo.'), findsOneWidget);
    location.failure = null;
    await tapSearchControl(tester, find.byKey(const ValueKey('wizard-locate')));
    expect(location.calls, 2);
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('search-submit')))
          .onPressed,
      isNotNull,
    );
  });
  testWidgets('barra guia as etapas e glow termina após capturar localização', (
    tester,
  ) async {
    final location = FakeLocationService();
    await tester.pumpWidget(
      ApoioApp(
        repository: RecordingPointRepository(),
        locationService: location,
      ),
    );
    expect(find.byKey(const ValueKey('wizard-next')), findsNothing);
    await tapSearchControl(tester, find.text('Preciso de ajuda'));
    final submit = find.byKey(const ValueKey('search-submit'));
    expect(tester.widget<IconButton>(submit).onPressed, isNull);
    expect(tester.widget<IconButton>(submit).icon, isA<Icon>());
    expect(
      (tester.widget<IconButton>(submit).icon as Icon).icon,
      Icons.arrow_forward_rounded,
    );
    expect(find.byType(LocationPill), findsNothing);
    expect(tester.widget<Scaffold>(find.byType(Scaffold)).extendBody, isTrue);
    final dockSurface = find.byWidgetPredicate(
      (widget) => widget is NavigationSurface && widget.bottom,
    );
    final searchOnlyHeight = tester.getSize(dockSurface).height;
    expect(
      tester.getRect(find.byKey(const ValueKey('search-term'))).top -
          tester.getRect(dockSurface).top,
      closeTo(16, .1),
    );
    for (final element in find.byType(NavigationSurface).evaluate()) {
      final decoration = find
          .descendant(
            of: find.byWidget(element.widget),
            matching: find.byType(DecoratedBox),
          )
          .first;
      final gradient =
          (tester.widget<DecoratedBox>(decoration).decoration as BoxDecoration)
                  .gradient!
              as LinearGradient;
      expect(gradient.colors.length, 2);
      expect(gradient.stops, isNull);
    }
    expect(find.text('Continuar'), findsNothing);
    await tapSearchControl(tester, find.text('Água'));
    expect(tester.widget<IconButton>(submit).onPressed, isNotNull);
    expect(
      tester
          .widget<ActionGlow>(
            find.ancestor(of: submit, matching: find.byType(ActionGlow)).first,
          )
          .active,
      isTrue,
    );
    expect(find.byKey(const ValueKey('wizard-next')), findsNothing);
    await tapSearchControl(tester, submit);
    expect(find.text('Onde buscar?'), findsOneWidget);
    expect(
      tester.getSize(dockSurface).height - searchOnlyHeight,
      closeTo(0, .1),
    );
    final locationGap =
        tester.getRect(find.byKey(const ValueKey('search-term'))).top -
        tester.getRect(find.byKey(const ValueKey('location-control'))).bottom;
    expect(locationGap, closeTo(16, .1));
    expect(
      tester.getRect(find.byKey(const ValueKey('search-term'))).top -
          tester.getRect(dockSurface).top,
      closeTo(16, .1),
    );
    expect(
      tester.getRect(dockSurface).top,
      closeTo(tester.getRect(find.byType(LocationPill)).bottom, .1),
    );
    final searchBoundsBeforeLocation = tester.getRect(
      find.byKey(const ValueKey('search-term')),
    );
    expect(
      tester
          .widget<Icon>(find.byKey(const ValueKey('location-step-symbol')))
          .icon,
      Icons.near_me_outlined,
    );
    expect((tester.widget<IconButton>(submit).icon as Icon).icon, Icons.search);
    final glow = find.descendant(
      of: find.byType(LocationPill),
      matching: find.byType(ActionGlow),
    );
    expect(tester.widget<ActionGlow>(glow).active, isTrue);
    expect(find.byKey(const ValueKey('wizard-results')), findsNothing);
    expect(tester.widget<IconButton>(submit).onPressed, isNull);
    await tapSearchControl(tester, find.byKey(const ValueKey('wizard-locate')));
    final coordinates = find.byKey(const ValueKey('search-coordinates'));
    expect(
      tester.getRect(coordinates).top,
      greaterThan(searchBoundsBeforeLocation.bottom),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('search-term'))),
      searchBoundsBeforeLocation,
    );
    expect(tester.widget<Text>(coordinates).style!.fontSize, 11);
    expect(tester.widget<ActionGlow>(glow).active, isFalse);
    expect(find.byKey(const ValueKey('wizard-results')), findsNothing);
    expect(
      tester
          .widget<Icon>(find.byKey(const ValueKey('location-step-symbol')))
          .icon,
      Icons.near_me_outlined,
    );
    expect(tester.widget<IconButton>(submit).onPressed, isNotNull);
    await tapSearchControl(tester, submit);
    expect(
      tester.widget<LocationPill>(find.byType(LocationPill)).highlight,
      isFalse,
    );
    expect(location.calls, 1);
    expect(
      tester.getRect(find.byType(FilterPill)).top -
          tester.getRect(find.byTooltip('Gestão')).bottom,
      closeTo(locationGap, .1),
    );
  });
  testWidgets('etapas preservam escolhas e só pedem GPS por ação explícita', (
    tester,
  ) async {
    final repository = RecordingPointRepository();
    final location = FakeLocationService();
    await tester.pumpWidget(
      ApoioApp(repository: repository, locationService: location),
    );
    expect(find.text('Como podemos ajudar?'), findsOneWidget);
    expect(find.byKey(const ValueKey('search-term')), findsNothing);
    await tapSearchControl(tester, find.text('Quero ajudar'));
    await chooseSearchItem(tester, term: 'Cobertor');
    expect(location.calls, 0);
    expect(repository.queries, isEmpty);
    expect(find.byKey(const ValueKey('wizard-results')), findsNothing);
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('search-submit')))
          .onPressed,
      isNull,
    );
    expect(find.text('Buscar sem localização'), findsNothing);
    await tapSearchControl(tester, find.byKey(const ValueKey('wizard-locate')));
    await tapSearchControl(tester, find.byKey(const ValueKey('search-submit')));
    expect(repository.queries.single.intent, SearchIntent.donate);
    expect(repository.queries.single.coordinates!.latitude, -23.55);
    await tester.enterText(find.byKey(const ValueKey('search-term')), 'Água');
    await tapSearchControl(tester, find.byKey(const ValueKey('search-submit')));
    await tapSearchControl(tester, find.byTooltip('Voltar'));
    expect(find.text('Encontre um lugar para doar'), findsOneWidget);
    expect(find.text('Água'), findsNWidgets(2));
    expect(find.text('Quero ajudar'), findsOneWidget);
    expect(
      tester.widget<LocationPill>(find.byType(LocationPill)).captured,
      isTrue,
    );
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(const ValueKey('search-term')),
              matching: find.byType(TextField),
            ),
          )
          .decoration!
          .hintText,
      'Buscar item ou categoria',
    );
    expect(find.text('Alterar escolhas'), findsNothing);
    await tapSearchControl(tester, find.text('Preciso de ajuda'));
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('search-term')))
          .controller!
          .text,
      'Água',
    );
    expect(find.text('Encontre o apoio que você precisa'), findsOneWidget);
    await tapSearchControl(tester, find.text('Higiene'));
    expect(
      tester.widget<CategoryPicker>(find.byType(CategoryPicker)).selected,
      'Higiene',
    );
    expect(
      tester.widget<LocationPill>(find.byType(LocationPill)).captured,
      isTrue,
    );
    await tapSearchControl(tester, find.byKey(const ValueKey('search-submit')));
    expect(repository.queries.last.intent, SearchIntent.help);
    expect(repository.queries.last.term, 'Higiene');
    expect(repository.queries.last.coordinates, isNotNull);
    expect(location.calls, 1);
  });
  testWidgets('sem item não avança e categorias têm ícones e seleção', (
    tester,
  ) async {
    await tester.pumpWidget(
      ApoioApp(
        repository: MockPointRepository(),
        locationService: FakeLocationService(),
      ),
    );
    await tapSearchControl(tester, find.text('Preciso de ajuda'));
    expect(find.byKey(const ValueKey('wizard-next')), findsNothing);
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('search-submit')))
          .onPressed,
      isNull,
    );
    await tapSearchControl(tester, find.text('Higiene'));
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('search-term')))
          .controller!
          .text,
      'Higiene',
    );
    expect(find.byIcon(Icons.sanitizer_outlined), findsOneWidget);
  });
  testWidgets('GPS negado bloqueia resultados e permite nova tentativa', (
    tester,
  ) async {
    final repository = RecordingPointRepository();
    final location = FakeLocationService()
      ..failure = const LocationFailure('Permita o acesso à localização.');
    await tester.pumpWidget(
      ApoioApp(repository: repository, locationService: location),
    );
    await chooseSearchItem(tester);
    await tapSearchControl(tester, find.byKey(const ValueKey('wizard-locate')));
    expect(find.text('Permita o acesso à localização.'), findsOneWidget);
    expect(repository.queries, isEmpty);
    expect(find.byKey(const ValueKey('wizard-results')), findsNothing);
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('search-submit')))
          .onPressed,
      isNull,
    );
    location.failure = null;
    await tapSearchControl(tester, find.byKey(const ValueKey('wizard-locate')));
    await tapSearchControl(tester, find.byKey(const ValueKey('search-submit')));
    expect(location.calls, 2);
    expect(repository.queries, hasLength(1));
  });
  testWidgets('captura pendente bloqueia reenvio e navegação', (tester) async {
    final repository = RecordingPointRepository();
    final location = FakeLocationService()
      ..pending = Completer<GeoCoordinates>();
    await tester.pumpWidget(
      ApoioApp(repository: repository, locationService: location),
    );
    await chooseSearchItem(tester);
    await tester.tap(find.byKey(const ValueKey('wizard-locate')));
    await tester.pump();
    expect(find.text('Obtendo localização…'), findsOneWidget);
    expect(
      tester
          .widget<InkWell>(find.byKey(const ValueKey('location-control')))
          .onTap,
      isNull,
    );
    expect(find.byKey(const ValueKey('wizard-results')), findsNothing);
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('search-submit')))
          .onPressed,
      isNull,
    );
    expect(repository.queries, isEmpty);
    location.pending!.complete(const GeoCoordinates(-23.55, -46.63));
    await tester.pumpAndSettle();
    expect(location.calls, 1);
    await tapSearchControl(tester, find.byKey(const ValueKey('search-submit')));
    expect(repository.queries, hasLength(1));
  });
  testWidgets('filtros e termo são preservados ao voltar para o resumo', (
    tester,
  ) async {
    final repository = RecordingPointRepository();
    await tester.pumpWidget(
      ApoioApp(repository: repository, locationService: FakeLocationService()),
    );
    await openWizardResults(tester);
    await tapSearchControl(tester, find.text('Filtros'));
    await tapSearchControl(tester, find.text('Somente disponíveis'));
    await tapSearchControl(tester, find.text('Aplicar filtros'));
    await tapSearchControl(tester, find.byTooltip('Voltar'));
    expect(find.text('Somente disponíveis'), findsOneWidget);
    await tapSearchControl(tester, find.byKey(const ValueKey('search-submit')));
    expect(repository.queries.last.availableOnly, isTrue);
    expect(repository.queries.last.coordinates, isNotNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets('modal cancela ajustes e aplica distância apenas ao confirmar', (
    tester,
  ) async {
    final repository = RecordingPointRepository();
    await tester.pumpWidget(
      ApoioApp(repository: repository, locationService: FakeLocationService()),
    );
    await openWizardResults(tester);
    final count = repository.queries.length;
    await tapSearchControl(tester, find.text('Filtros'));
    expect(find.byType(Dialog), findsOneWidget);
    final slider = find.byKey(const ValueKey('distance-range'));
    tester.widget<Slider>(slider).onChanged!(25);
    await tester.pump();
    expect(repository.queries.length, count);
    await tapSearchControl(tester, find.text('Cancelar'));
    expect(repository.queries.last.radiusKm, isNull);
    await tapSearchControl(tester, find.text('Filtros'));
    tester.widget<Slider>(slider).onChanged!(25);
    await tester.pump();
    await tapSearchControl(tester, find.text('Aplicar filtros'));
    expect(repository.queries.last.radiusKm, 25);
    await tapSearchControl(tester, find.byTooltip('Voltar'));
    await tapSearchControl(tester, find.text('Voltar ao passo a passo'));
    expect(find.text('Etapa 1 de 3'), findsOneWidget);
    await tapSearchControl(tester, find.text('Preciso de ajuda'));
    expect(
      tester.widget<CategoryPicker>(find.byType(CategoryPicker)).selected,
      isNotEmpty,
    );
    expect(tester.takeException(), isNull);
  });
  test('extremidades do controle de distância significam todas', () {
    expect(ResultFilters.radiusFor(0), isNull);
    expect(ResultFilters.radiusFor(50), isNull);
    expect(ResultFilters.radiusFor(25), 25);
  });
}
