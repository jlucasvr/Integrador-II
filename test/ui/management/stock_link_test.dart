import 'dart:async';
import 'dart:convert';

import 'package:apoio_app/data/models/managed_point.dart';
import 'package:apoio_app/data/repositories/management_repository.dart';
import 'package:apoio_app/ui/core/theme/wireframe_theme.dart';
import 'package:apoio_app/ui/management/views/stock_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../fixtures/management_api_fixture.dart';

const blanket = {
  'id': 'blanket',
  'name': 'Cobertor',
  'category': 'Abrigo',
  'unit': 'unidades',
};
const water = {
  'id': 'water',
  'name': 'Água potável',
  'category': 'Água',
  'unit': 'garrafas de 1 L',
};
final linkedBlanket = {
  ...blanket,
  'id': 'stock-blanket',
  'quantity': 0,
  'visible': 0,
  'version': 0,
  'updated_at': '2026-11-09T10:00:00Z',
};

Future<void> openStock(WidgetTester tester, ManagementRepository api) async {
  addTearDown(api.dispose);
  await api.login('manager', 'password');
  await tester.pumpWidget(
    MaterialApp(
      theme: wireframeTheme(),
      home: Scaffold(
        appBar: AppBar(title: const Text('Estoque do ponto')),
        body: StockView(
          api: api,
          point: ManagedPoint({
            'id': 'new-point',
            'name': 'Novo ponto',
            'institution': 'Instituição Teste',
            'address': 'Rua Exemplo, 100',
            'hours': '8h às 18h',
          }),
          onMove: (_) {},
          onHistory: (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final size in [const Size(320, 568), const Size(1280, 900)]) {
    testWidgets('vincula item e atualiza o estoque em $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final catalog = Completer<http.Response>();
      final link = Completer<http.Response>();
      var linked = false;
      var writes = 0;
      final api = ManagementRepository(
        'http://localhost/api/v1',
        client: MockClient((request) async {
          if (request.url.path.endsWith('/login')) return ok(sessionData());
          if (request.url.path.endsWith('/new-point/catalog')) {
            return catalog.future;
          }
          expect(request.url.path, '/api/v1/manage/points/new-point/stock');
          if (request.method == 'GET') return ok(linked ? [linkedBlanket] : []);
          writes++;
          expect(jsonDecode(request.body), {'item_id': 'blanket'});
          return link.future;
        }),
      );
      await openStock(tester, api);
      expect(find.textContaining('O estoque está vazio'), findsOneWidget);
      await tester.tap(find.text('Vincular item do catálogo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      catalog.complete(ok([blanket, water]));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'abrigo');
      await tester.pumpAndSettle();
      expect(find.text('Água potável'), findsNothing);
      await tester.tap(find.byTooltip('Vincular Cobertor'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNull,
      );
      expect(writes, 1);
      linked = true;
      link.complete(ok({'id': 'stock-blanket'}, 201));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Cobertor'),
        100,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Cobertor'), findsOneWidget);
      expect(find.text('Saldo: 0 unidades'), findsOneWidget);
      expect(find.text('Item oculto da consulta pública'), findsOneWidget);
      expect(find.text('Movimentar'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'recupera falha de catálogo e atualiza após vínculo concorrente',
    (tester) async {
      var catalogReads = 0;
      var linked = false;
      final api = ManagementRepository(
        'http://localhost/api/v1',
        client: MockClient((request) async {
          if (request.url.path.endsWith('/login')) return ok(sessionData());
          if (request.url.path.endsWith('/catalog')) {
            catalogReads++;
            if (catalogReads == 1) {
              return failure(503, 'Catálogo indisponível.');
            }
            return ok(linked ? [water] : [blanket, water]);
          }
          if (request.method == 'GET') return ok(linked ? [linkedBlanket] : []);
          linked = true;
          return failure(409, 'Este item já está vinculado.');
        }),
      );
      await openStock(tester, api);
      await tester.tap(find.text('Vincular item do catálogo'));
      await tester.pumpAndSettle();
      expect(find.text('Catálogo indisponível.'), findsOneWidget);
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Vincular Cobertor'));
      await tester.pumpAndSettle();
      expect(find.text('Este item já está vinculado.'), findsOneWidget);
      expect(find.byTooltip('Vincular Cobertor'), findsNothing);
      expect(find.byTooltip('Vincular Água potável'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Saldo: 0 unidades'), findsOneWidget);
      expect(catalogReads, 3);
    },
  );
}
