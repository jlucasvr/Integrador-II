import 'dart:convert';

import 'package:apoio_app/data/models/search_intent.dart';
import 'package:apoio_app/data/models/search_query.dart';
import 'package:http/http.dart' as http;

class PointApiService {
  final Uri baseUrl;
  final http.Client _client;

  PointApiService(String url, {http.Client? client})
      : baseUrl = Uri.parse(url.endsWith('/') ? url : '$url/'),
        _client = client ?? http.Client();

  Future<List<Map<String, dynamic>>> search(SearchQuery query) async {
    final uri = baseUrl.resolve('points').replace(queryParameters: {
      'q': query.term,
      'lat': query.coordinates.latitude.toString(),
      'lon': query.coordinates.longitude.toString(),
      'intent': query.intent == SearchIntent.help ? 'help' : 'donate',
    });
    final response =
        await _client.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('A consulta à API falhou (${response.statusCode}).');
    }
    final payload =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return (payload['data'] as List).cast<Map<String, dynamic>>();
  }

  void dispose() => _client.close();
}
