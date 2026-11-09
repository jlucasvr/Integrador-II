import 'package:apoio_app/data/models/search_hit.dart';
import 'package:apoio_app/data/models/search_query.dart';

abstract class PointRepository {
  bool get isDemo;
  Future<List<SearchHit>> search(SearchQuery query);
}
