import 'dart:convert';

import 'package:apoio_app/data/repositories/management_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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
  late final ManagementRepository api = ManagementRepository(
      'http://localhost:3000/api/v1',
      client: MockClient(handle));
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
