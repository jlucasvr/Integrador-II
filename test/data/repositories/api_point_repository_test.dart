import 'package:apoio_app/data/models/geo_coordinates.dart';
import 'dart:convert';

import 'package:apoio_app/data/models/search_intent.dart';
import 'package:apoio_app/data/models/search_query.dart';
import 'package:apoio_app/data/repositories/api_point_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('API preserva quantidade privada e distância desconhecida', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/v1/points');
      expect(request.url.queryParameters['intent'], 'donate');
      expect(request.url.queryParameters['lat'], '-23.55');
      expect(request.url.queryParameters['lon'], '-46.63');
      expect(request.url.queryParameters.containsKey('location'), isFalse);
      final r = {
        'name': 'Água potável',
        'category': 'Água',
        'unit': 'garrafas de 1 L',
        'available': true,
        'acceptsDonation': true,
        'publicQuantity': null,
        'updatedAt': '2026-10-14T13:00:00Z'
      };
      return http.Response(
          jsonEncode({
            'data': [
              {
                'point': {
                  'id': 'norte',
                  'name': 'Ponto Norte',
                  'institution': 'Instituição',
                  'address': 'Rua Exemplo',
                  'hours': '8h às 17h',
                  'updatedAt': '2026-10-14T13:00:00Z',
                  'distanceKm': null,
                  'resources': [r]
                },
                'resource': r,
                'alternative': false
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'});
    });
    final hits =
        await ApiPointRepository('http://localhost:3000/api/v1', client: client)
            .search(const SearchQuery('Água', SearchIntent.donate,
                coordinates: GeoCoordinates(-23.55, -46.63)));
    expect(hits.single.resource.publicQuantity, isNull);
    expect(hits.single.point.distanceKm, isNull);
    expect(hits.single.resource.name, 'Água potável');
  });
  test('falha HTTP é propagada para a tela de tentativa novamente', () async {
    final repository = ApiPointRepository('http://localhost:3000/api/v1',
        client: MockClient((_) async => http.Response('{}', 503)));
    await expectLater(
        repository.search(const SearchQuery('Água', SearchIntent.help,
            coordinates: GeoCoordinates(-23.55, -46.63))),
        throwsException);
  });
}
