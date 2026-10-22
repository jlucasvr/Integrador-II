import 'package:apoio_app/data/mappers/search_hit_mapper.dart';
import 'package:apoio_app/data/models/search_hit.dart';
import 'package:apoio_app/data/models/search_query.dart';
import 'package:apoio_app/data/repositories/point_repository.dart';
import 'package:apoio_app/data/services/point_api_service.dart';
import 'package:http/http.dart' as http;

class ApiPointRepository implements PointRepository {
  @override
  bool get locationFilteringEnabled => true;
  final PointApiService _service;
  final SearchHitMapper _mapper = SearchHitMapper();

  ApiPointRepository(String url, {http.Client? client})
      : _service = PointApiService(url, client: client);

  @override
  Future<List<SearchHit>> search(SearchQuery query) async =>
      (await _service.search(query)).map(_mapper.fromJson).toList();

  void dispose() => _service.dispose();
}
