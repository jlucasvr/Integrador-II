import 'dart:io';
import 'package:apoio_app/api_repository.dart';
import 'package:apoio_app/data.dart';

Future<void> main() async {
  final repository = ApiPointRepository('http://127.0.0.1:3000/api/v1');
  try {
    final hits = await repository
        .search(const SearchQuery('Água', 'Cidade Exemplo', SearchIntent.help));
    if (hits.length != 3) {
      throw StateError('Esperados três pontos de demonstração.');
    }
    final hidden = hits.firstWhere((h) => h.point.id == 'norte');
    if (hidden.resource.publicQuantity != null ||
        hidden.point.distanceKm != null) {
      throw StateError(
          'A resposta publicou uma quantidade ou distância indevida.');
    }
    final alternatives = await repository.search(
        const SearchQuery('Água mineral', 'Cidade Exemplo', SearchIntent.help));
    if (alternatives.isEmpty || alternatives.any((h) => !h.alternative)) {
      throw StateError('Alternativas não identificadas.');
    }
    stdout.writeln('Integração cliente Dart → API → SQLite aprovada.');
  } finally {
    repository.client.close();
  }
}
