import 'package:apoio_app/app/app.dart';
import 'package:apoio_app/core/errors/management_failure.dart';
import 'package:apoio_app/data/repositories/management_repository.dart';
import 'package:apoio_app/data/repositories/mock_point_repository.dart';
import 'package:apoio_app/ui/management/views/management_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../fixtures/management_api_fixture.dart';
import '../../helpers/management_actions.dart';

void main() {
  testWidgets('sessão expirada na consulta privada retorna ao login',
      (tester) async {
    final api = ManagementRepository('http://localhost/api/v1',
        client: MockClient((request) async {
      if (request.url.path.endsWith('/login')) {
        return ok(sessionData());
      }
      return failure(401, 'Sessão expirada.');
    }));
    addTearDown(api.dispose);
    await api.login('gestor@example.test', 'password');
    await tester.pumpWidget(MaterialApp(home: ManagementPage(api: api)));
    await tester.pumpAndSettle();
    expect(find.text('Acesso da instituição'), findsOneWidget);
    expect(find.text('Sua sessão expirou. Entre novamente.'), findsOneWidget);
    expect(api.session, isNull);
  });
  test('credenciais incorretas não criam sessão', () async {
    final fixture = ApiFixture();
    addTearDown(fixture.api.dispose);
    await expectLater(fixture.api.login('gestor@example.test', 'incorrect'),
        throwsA(isA<ManagementFailure>()));
    expect(fixture.api.session, isNull);
  });
  test('401 de uma rota privada encerra a sessão', () async {
    final api = ManagementRepository('http://localhost/api/v1',
        client: MockClient((r) async => r.url.path.endsWith('/login')
            ? ok(sessionData())
            : failure(401, 'Sessão expirada.')));
    addTearDown(api.dispose);
    await api.login('gestor@example.test', 'password');
    await expectLater(api.points(), throwsA(isA<ManagementFailure>()));
    expect(api.session, isNull);
    expect(api.signInNotice, contains('expirou'));
  });
  test('logout limpa a sessão mesmo quando a conexão falha', () async {
    final api = ManagementRepository('http://localhost/api/v1',
        client: MockClient((r) async {
      if (r.url.path.endsWith('/login')) return ok(sessionData());
      throw http.ClientException('offline');
    }));
    addTearDown(api.dispose);
    await api.login('gestor@example.test', 'password');
    await expectLater(api.logout(), throwsA(isA<ManagementFailure>()));
    expect(api.session, isNull);
  });

  for (final width in [390.0, 1280.0]) {
    testWidgets(
        'login → estoque → entrada → histórico e logout em ${width.toInt()} px',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fixture = ApiFixture();
      addTearDown(fixture.api.dispose);
      await tester.pumpWidget(ApoioApp(
          repository: MockPointRepository(), managementApi: fixture.api));
      await tapVisible(tester, find.byTooltip('Gestão'));
      await login(tester);
      expect(find.text('Meus pontos'), findsOneWidget);
      await tapVisible(tester, find.text('Centro de Apoio Central'));
      expect(find.text('Saldo: 120 garrafas de 1 L'), findsOneWidget);
      await tapVisible(tester, find.text('Movimentar'));
      await tester.enterText(
          find.byKey(const ValueKey('movement-quantity')), '20');
      await tester.pumpAndSettle();
      expect(
          find.text('Saldo após entrada: 140 garrafas de 1 L'), findsOneWidget);
      await tapVisible(tester, find.text('Confirmar entrada'));
      expect(find.text('Saldo: 140 garrafas de 1 L'), findsOneWidget);
      expect(fixture.movementRequests, 1);
      await tapVisible(tester, find.text('Histórico'));
      expect(find.text('Saldo: 120 → 140'), findsOneWidget);
      expect(find.text('Responsável: Gestor Teste'), findsOneWidget);
      await tapVisible(tester, find.text('Sair'));
      expect(find.text('Acesso da instituição'), findsOneWidget);
      expect(fixture.api.session, isNull);
    });
  }

  testWidgets('saída excedente é bloqueada antes de enviar à API',
      (tester) async {
    final fixture = ApiFixture();
    addTearDown(fixture.api.dispose);
    await fixture.api.login('gestor@example.test', 'password');
    await tester
        .pumpWidget(MaterialApp(home: ManagementPage(api: fixture.api)));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Centro de Apoio Central'));
    await tapVisible(tester, find.text('Movimentar'));
    await tapVisible(tester, find.text('Saída'));
    await tester.enterText(
        find.byKey(const ValueKey('movement-quantity')), '121');
    await tapVisible(tester, find.text('Confirmar saída'));
    expect(find.text('A saída excede o saldo de 120.'), findsOneWidget);
    expect(fixture.movementRequests, 0);
  });
  for (final uncertain in [false, true]) {
    testWidgets(
        'falha ${uncertain ? 'de conexão' : 'de versão'} impede reenvio sem conferir saldo',
        (tester) async {
      final fixture = ApiFixture()
        ..stale = !uncertain
        ..connectionLost = uncertain;
      addTearDown(fixture.api.dispose);
      await fixture.api.login('gestor@example.test', 'password');
      await tester
          .pumpWidget(MaterialApp(home: ManagementPage(api: fixture.api)));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Centro de Apoio Central'));
      await tapVisible(tester, find.text('Movimentar'));
      await tester.enterText(
          find.byKey(const ValueKey('movement-quantity')), '20');
      await tapVisible(tester, find.text('Confirmar entrada'));
      expect(
          tester
              .widget<FilledButton>(
                  find.widgetWithText(FilledButton, 'Confirmar entrada'))
              .onPressed,
          isNull);
      expect(find.text('Conferir estoque e histórico'), findsOneWidget);
      expect(fixture.movementRequests, 1);
    });
  }
}
