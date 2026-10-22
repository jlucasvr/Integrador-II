import 'dart:async';
import 'dart:convert';

import 'package:apoio_app/core/errors/management_failure.dart';
import 'package:http/http.dart' as http;

class ManagementApiService {
  final Uri baseUrl;
  final http.Client _client;
  ManagementApiService(String url, {http.Client? client})
      : baseUrl = Uri.parse(url.endsWith('/') ? url : '$url/'),
        _client = client ?? http.Client();
  Future<dynamic> request(String method, String path,
      {Map<String, dynamic>? body, String? token}) async {
    try {
      final request = http.Request(method, baseUrl.resolve(path));
      request.headers['Content-Type'] = 'application/json';
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
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

  void dispose() => _client.close();
}
