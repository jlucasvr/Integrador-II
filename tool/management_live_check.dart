import 'dart:io';

import 'package:apoio_app/core/errors/management_failure.dart';
import 'package:apoio_app/data/models/geo_coordinates.dart';
import 'package:apoio_app/data/models/movement_type.dart';
import 'package:apoio_app/data/models/municipal_institution.dart';
import 'package:apoio_app/data/models/search_intent.dart';
import 'package:apoio_app/data/models/search_query.dart';
import 'package:apoio_app/data/repositories/api_point_repository.dart';
import 'package:apoio_app/data/repositories/management_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  final url = Platform.environment['APOIO_ISOLATED_API_URL'];
  test(
    'prefeitura consulta, cadastra e registra decisões na API isolada',
    () async {
      final api = ManagementRepository(url!);
      addTearDown(api.dispose);
      await api.login('prefeitura@example.test', 'integration-test-password');
      expect(api.session!.role, 'municipality');
      await expectLater(
        api.points(),
        throwsA(
          isA<ManagementFailure>().having(
            (failure) => failure.status,
            'status',
            403,
          ),
        ),
      );
      await api.createInstitution('Instituição da integração municipal');
      final institution = (await api.municipalInstitutions()).singleWhere(
        (item) => item.name == 'Instituição da integração municipal',
      );
      expect(institution.status, InstitutionStatus.pending);
      for (final status in [
        InstitutionStatus.verified,
        InstitutionStatus.suspended,
        InstitutionStatus.pending,
      ]) {
        await api.verifyInstitution(institution.id, status, 'Decisão de teste');
        final updated = (await api.municipalInstitutions()).singleWhere(
          (item) => item.id == institution.id,
        );
        expect(updated.status, status);
      }
      await api.logout();
      await api.login('gestor@example.test', 'integration-test-password');
      await expectLater(
        api.municipalInstitutions(),
        throwsA(
          isA<ManagementFailure>().having(
            (failure) => failure.status,
            'status',
            403,
          ),
        ),
      );
    },
    skip: url == null ? 'Execute iniciar.ps1 -Action integration.' : false,
  );

  test('gestão atualiza consulta pública na API isolada', () async {
    final api = ManagementRepository(url!), public = ApiPointRepository(url);
    addTearDown(api.dispose);
    addTearDown(public.dispose);
    await api.login('gestor@example.test', 'integration-test-password');
    final institution = (await api.institutions()).single['id'];
    final pointFields = {
      'institution_id': institution,
      'name': 'Ponto do teste de integração',
      'address': 'Rua de teste, 10',
      'region': 'Centro',
      'hours': '8h às 18h',
      'contact': 'Contato de teste',
      'latitude': -23.55,
      'longitude': -46.63,
      'active': true,
    };
    await api.savePoint(pointFields, idempotencyKey: 'live-check-creation');
    await api.savePoint(pointFields, idempotencyKey: 'live-check-creation');
    final created = (await api.points()).singleWhere(
      (point) => point.name == pointFields['name'],
    );
    expect(await api.stock(created.id), isEmpty);
    final detailUrl = Uri.parse('$url/points/${created.id}');
    expect((await http.get(detailUrl)).statusCode, 200);
    await api.savePoint({
      ...pointFields,
      'name': 'Ponto editado',
    }, point: created);
    final edited = (await api.points()).singleWhere((p) => p.id == created.id);
    expect(edited.name, 'Ponto editado');
    expect(edited.version, created.version + 1);

    const withoutLocation = SearchQuery(
      'Água',
      SearchIntent.help,
      availableOnly: true,
    );
    final catalogItem = (await api.catalog(
      edited.id,
    )).singleWhere((item) => item.id == 'water');
    await api.linkStockItem(edited.id, catalogItem.id);
    final firstStock = (await api.stock(edited.id)).single;
    expect(firstStock.quantity, 0);
    expect(firstStock.visible, isFalse);
    expect(firstStock.unit, catalogItem.unit);
    expect(
      (await api.catalog(edited.id)).map((item) => item.id),
      isNot(contains(catalogItem.id)),
    );
    final hiddenDetail = await http.get(detailUrl);
    expect(hiddenDetail.statusCode, 200);
    expect(hiddenDetail.body, isNot(contains(firstStock.id)));

    await api.move(firstStock, MovementType.entry, 7, 'Primeira entrada');
    expect(
      (await public.search(withoutLocation)).map((hit) => hit.point.id),
      isNot(contains(edited.id)),
    );
    final stocked = (await api.stock(edited.id)).single;
    await api.publish(stocked, {
      'visible': true,
      'public_quantity': true,
      'distributable': true,
      'accepts_donation': false,
    });
    final publicHit = (await public.search(
      withoutLocation,
    )).singleWhere((hit) => hit.point.id == edited.id);
    expect(publicHit.resource.available, isTrue);
    expect(publicHit.resource.publicQuantity, 7);

    await api.savePoint({
      ...pointFields,
      'name': edited.name,
      'active': false,
    }, point: edited);
    expect((await http.get(detailUrl)).statusCode, 404);
    expect(
      (await public.search(withoutLocation)).map((hit) => hit.point.id),
      isNot(contains(edited.id)),
    );
    expect((await api.stock(edited.id)).single.quantity, 7);
    final firstMovement = (await api.history(firstStock.id)).single;
    expect(firstMovement.previousBalance, 0);
    expect(firstMovement.resultingBalance, 7);
    expect(firstMovement.responsible, 'Gestor de demonstração');

    final points = await api.points();
    final central = points.singleWhere((point) => point.id == 'central');
    final stocks = await api.stock(central.id);
    final water = stocks.firstWhere((s) => s.id == 'central-water');
    final previous = water.quantity;
    await api.move(water, MovementType.entry, 20, 'Teste em banco isolado');
    const query = SearchQuery(
      'Água',
      SearchIntent.help,
      coordinates: GeoCoordinates(-23.55, -46.63),
    );
    final results = await public.search(query);
    expect(results.length, greaterThan(1));
    expect(
      results
          .singleWhere((hit) => hit.point.id == central.id)
          .resource
          .publicQuantity,
      previous + 20,
    );
    final history = await api.history(water.id);
    expect(history.first.responsible, 'Gestor de demonstração');
    expect(history.first.resultingBalance, previous + 20);
    final updated = (await api.stock(
      central.id,
    )).singleWhere((s) => s.id == water.id);
    await api.publish(updated, {
      'visible': true,
      'public_quantity': false,
      'distributable': true,
      'accepts_donation': false,
    });
    final hit = (await public.search(
      withoutLocation,
    )).singleWhere((hit) => hit.point.id == central.id);
    expect(hit.point.distanceKm, isNull);
    final published = hit.resource;
    expect(published.publicQuantity, isNull);
    expect(published.available, isTrue);
    expect(published.acceptsDonation, isFalse);
    await api.logout();
    expect(api.session, isNull);
  }, skip: url == null ? 'Execute iniciar.ps1 -Action integration.' : false);
}
