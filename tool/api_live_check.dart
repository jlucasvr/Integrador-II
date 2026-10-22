import 'package:apoio_app/data/models/geo_coordinates.dart';
import 'dart:io';

import 'package:apoio_app/data/models/search_intent.dart';
import 'package:apoio_app/data/models/search_query.dart';
import 'package:apoio_app/data/repositories/api_point_repository.dart';

Future<void> main() async {
  final repository = ApiPointRepository('http://127.0.0.1:3000/api/v1');
  try {
    final hits = await repository.search(const SearchQuery(
        'Água', SearchIntent.help,
        coordinates: GeoCoordinates(-23.55, -46.63)));
    if (hits.length != 3) {
      throw StateError('Esperados três pontos de demonstração.');
    }
    final hidden = hits.firstWhere((h) => h.point.id == 'norte');
    if (hidden.resource.publicQuantity != null ||
        hidden.point.distanceKm == null) {
      throw StateError(
          'A resposta publicou uma quantidade privada ou omitiu a distância.');
    }
    final alternatives = await repository.search(const SearchQuery(
        'Água mineral', SearchIntent.help,
        coordinates: GeoCoordinates(-23.55, -46.63)));
    if (alternatives.isEmpty || alternatives.any((h) => !h.alternative)) {
      throw StateError('Alternativas não identificadas.');
    }
    stdout.writeln('Integração cliente Dart → API → SQLite aprovada.');
  } finally {
    repository.dispose();
  }
}
