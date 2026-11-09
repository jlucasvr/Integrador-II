import 'dart:convert';
import 'package:apoio_app/data/models/stock_item.dart';
import 'package:apoio_app/data/repositories/management_repository.dart';
import 'package:apoio_app/ui/core/theme/wireframe_theme.dart';
import 'package:apoio_app/ui/management/views/point_form.dart';
import 'package:apoio_app/ui/management/views/publication_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import '../../fixtures/management_api_fixture.dart';

void main() {
  for (final width in [390.0, 1280.0]) {
    testWidgets('cadastro valida e salva ponto em $width px', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Map<String, dynamic>? saved;
      final attempts = <String?>[];
      final payloads = <String>[];
      final retry = width == 390;
      final api = ManagementRepository('http://localhost/api/v1',
          client: MockClient((r) async {
        if (r.url.path.endsWith('/login')) return ok(sessionData());
        if (r.url.path.endsWith('/my-institutions')) {
          return ok([
            {'id': 'inst-central', 'name': 'Instituição Central'}
          ]);
        }
        attempts.add(r.headers['idempotency-key']);
        payloads.add(r.body);
        if (retry && attempts.length == 1) {
          return failure(502, 'Resposta do cadastro não confirmada.');
        }
        saved = jsonDecode(r.body) as Map<String, dynamic>;
        return ok({'id': 'new'}, 201);
      }));
      addTearDown(api.dispose);
      await api.login('manager', 'password');
      await tester.pumpWidget(
          MaterialApp(theme: wireframeTheme(), home: PointForm(api: api)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Salvar ponto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar ponto'));
      await tester.pumpAndSettle();
      expect(saved, isNull);
      await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Instituição Central').last);
      await tester.pumpAndSettle();
      final values = [
        'Ponto Centro',
        'Rua A, 10',
        'São Paulo',
        '8h às 18h',
        'Telefone 123',
        '-23,5',
        '-46.6'
      ];
      for (var i = 0; i < values.length; i++) {
        await tester.ensureVisible(find.byType(TextFormField).at(i));
        await tester.enterText(find.byType(TextFormField).at(i), values[i]);
      }
      await tester.ensureVisible(find.text('Salvar ponto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar ponto'));
      await tester.pumpAndSettle();
      if (retry) {
        expect(saved, isNull);
        expect(attempts, hasLength(1));
        expect(
            tester
                .widget<TextFormField>(find.byType(TextFormField).first)
                .enabled,
            isFalse);
        final confirmation = find.text('Confirmar cadastro');
        await tester.scrollUntilVisible(confirmation, 150,
            scrollable: find
                .descendant(
                    of: find.byType(ListView),
                    matching: find.byType(Scrollable))
                .first);
        await tester.pumpAndSettle();
        await tester.tap(confirmation);
        await tester.pumpAndSettle();
        expect(attempts, [attempts.first, attempts.first]);
        expect(payloads, [payloads.first, payloads.first]);
      }
      expect(attempts.first, matches(RegExp(r'^[a-f0-9]{32}$')));
      expect(saved?['institution_id'], 'inst-central');
      expect(saved?['latitude'], -23.5);
      expect(saved?['contact'], 'Telefone 123');
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('publicação envia opções e bloqueia reenvio após conflito',
      (tester) async {
    var requests = 0;
    final fixture = ApiFixture();
    final api = ManagementRepository('http://localhost/api/v1',
        client: MockClient((r) async {
      if (r.url.path.endsWith('/login')) return ok(sessionData());
      requests++;
      final body = jsonDecode(r.body);
      expect(body['visible'], false);
      expect(body['expectedVersion'], 0);
      expect(body['public_quantity'], true);
      return failure(
          409, 'Recarregue o estoque antes de alterar a publicação.');
    }));
    addTearDown(api.dispose);
    await api.login('manager', 'password');
    await tester.pumpWidget(MaterialApp(
        theme: wireframeTheme(),
        home: PublicationForm(api: api, item: StockItem(fixture.stock()))));
    await tester.tap(find.text('Exibir na consulta pública'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Salvar publicação'));
    await tester.tap(find.text('Salvar publicação'));
    await tester.pumpAndSettle();
    expect(requests, 1);
    await tester.scrollUntilVisible(find.text('Salvar publicação'), 200);
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    expect(find.textContaining('Volte ao estoque'), findsOneWidget);
  });
}
