import 'package:apoio_app/data/models/search_hit.dart';
import 'package:apoio_app/data/models/geo_coordinates.dart';
import 'package:apoio_app/data/models/search_intent.dart';
import 'package:apoio_app/data/models/search_query.dart';
import 'package:apoio_app/data/repositories/point_repository.dart';
import 'package:flutter/foundation.dart';

class ResultsViewModel extends ChangeNotifier {
  final PointRepository _repository;
  SearchQuery _query;
  SearchQuery get query => _query;
  late Future<List<SearchHit>> request;
  bool showFilters = false;
  bool get canFilterByDistance =>
      !_repository.isDemo && query.coordinates != null;
  bool get canFilter =>
      canFilterByDistance || query.intent == SearchIntent.help;

  ResultsViewModel(this._repository, this._query) {
    request = _repository.search(query);
  }

  void reload() {
    request = _repository.search(query);
    notifyListeners();
  }

  void toggleFilters() {
    showFilters = !showFilters;
    notifyListeners();
  }

  void search(String term, {GeoCoordinates? coordinates}) {
    _query = SearchQuery(term, query.intent,
        coordinates: coordinates ?? query.coordinates,
        radiusKm: query.radiusKm,
        availableOnly: query.availableOnly);
    reload();
  }

  void setRadius(double? value) {
    if (!canFilterByDistance || value == query.radiusKm) return;
    _query = SearchQuery(query.term, query.intent,
        coordinates: query.coordinates,
        radiusKm: value,
        availableOnly: query.availableOnly);
    reload();
  }

  void setAvailableOnly(bool value) {
    if (query.intent != SearchIntent.help || value == query.availableOnly) {
      return;
    }
    _query = SearchQuery(query.term, query.intent,
        coordinates: query.coordinates,
        radiusKm: query.radiusKm,
        availableOnly: value);
    reload();
  }
}
