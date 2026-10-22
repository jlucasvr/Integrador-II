import 'package:apoio_app/core/utils/normalize.dart';
import 'package:apoio_app/data/fixtures/demo_points.dart';
import 'package:apoio_app/data/models/resource.dart';
import 'package:apoio_app/data/models/search_hit.dart';
import 'package:apoio_app/data/models/search_intent.dart';
import 'package:apoio_app/data/models/search_query.dart';
import 'package:apoio_app/data/repositories/point_repository.dart';

class MockPointRepository implements PointRepository {
  @override
  final bool locationFilteringEnabled;

  MockPointRepository({this.locationFilteringEnabled = true});

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
      'agasalho': 'Agasalhos',
      'roupa': 'Roupas',
      'calcado': 'Calçados',
      'coberta': 'Cobertores',
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
