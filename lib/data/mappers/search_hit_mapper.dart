import 'package:apoio_app/data/models/resource.dart';
import 'package:apoio_app/data/models/search_hit.dart';
import 'package:apoio_app/data/models/support_point.dart';

class SearchHitMapper {
  SearchHit fromJson(Map<String, dynamic> hit) {
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
