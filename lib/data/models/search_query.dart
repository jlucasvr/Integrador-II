import 'package:apoio_app/data/models/geo_coordinates.dart';
import 'package:apoio_app/data/models/search_intent.dart';

class SearchQuery {
  final String term;
  final SearchIntent intent;
  final GeoCoordinates coordinates;

  const SearchQuery(this.term, this.intent, {required this.coordinates});
}
