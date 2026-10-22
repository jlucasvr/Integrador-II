import 'package:apoio_app/data/models/geo_coordinates.dart';
import 'package:apoio_app/data/models/movement_type.dart';
import 'package:apoio_app/data/models/search_intent.dart';
import 'package:apoio_app/data/models/search_query.dart';
import 'package:apoio_app/data/repositories/api_point_repository.dart';
import 'package:apoio_app/data/repositories/management_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const url = String.fromEnvironment('LIVE_API_BASE_URL');
  test('entrada do gestor atualiza busca pública na API real', () async {
    final api = ManagementRepository(url), public = ApiPointRepository(url);
    addTearDown(api.dispose);
    addTearDown(public.dispose);
    await api.login('gestor@example.test', 'integration-test-password');
    final points = await api.points();
    expect(points.single.id, 'central');
    final stocks = await api.stock(points.single.id);
    final water = stocks.firstWhere((s) => s.id == 'central-water');
    final previous = water.quantity;
    await api.move(water, MovementType.entry, 20, 'Teste em banco isolado');
    final results = await public.search(const SearchQuery(
        'Água', SearchIntent.help,
        coordinates: GeoCoordinates(-23.55, -46.63)));
    expect(results.single.resource.publicQuantity, previous + 20);
    final history = await api.history(water.id);
    expect(history.first.responsible, 'Gestor de demonstração');
    expect(history.first.resultingBalance, previous + 20);
    await api.logout();
    expect(api.session, isNull);
  }, skip: url.isEmpty ? 'Requer API isolada de integração.' : false);
}
