import 'package:apoio_app/data/models/geo_coordinates.dart';
import 'package:apoio_app/data/models/search_intent.dart';

class SearchQuery {
  final String term;
  final SearchIntent intent;
  final GeoCoordinates? coordinates;
  final double? radiusKm;
  final bool availableOnly;

  const SearchQuery(this.term, this.intent,
      {this.coordinates, this.radiusKm, this.availableOnly = false});
}
