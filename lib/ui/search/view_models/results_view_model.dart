import 'package:apoio_app/data/models/search_hit.dart';
import 'package:apoio_app/data/models/geo_coordinates.dart';
import 'package:apoio_app/data/models/search_query.dart';
import 'package:apoio_app/data/repositories/point_repository.dart';
import 'package:flutter/foundation.dart';

class ResultsViewModel extends ChangeNotifier {
  final PointRepository _repository;
  SearchQuery _query;
  SearchQuery get query => _query;
  late Future<List<SearchHit>> request;
  bool availableOnly = false;
  bool showFilters = false;
  double? radius;

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
        coordinates: coordinates ?? query.coordinates);
    reload();
  }

  void setRadius(double? value) {
    radius = value;
    notifyListeners();
  }

  void setAvailableOnly(bool value) {
    availableOnly = value;
    notifyListeners();
  }

  List<SearchHit> filter(List<SearchHit> hits) => hits
      .where((hit) =>
          (!_repository.locationFilteringEnabled ||
              radius == null ||
              (hit.point.distanceKm != null &&
                  hit.point.distanceKm! <= radius!)) &&
          (!availableOnly || hit.resource.available))
      .toList()
    ..sort((a, b) {
      final availability = (b.resource.available ? 1 : 0)
          .compareTo(a.resource.available ? 1 : 0);
      if (availability != 0) return availability;
      return (a.point.distanceKm ?? double.infinity)
          .compareTo(b.point.distanceKm ?? double.infinity);
    });
}
