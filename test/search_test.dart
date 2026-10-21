import 'package:flutter_test/flutter_test.dart';
import 'package:apoio_app/data.dart';

void main() {
  test('aceitar doação não depende de estoque para distribuição', () async {
    final hits = await MockPointRepository().search(
        const SearchQuery('Água potável', 'Centro', SearchIntent.donate));
    expect(hits.any((h) => !h.resource.available && h.resource.acceptsDonation),
        isTrue);
  });
  test('quantidade oculta continua disponível e não é zero', () async {
    final hits = await MockPointRepository()
        .search(const SearchQuery('Água', 'Centro', SearchIntent.help));
    final hidden = hits.firstWhere((h) => h.point.id == 'norte').resource;
    expect(hidden.available, isTrue);
    expect(hidden.publicQuantity, isNull);
  });
  test('alternativas são identificadas e termos desconhecidos ficam vazios',
      () async {
    final repository = MockPointRepository();
    final alternatives = await repository
        .search(const SearchQuery('agua mineral', 'Centro', SearchIntent.help));
    expect(alternatives, isNotEmpty);
    expect(alternatives.every((h) => h.alternative), isTrue);
    expect(
        await repository.search(const SearchQuery(
            'medicamento inexistente', 'Centro', SearchIntent.help)),
        isEmpty);
  });
}
