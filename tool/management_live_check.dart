import 'package:flutter_test/flutter_test.dart';
import 'package:apoio_app/management_api.dart';
import 'package:apoio_app/api_repository.dart';
import 'package:apoio_app/data.dart';

void main() {
  const url = String.fromEnvironment('LIVE_API_BASE_URL');
  test('entrada do gestor atualiza busca pública na API real', () async {
    final api = ManagementApi(url), public = ApiPointRepository(url);
    addTearDown(api.dispose);
    addTearDown(public.client.close);
    await api.login('gestor@example.test', 'integration-test-password');
    final points = await api.points();
    expect(points.single.id, 'central');
    final stocks = await api.stock(points.single.id);
    final water = stocks.firstWhere((s) => s.id == 'central-water');
    final previous = water.quantity;
    await api.move(water, MovementType.entry, 20, 'Teste em banco isolado');
    final results = await public.search(
        const SearchQuery('Água', 'Centro, Cidade Exemplo', SearchIntent.help));
    expect(results.single.resource.publicQuantity, previous + 20);
    final history = await api.history(water.id);
    expect(history.first.responsible, 'Gestor de demonstração');
    expect(history.first.resultingBalance, previous + 20);
    await api.logout();
    expect(api.session, isNull);
  }, skip: url.isEmpty ? 'Requer API isolada de integração.' : false);
}
