import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ManagementFailure implements Exception {
  final int status;
  final String message;
  final bool uncertain;
  const ManagementFailure(this.status, this.message, {this.uncertain = false});
  @override
  String toString() => message;
}

class AccountSession {
  final String token, id, name, email, role;
  final DateTime expiresAt;
  AccountSession(Map<String, dynamic> data)
      : token = data['token'] as String,
        expiresAt = DateTime.parse(data['expiresAt'] as String),
        id = data['user']['id'] as String,
        name = data['user']['name'] as String,
        email = data['user']['email'] as String,
        role = data['user']['role'] as String;
}

class ManagedPoint {
  final String id, name, institution, address, hours;
  ManagedPoint(Map<String, dynamic> data)
      : id = data['id'] as String,
        name = data['name'] as String,
        institution = data['institution'] as String? ?? '',
        address = data['address'] as String,
        hours = data['hours'] as String;
}

class StockItem {
  final String id, name, category, unit;
  final DateTime updatedAt;
  final int quantity, version;
  final bool publicQuantity, visible, distributable, acceptsDonation;
  StockItem(Map<String, dynamic> data)
      : id = data['id'] as String,
        name = data['name'] as String,
        category = data['category'] as String,
        unit = data['unit'] as String,
        quantity = data['quantity'] as int,
        version = data['version'] as int,
        updatedAt = DateTime.parse(data['updated_at'] as String),
        publicQuantity = data['public_quantity'] == 1,
        visible = data['visible'] == 1,
        distributable = data['distributable'] == 1,
        acceptsDonation = data['accepts_donation'] == 1;
}

class StockMovement {
  final String type, note, responsible;
  final int quantity, previousBalance, resultingBalance;
  final DateTime createdAt;
  StockMovement(Map<String, dynamic> data)
      : type = data['type'] as String,
        note = data['note'] as String,
        responsible = data['user_name'] as String? ?? data['user_id'] as String,
        quantity = data['quantity'] as int,
        previousBalance = data['previous_balance'] as int,
        resultingBalance = data['resulting_balance'] as int,
        createdAt = DateTime.parse(data['created_at'] as String);
}

enum MovementType { entry, exit, adjustment }

extension MovementLabel on MovementType {
  String get label => switch (this) {
        MovementType.entry => 'Entrada',
        MovementType.exit => 'Saída',
        MovementType.adjustment => 'Ajuste',
      };
}

class ManagementApi extends ChangeNotifier {
  final Uri baseUrl;
  final http.Client _client;
  AccountSession? _session;
  bool _closed = false;
  String? signInNotice;
  AccountSession? get session => _session;
  ManagementApi(String url, {http.Client? client})
      : baseUrl = Uri.parse(url.endsWith('/') ? url : '$url/'),
        _client = client ?? http.Client();

  Future<dynamic> _request(String method, String path,
      {Map<String, dynamic>? body, bool authorized = true}) async {
    final current = _session;
    if (authorized &&
        (current == null || !current.expiresAt.isAfter(DateTime.now()))) {
      _expire(current);
      throw const ManagementFailure(
          401, 'Sua sessão expirou. Entre novamente.');
    }
    try {
      final request = http.Request(method, baseUrl.resolve(path));
      request.headers['Content-Type'] = 'application/json';
      if (authorized) {
        request.headers['Authorization'] = 'Bearer ${current!.token}';
      }
      if (body != null) request.body = jsonEncode(body);
      final response = await (() async {
        return http.Response.fromStream(await _client.send(request));
      })()
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 204) return null;
      dynamic payload;
      try {
        payload = jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        payload = null;
      }
      if (response.statusCode >= 400) {
        if (response.statusCode == 401 && authorized) _expire(current);
        final message = response.statusCode == 429
            ? 'Muitas tentativas de acesso. Aguarde e tente novamente.'
            : payload is Map && payload['error'] is Map
                ? payload['error']['message'] as String
                : 'Não foi possível concluir a operação (${response.statusCode}).';
        throw ManagementFailure(response.statusCode, message);
      }
      if (payload is! Map || !payload.containsKey('data')) {
        throw const ManagementFailure(
            502, 'O servidor retornou uma resposta inválida.',
            uncertain: true);
      }
      return payload['data'];
    } on TimeoutException {
      throw const ManagementFailure(
          0, 'O servidor demorou para responder. Verifique sua conexão.',
          uncertain: true);
    } on http.ClientException {
      throw const ManagementFailure(
          0, 'Não foi possível conectar à API. Verifique se ela está iniciada.',
          uncertain: true);
    }
  }

  void _expire(AccountSession? expected) {
    if (_session != expected) return;
    _session = null;
    signInNotice = 'Sua sessão expirou. Entre novamente.';
    scheduleMicrotask(() {
      if (!_closed) notifyListeners();
    });
  }

  Future<void> login(String email, String password) async {
    final result = await _request('POST', 'auth/login',
        authorized: false, body: {'email': email.trim(), 'password': password});
    _session = AccountSession(result as Map<String, dynamic>);
    signInNotice = null;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      if (_session != null) await _request('POST', 'auth/logout');
    } finally {
      _session = null;
      signInNotice = null;
      notifyListeners();
    }
  }

  Future<List<ManagedPoint>> points() async =>
      (await _request('GET', 'manage/points') as List)
          .map((p) => ManagedPoint(p as Map<String, dynamic>))
          .toList();
  Future<List<StockItem>> stock(String pointId) async => (await _request(
          'GET', 'manage/points/${Uri.encodeComponent(pointId)}/stock') as List)
      .map((s) => StockItem(s as Map<String, dynamic>))
      .toList();
  Future<void> move(
      StockItem item, MovementType type, int quantity, String note) async {
    await _request(
        'POST', 'manage/stocks/${Uri.encodeComponent(item.id)}/movements',
        body: {
          'type': type.name,
          'quantity': quantity,
          'expectedVersion': item.version,
          if (note.trim().isNotEmpty) 'note': note.trim(),
        });
  }

  Future<List<StockMovement>> history(String stockId) async => (await _request(
              'GET', 'manage/stocks/${Uri.encodeComponent(stockId)}/movements')
          as List)
      .map((m) => StockMovement(m as Map<String, dynamic>))
      .toList();
  @override
  void dispose() {
    _closed = true;
    _client.close();
    super.dispose();
  }
}
