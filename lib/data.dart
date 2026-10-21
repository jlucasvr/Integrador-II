enum SearchIntent { help, donate }

class Resource {
  final String name;
  final String category;
  final String unit;
  final bool available;
  final bool acceptsDonation;
  final int? publicQuantity;
  final String? updatedAt;
  const Resource(this.name, this.category, this.unit, this.available,
      this.acceptsDonation, this.publicQuantity,
      {this.updatedAt});
}

class SupportPoint {
  final String id, name, institution, address, hours, updatedAt;
  final double? distanceKm;
  final List<Resource> resources;
  const SupportPoint(
      {required this.id,
      required this.name,
      required this.institution,
      required this.address,
      required this.hours,
      required this.updatedAt,
      required this.distanceKm,
      required this.resources});
}

class SearchQuery {
  final String term, location;
  final SearchIntent intent;
  const SearchQuery(this.term, this.location, this.intent);
}

class SearchHit {
  final SupportPoint point;
  final Resource resource;
  final bool alternative;
  const SearchHit(this.point, this.resource, this.alternative);
}

abstract class PointRepository {
  Future<List<SearchHit>> search(SearchQuery query);
}

String normalize(String value) {
  var result = value.toLowerCase().trim();
  const accents = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'é': 'e',
    'ê': 'e',
    'í': 'i',
    'ó': 'o',
    'ô': 'o',
    'õ': 'o',
    'ú': 'u',
    'ç': 'c'
  };
  accents.forEach((a, b) {
    result = result.replaceAll(a, b);
  });
  return result;
}

class MockPointRepository implements PointRepository {
  bool failNextRequest = false;
  @override
  Future<List<SearchHit>> search(SearchQuery query) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (failNextRequest) {
      failNextRequest = false;
      throw Exception('Falha de conexão simulada');
    }
    final term = normalize(query.term);
    bool eligible(Resource r) =>
        query.intent == SearchIntent.help || r.acceptsDonation;
    final exact = <SearchHit>[];
    for (final point in demoPoints) {
      for (final resource in point.resources) {
        if (eligible(resource) &&
            (normalize(resource.name).contains(term) ||
                normalize(resource.category) == term)) {
          exact.add(SearchHit(point, resource, false));
          break;
        }
      }
    }
    if (exact.isNotEmpty) return exact;
    // Only an explicit alias can trigger an alternative; unrelated terms stay empty.
    const aliases = {
      'agua mineral': 'Água',
      'comida': 'Alimentos',
      'sabonete': 'Higiene',
      'agasalho': 'Abrigo'
    };
    final category = aliases[term];
    if (category == null) return [];
    final alternatives = <SearchHit>[];
    for (final point in demoPoints) {
      for (final resource in point.resources) {
        if (eligible(resource) && resource.category == category) {
          alternatives.add(SearchHit(point, resource, true));
          break;
        }
      }
    }
    return alternatives;
  }
}

const demoPoints = [
  SupportPoint(
      id: 'central',
      name: 'Centro de Apoio Central',
      institution: 'Instituição Solidariedade',
      address: 'Rua Exemplo, 100 · Centro',
      hours: 'Segunda a sexta, das 8h às 18h',
      updatedAt: '14/10/2026, às 10h',
      distanceKm: 1.2,
      resources: [
        Resource('Água potável', 'Água', 'garrafas de 1 L', true, true, 120),
        Resource('Cesta básica', 'Alimentos', 'cestas', true, true, 25),
        Resource('Kit de higiene', 'Higiene', 'kits', false, true, 0)
      ]),
  SupportPoint(
      id: 'norte',
      name: 'Ponto Comunitário Norte',
      institution: 'Associação Bairro Unido',
      address: 'Avenida Modelo, 250 · Bairro Norte',
      hours: 'Segunda a sexta, das 8h às 17h',
      updatedAt: '14/10/2026, às 9h',
      distanceKm: 2.8,
      resources: [
        Resource('Água potável', 'Água', 'garrafas de 1 L', true, true, null),
        Resource('Cobertor', 'Abrigo', 'unidades', true, true, 40)
      ]),
  SupportPoint(
      id: 'sul',
      name: 'Escola de Apoio Sul',
      institution: 'Rede de Apoio Municipal',
      address: 'Rua Ilustrativa, 40 · Bairro Sul',
      hours: 'Segunda a sexta, das 8h às 18h',
      updatedAt: '13/10/2026, às 16h',
      distanceKm: 4.1,
      resources: [
        Resource('Água potável', 'Água', 'garrafas de 1 L', false, true, 0),
        Resource('Cesta básica', 'Alimentos', 'cestas', true, false, 10)
      ])
];
