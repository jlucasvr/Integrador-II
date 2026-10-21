import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:apoio_app/main.dart';
import 'package:apoio_app/data.dart';
import 'package:apoio_app/management_api.dart';
import 'package:apoio_app/management_page.dart';

Map<String, dynamic> sessionData() => {
      'token': 'test-token',
      'expiresAt':
          DateTime.now().add(const Duration(hours: 8)).toIso8601String(),
      'user': {
        'id': 'manager',
        'name': 'Gestor Teste',
        'email': 'gestor@example.test',
        'role': 'manager'
      },
    };
http.Response ok(dynamic value, [int status = 200]) =>
    http.Response(jsonEncode({'data': value}), status,
        headers: {'content-type': 'application/json; charset=utf-8'});
http.Response failure(int code, String message) => http.Response(
    jsonEncode({
      'error': {'message': message}
    }),
    code,
    headers: {'content-type': 'application/json; charset=utf-8'});

class ApiFixture {
  int quantity = 120, version = 0, movementRequests = 0;
  bool stale = false, connectionLost = false;
  final List<Map<String, dynamic>> history = [];
  late final ManagementApi api =
      ManagementApi('http://localhost:3000/api/v1', client: MockClient(handle));
  Map<String, dynamic> stock() => {
        'id': 'central-water',
        'name': 'Água potável',
        'category': 'Água',
        'unit': 'garrafas de 1 L',
        'quantity': quantity,
        'version': version,
        'updated_at': '2026-10-14T13:00:00Z',
        'public_quantity': 1,
        'visible': 1,
        'distributable': 1,
        'accepts_donation': 1
      };
  Future<http.Response> handle(http.Request request) async {
    if (request.url.path.endsWith('/auth/login')) {
      final body = jsonDecode(request.body);
      if (body['password'] == 'incorrect') {
        return failure(401, 'E-mail ou senha inválidos.');
      }
      return ok(sessionData());
    }
    expect(request.headers['Authorization'], 'Bearer test-token');
    if (request.url.path.endsWith('/auth/logout')) {
      return http.Response('', 204);
    }
    if (request.url.path.endsWith('/manage/points')) {
      return ok([
        {
          'id': 'central',
          'name': 'Centro de Apoio Central',
          'institution': 'Instituição Teste',
          'address': 'Rua Exemplo, 100',
          'hours': '8h às 18h',
        }
      ]);
    }
    if (request.url.path.endsWith('/stock')) return ok([stock()]);
    if (request.url.path.endsWith('/movements')) {
      if (request.method == 'GET') return ok(history.reversed.toList());
      movementRequests++;
      if (connectionLost) throw http.ClientException('connection lost');
      if (stale) {
        return failure(
            409, 'Estoque atualizado por outro gestor. Recarregue o saldo.');
      }
      final body = jsonDecode(request.body);
      expect(body['expectedVersion'], version);
      final before = quantity;
      final q = body['quantity'] as int;
      quantity = body['type'] == 'adjustment'
          ? q
          : quantity + (body['type'] == 'entry' ? q : -q);
      version++;
      history.add({
        'type': body['type'],
        'quantity': q,
        'previous_balance': before,
        'resulting_balance': quantity,
        'note': body['note'] ?? '',
        'user_id': 'manager',
        'user_name': 'Gestor Teste',
        'created_at': '2026-10-14T14:00:00Z'
      });
      return ok({'resultingBalance': quantity, 'version': version}, 201);
    }
    return failure(404, 'Não encontrado.');
  }
}

Future<void> tapVisible(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> login(WidgetTester tester) async {
  await tester.enterText(
      find.byKey(const ValueKey('login-email')), 'gestor@example.test');
  await tester.enterText(
      find.byKey(const ValueKey('login-password')), 'test-password');
  await tapVisible(tester, find.text('Entrar'));
}

void main() {
  testWidgets('sessão expirada na consulta privada retorna ao login',
      (tester) async {
    final api = ManagementApi('http://localhost/api/v1',
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
    final api = ManagementApi('http://localhost/api/v1',
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
    final api =
        ManagementApi('http://localhost/api/v1', client: MockClient((r) async {
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
      await tapVisible(tester, find.text('Gestão'));
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
