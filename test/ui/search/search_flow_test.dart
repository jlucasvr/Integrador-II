import 'dart:async';

import 'package:apoio_app/app/app.dart';
import 'package:apoio_app/core/errors/location_failure.dart';
import 'package:apoio_app/data/models/geo_coordinates.dart';
import 'package:apoio_app/data/models/search_hit.dart';
import 'package:apoio_app/data/models/search_query.dart';
import 'package:apoio_app/data/repositories/mock_point_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/location_service_fixture.dart';

class RecordingPointRepository extends MockPointRepository {
  final List<SearchQuery> queries = [];

  @override
  Future<List<SearchHit>> search(SearchQuery query) {
    queries.add(query);
    return super.search(query);
  }
}

Future<void> submit(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('search-submit')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('busca fixa preserva termo e coordenadas em novas consultas',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = RecordingPointRepository();
    final location = FakeLocationService();
    await tester.pumpWidget(
        ApoioApp(repository: repository, locationService: location));
    expect(find.text('Bairro ou cidade'), findsNothing);
    expect(tester.getSize(find.byTooltip('Gestão')).height, 48);
    expect(find.byTooltip('Voltar'), findsNothing);
    final button = find.byKey(const ValueKey('search-submit'));
    final homePosition = tester.getRect(button);
    expect(homePosition.bottom, greaterThan(800));
    final locationControl = find.byKey(const ValueKey('location-control'));
    expect(find.byKey(const ValueKey('search-coordinates')), findsNothing);
    final expandedWidth = tester.getSize(locationControl).width;
    expect(expandedWidth, greaterThan(48));
    final locationPosition = tester.getTopLeft(locationControl);
    await tester.tap(locationControl);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    expect(tester.getSize(locationControl).width,
        allOf(greaterThan(48), lessThan(expandedWidth)));
    expect(tester.getTopLeft(locationControl), locationPosition);
    await tester.pumpAndSettle();
    expect(tester.getSize(locationControl), const Size(48, 48));
    expect(tester.getTopLeft(locationControl), locationPosition);
    expect(find.text('Usar minha localização'), findsNothing);
    await submit(tester);
    expect(location.calls, 1);
    expect(repository.queries.single.coordinates.latitude, -23.55);
    expect(find.text('-23.550000, -46.630000'), findsOneWidget);
    expect(find.textContaining('Latitude:'), findsNothing);
    expect(find.textContaining('Longitude:'), findsNothing);
    expect(find.text('Mapa'), findsNothing);
    expect(tester.getSize(find.byTooltip('Voltar')).height, 48);
    final field = find.byKey(const ValueKey('search-term'));
    expect(
        tester.widget<TextFormField>(field).controller!.text, 'Água potável');
    expect(find.descendant(of: field, matching: button), findsOneWidget);
    final dockPosition = tester.getRect(button);
    final coordinatePosition =
        tester.getRect(find.byKey(const ValueKey('search-coordinates')));
    expect(coordinatePosition.bottom,
        lessThanOrEqualTo(tester.getRect(field).top));
    await tester.drag(
        find.byType(SingleChildScrollView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(tester.getRect(button), dockPosition);

    // The keyboard must leave the search button visible above its top edge.
    tester.view.viewInsets = const FakeViewPadding(bottom: 250);
    await tester.pumpAndSettle();
    expect(tester.getRect(button).bottom, lessThanOrEqualTo(594));
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();

    await tester.enterText(field, 'Cobertor');
    await submit(tester);
    expect(repository.queries.last.term, 'Cobertor');
    expect(repository.queries.last.coordinates.longitude, -46.63);
    expect(location.calls, 1);
    expect(find.text('Ponto Comunitário Norte'), findsOneWidget);
    expect(tester.widget<TextFormField>(field).controller!.text, 'Cobertor');
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(field).controller!.text, 'Cobertor');
  });

  testWidgets('permissão negada mantém o termo e permite tentar novamente',
      (tester) async {
    final repository = RecordingPointRepository();
    final location = FakeLocationService()
      ..failure = const LocationFailure('Permita o acesso à localização.');
    await tester.pumpWidget(
        ApoioApp(repository: repository, locationService: location));
    await submit(tester);
    expect(repository.queries, isEmpty);
    expect(find.text('Permita o acesso à localização.'), findsOneWidget);
    expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('search-term')))
            .controller!
            .text,
        'Água potável');
    location.failure = null;
    await submit(tester);
    expect(location.calls, 2);
    expect(find.text('Centro de Apoio Central'), findsOneWidget);
  });

  testWidgets('captura em andamento bloqueia buscas duplicadas',
      (tester) async {
    final repository = RecordingPointRepository();
    final location = FakeLocationService()
      ..pending = Completer<GeoCoordinates>();
    await tester.pumpWidget(
        ApoioApp(repository: repository, locationService: location));
    await tester.tap(find.byKey(const ValueKey('search-submit')));
    await tester.pump();
    expect(find.text('Obtendo localização…'), findsOneWidget);
    expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('search-submit')))
            .onPressed,
        isNull);
    expect(repository.queries, isEmpty);
    location.pending!.complete(const GeoCoordinates(-23.55, -46.63));
    await tester.pumpAndSettle();
    expect(location.calls, 1);
    expect(repository.queries, hasLength(1));
  });

  testWidgets('filtros e recuperação de erro mantêm a busca fixa',
      (tester) async {
    final repository = RecordingPointRepository()..failNextRequest = true;
    await tester.pumpWidget(ApoioApp(
        repository: repository, locationService: FakeLocationService()));
    await submit(tester);
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(find.byKey(const ValueKey('search-submit')), findsOneWidget);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    final heading = find.text('Água potável').first;
    final headingPosition = tester.getTopLeft(heading);
    await tester.tap(find.text('Filtros'));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(heading), headingPosition);
    expect(find.text('3 resultados para'), findsOneWidget);
    await Scrollable.ensureVisible(
        tester.element(find.text('Somente disponíveis')),
        alignment: .35);
    await tester.tap(find.text('Somente disponíveis'));
    await tester.pumpAndSettle();
    expect(find.text('Escola de Apoio Sul'), findsNothing);
    expect(find.text('2 resultados para'), findsOneWidget);
    expect(repository.queries, hasLength(2));
    expect(find.text('-23.550000, -46.630000'), findsOneWidget);
  });
}
