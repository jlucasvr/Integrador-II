import 'package:apoio_app/data/models/geo_coordinates.dart';
import 'package:apoio_app/data/models/search_intent.dart';
import 'package:apoio_app/data/models/search_query.dart';
import 'package:apoio_app/data/repositories/api_point_repository.dart';
import 'package:apoio_app/data/repositories/mock_point_repository.dart';
import 'package:apoio_app/ui/search/view_models/results_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('demonstração ignora raio e mantém o filtro de disponibilidade',
      () async {
    final model = ResultsViewModel(
        MockPointRepository(), const SearchQuery('Água', SearchIntent.help));
    addTearDown(model.dispose);
    expect(await model.request, hasLength(3));
    expect(model.canFilterByDistance, isFalse);
    final previous = model.request;
    model.setRadius(2);
    expect(model.request, same(previous));
    model.setAvailableOnly(true);
    final available = await model.request;
    expect(available, hasLength(2));
    expect(available.every((hit) => hit.point.distanceKm == null), isTrue);
  });

  test('nova busca mantém filtros e usa as coordenadas atualizadas', () async {
    final repository = ApiPointRepository('http://localhost:3000/api/v1',
        client: MockClient((_) async => http.Response('{"data":[]}', 200)));
    final model = ResultsViewModel(
        repository, const SearchQuery('Água', SearchIntent.help));
    addTearDown(repository.dispose);
    addTearDown(model.dispose);
    await model.request;
    expect(model.canFilterByDistance, isFalse);
    model.search('Água', coordinates: const GeoCoordinates(-23.55, -46.63));
    await model.request;
    expect(model.canFilterByDistance, isTrue);
    model.setRadius(2);
    await model.request;
    model.setAvailableOnly(true);
    await model.request;
    model.search('Cobertor', coordinates: const GeoCoordinates(-22.9, -43.2));
    await model.request;
    expect(model.query.term, 'Cobertor');
    expect(model.query.coordinates!.latitude, -22.9);
    expect(model.query.availableOnly, isTrue);
    expect(model.query.radiusKm, 2);
  });
}
