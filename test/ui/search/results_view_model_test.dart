import 'package:apoio_app/data/models/geo_coordinates.dart';
import 'package:apoio_app/data/fixtures/demo_points.dart';
import 'package:apoio_app/data/models/search_hit.dart';
import 'package:apoio_app/data/models/search_intent.dart';
import 'package:apoio_app/data/models/search_query.dart';
import 'package:apoio_app/data/models/support_point.dart';
import 'package:apoio_app/data/repositories/mock_point_repository.dart';
import 'package:apoio_app/ui/search/view_models/results_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('modo de teste ignora distância e mantém o filtro de disponibilidade',
      () async {
    final model = ResultsViewModel(
        MockPointRepository(locationFilteringEnabled: false),
        const SearchQuery('Água', SearchIntent.help,
            coordinates: GeoCoordinates(0, 0)));
    addTearDown(model.dispose);
    final hits = await model.request;
    model.setRadius(2);
    expect(model.filter(hits), hasLength(3));
    model.setAvailableOnly(true);
    expect(model.filter(hits), hasLength(2));
  });
  test('filtro de distância exclui valores desconhecidos e mantém a origem',
      () async {
    final model = ResultsViewModel(
        MockPointRepository(),
        const SearchQuery('Água', SearchIntent.help,
            coordinates: GeoCoordinates(-23.55, -46.63)));
    addTearDown(model.dispose);
    await model.request;
    final point = demoPoints.first;
    final unknown = SupportPoint(
        id: 'unknown',
        name: 'Ponto sem distância',
        institution: point.institution,
        address: point.address,
        hours: point.hours,
        updatedAt: point.updatedAt,
        distanceKm: null,
        resources: point.resources);
    final hits = [
      SearchHit(unknown, unknown.resources.first, false),
      SearchHit(point, point.resources.first, false),
    ];
    expect(model.filter(hits).first.point.id, point.id);
    expect(hits.first.point.id, 'unknown');
    model.setRadius(2);
    expect(model.filter(hits).map((hit) => hit.point.id), [point.id]);
    model.setRadius(null);
    expect(model.filter(hits), hasLength(2));
  });

  test('nova busca mantém filtros e usa as coordenadas atualizadas', () async {
    final model = ResultsViewModel(
        MockPointRepository(),
        const SearchQuery('Água', SearchIntent.help,
            coordinates: GeoCoordinates(-23.55, -46.63)));
    addTearDown(model.dispose);
    model.setAvailableOnly(true);
    await model.request;
    model.search('Cobertor', coordinates: const GeoCoordinates(-22.9, -43.2));
    final hits = await model.request;
    expect(model.query.term, 'Cobertor');
    expect(model.query.coordinates.latitude, -22.9);
    expect(model.availableOnly, isTrue);
    expect(model.filter(hits).single.point.id, 'norte');
  });
}
