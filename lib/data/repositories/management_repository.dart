import 'dart:async';

import 'package:apoio_app/core/errors/management_failure.dart';
import 'package:apoio_app/data/models/account_session.dart';
import 'package:apoio_app/data/models/managed_point.dart';
import 'package:apoio_app/data/models/movement_type.dart';
import 'package:apoio_app/data/models/stock_item.dart';
import 'package:apoio_app/data/models/stock_movement.dart';
import 'package:apoio_app/data/services/management_api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ManagementRepository extends ChangeNotifier {
  final Uri baseUrl;
  final ManagementApiService _service;
  AccountSession? _session;
  bool _closed = false;
  String? signInNotice;
  AccountSession? get session => _session;
  ManagementRepository(String url, {http.Client? client})
      : baseUrl = Uri.parse(url.endsWith('/') ? url : '$url/'),
        _service = ManagementApiService(url, client: client);

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
      return await _service.request(method, path,
          body: body, token: authorized ? current!.token : null);
    } on ManagementFailure catch (error) {
      if (error.status == 401 && authorized) _expire(current);
      rethrow;
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
    _service.dispose();
    super.dispose();
  }
}
