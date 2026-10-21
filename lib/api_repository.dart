import 'dart:convert';
import 'package:http/http.dart' as http;
import 'data.dart';

class ApiPointRepository implements PointRepository {
  final Uri baseUrl;
  final http.Client client;
  ApiPointRepository(String url, {http.Client? client})
      : baseUrl = Uri.parse(url.endsWith('/') ? url : '$url/'),
        client = client ?? http.Client();

  @override
  Future<List<SearchHit>> search(SearchQuery query) async {
    final uri = baseUrl.resolve('points').replace(queryParameters: {
      'q': query.term,
      'location': query.location,
      'intent': query.intent == SearchIntent.help ? 'help' : 'donate',
    });
    final response = await client.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('A consulta à API falhou (${response.statusCode}).');
    }
    final payload =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return (payload['data'] as List).map((entry) {
      final hit = entry as Map<String, dynamic>;
      final p = hit['point'] as Map<String, dynamic>;
      return SearchHit(
          SupportPoint(
            id: p['id'] as String,
            name: p['name'] as String,
            institution: p['institution'] as String,
            address: p['address'] as String,
            hours: p['hours'] as String,
            updatedAt: _date(p['updatedAt'] as String),
            distanceKm: (p['distanceKm'] as num?)?.toDouble(),
            resources: (p['resources'] as List)
                .map((r) => _resource(r as Map<String, dynamic>))
                .toList(),
          ),
          _resource(hit['resource'] as Map<String, dynamic>),
          hit['alternative'] as bool);
    }).toList();
  }

  Resource _resource(Map<String, dynamic> r) => Resource(
        r['name'] as String,
        r['category'] as String,
        r['unit'] as String,
        r['available'] as bool,
        r['acceptsDonation'] as bool,
        r['publicQuantity'] as int?,
        updatedAt: _date(r['updatedAt'] as String),
      );
  String _date(String value) {
    final d = DateTime.tryParse(value)?.toLocal();
    if (d == null) return value.isEmpty ? 'Não informado' : value;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}, às ${two(d.hour)}h${two(d.minute)}';
  }
}
