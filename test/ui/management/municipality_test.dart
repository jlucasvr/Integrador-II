import 'dart:convert';

import 'package:apoio_app/data/repositories/management_repository.dart';
import 'package:apoio_app/ui/core/theme/wireframe_theme.dart';
import 'package:apoio_app/ui/management/views/management_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';

import '../../fixtures/management_api_fixture.dart';
import '../../helpers/management_actions.dart';

void main() {
  for (final size in [const Size(320, 600), const Size(1280, 900)]) {
    testWidgets('prefeitura cadastra e verifica instituição em $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final institutions = [
        {'id': 'first', 'name': 'Associação Norte', 'status': 'verified'},
      ];
      var loadFailed = false;
      var decisions = 0;
      final session = sessionData();
      session['user']['role'] = 'municipality';
      final api = ManagementRepository(
        'http://localhost/api/v1',
        client: MockClient((request) async {
          if (request.url.path.endsWith('/auth/login')) return ok(session);
          expect(request.headers['Authorization'], 'Bearer test-token');
          switch (request.method) {
            case 'GET':
              expect(request.url.path, '/api/v1/manage/institutions');
              if (!loadFailed) {
                loadFailed = true;
                return failure(403, 'Acesso restrito à prefeitura.');
              }
              return ok(institutions);
            case 'POST':
              expect(request.url.path, '/api/v1/manage/institutions');
              expect(jsonDecode(request.body), {'name': 'Instituição Sul'});
              final created = {
                'id': 'second',
                'name': 'Instituição Sul',
                'status': 'pending',
              };
              institutions.add(created);
              return ok(created, 201);
            case 'PATCH':
              expect(
                request.url.path,
                '/api/v1/manage/institutions/second/verification',
              );
              expect(jsonDecode(request.body), {
                'status': 'verified',
                'note': 'Documentos conferidos',
              });
              decisions++;
              institutions.last['status'] = 'verified';
              return ok({'id': 'second', 'status': 'verified'});
          }
          throw StateError('Método inesperado');
        }),
      );
      addTearDown(api.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: wireframeTheme(),
          home: ManagementPage(api: api),
        ),
      );
      await login(tester);
      expect(find.text('Acesso restrito à prefeitura.'), findsOneWidget);
      await tapVisible(tester, find.text('Tentar novamente'));
      expect(find.text('Prefeitura'), findsOneWidget);
      expect(find.text('Pontos sob sua gestão'), findsNothing);

      await tapVisible(tester, find.text('Cadastrar instituição'));
      await tester.enterText(find.byType(TextFormField), '  Instituição Sul  ');
      await tapVisible(tester, find.text('Cadastrar'));
      final messenger = tester.state<ScaffoldMessengerState>(
        find.byType(ScaffoldMessenger),
      );
      expect(
        find.text('Instituição cadastrada como pendente.'),
        findsOneWidget,
      );
      messenger.hideCurrentSnackBar();
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Pendentes · 1'));
      expect(find.text('Associação Norte'), findsNothing);
      await tester.enterText(
        find.widgetWithText(TextField, 'Buscar instituição'),
        'instituicao sul',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Ver detalhes'));
      expect(find.text('Pendente'), findsOneWidget);
      await tapVisible(tester, find.text('Alterar situação'));
      await tapVisible(tester, find.text('Nova situação'));
      await tapVisible(tester, find.text('Verificada').last);
      await tapVisible(tester, find.text('Confirmar decisão'));
      expect(decisions, 0);
      await tester.enterText(
        find.byType(TextFormField),
        'Documentos conferidos',
      );
      await tapVisible(tester, find.text('Confirmar decisão'));
      expect(decisions, 1);
      expect(find.text('Verificada'), findsOneWidget);
      await tapVisible(tester, find.text('Todas as instituições'));
      expect(find.text('Pendentes · 0'), findsOneWidget);
      expect(find.text('Nenhuma instituição encontrada'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
