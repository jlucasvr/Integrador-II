import 'package:apoio_app/data/models/geo_coordinates.dart';
import 'package:apoio_app/data/models/search_intent.dart';
import 'package:apoio_app/data/models/search_query.dart';
import 'package:apoio_app/data/repositories/mock_point_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('todas as categorias da busca possuem exemplos locais', () async {
    final repository = MockPointRepository();
    for (final category in [
      'Água',
      'Alimentos',
      'Higiene',
      'Abrigo',
      'Roupas',
      'Agasalhos',
      'Calçados',
      'Cobertores',
      'Medicamentos',
      'Infantil'
    ]) {
      final hits = await repository.search(SearchQuery(
          category, SearchIntent.help,
          coordinates: const GeoCoordinates(0, 0)));
      expect(hits, isNotEmpty, reason: category);
    }
  });
  test('aceitar doação não depende de estoque para distribuição', () async {
    final hits = await MockPointRepository().search(const SearchQuery(
        'Água potável', SearchIntent.donate,
        coordinates: GeoCoordinates(-23.55, -46.63)));
    expect(hits.any((h) => !h.resource.available && h.resource.acceptsDonation),
        isTrue);
  });
  test('quantidade oculta continua disponível e não é zero', () async {
    final hits = await MockPointRepository().search(const SearchQuery(
        'Água', SearchIntent.help,
        coordinates: GeoCoordinates(-23.55, -46.63)));
    final hidden = hits.firstWhere((h) => h.point.id == 'norte').resource;
    expect(hidden.available, isTrue);
    expect(hidden.publicQuantity, isNull);
  });
  test('alternativas são identificadas e termos desconhecidos ficam vazios',
      () async {
    final repository = MockPointRepository();
    final alternatives = await repository.search(const SearchQuery(
        'agua mineral', SearchIntent.help,
        coordinates: GeoCoordinates(-23.55, -46.63)));
    expect(alternatives, isNotEmpty);
    expect(alternatives.every((h) => h.alternative), isTrue);
    expect(
        await repository.search(const SearchQuery(
            'medicamento inexistente', SearchIntent.help,
            coordinates: GeoCoordinates(-23.55, -46.63))),
        isEmpty);
  });
}
