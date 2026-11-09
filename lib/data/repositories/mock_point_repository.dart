import 'package:apoio_app/core/utils/normalize.dart';
import 'package:apoio_app/data/fixtures/demo_points.dart';
import 'package:apoio_app/data/models/resource.dart';
import 'package:apoio_app/data/models/search_hit.dart';
import 'package:apoio_app/data/models/search_intent.dart';
import 'package:apoio_app/data/models/search_query.dart';
import 'package:apoio_app/data/repositories/point_repository.dart';

class MockPointRepository implements PointRepository {
  @override
  bool get isDemo => true;

  bool failNextRequest = false;
  @override
  Future<List<SearchHit>> search(SearchQuery query) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (failNextRequest) {
      failNextRequest = false;
      throw Exception('Falha de conexão simulada');
    }
    final term = normalize(query.term);
    if (term.isEmpty) return [];
    final help = query.intent == SearchIntent.help;
    bool eligible(Resource r) =>
        help ? !query.availableOnly || r.available : r.acceptsDonation;

    List<SearchHit> collectHits(
        bool Function(Resource) matches, bool alternative) {
      final hits = <SearchHit>[];
      for (final point in demoPoints) {
        final candidates =
            point.resources.where((r) => eligible(r) && matches(r));
        final resource =
            (help ? candidates.where((r) => r.available).firstOrNull : null) ??
                candidates.firstOrNull;
        if (resource != null) hits.add(SearchHit(point, resource, alternative));
      }
      return hits
        ..sort((a, b) {
          if (a.resource.available != b.resource.available) {
            return a.resource.available ? -1 : 1;
          }
          return a.point.name.compareTo(b.point.name);
        });
    }

    final exact = collectHits(
        (r) =>
            normalize(r.name).contains(term) || normalize(r.category) == term,
        false);
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
    return collectHits((r) => r.category == category, true);
  }
}
