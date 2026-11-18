import 'package:apoio_app/core/utils/normalize.dart';
import 'package:apoio_app/data/models/resource.dart';
import 'package:apoio_app/data/models/search_hit.dart';
import 'package:apoio_app/data/models/search_intent.dart';
import 'package:apoio_app/data/models/search_query.dart';

List<Resource> resultResources(SearchHit hit, SearchQuery query) {
  final term = normalize(query.term);
  final primary = hit.resource;
  return [
    primary,
    ...hit.point.resources.where((resource) {
      if (resource.name == primary.name &&
          resource.category == primary.category &&
          resource.unit == primary.unit) {
        return false;
      }
      if (query.intent == SearchIntent.donate && !resource.acceptsDonation) {
        return false;
      }
      if (query.intent == SearchIntent.help &&
          query.availableOnly &&
          !resource.available) {
        return false;
      }
      return hit.alternative
          ? resource.category == primary.category
          : normalize(resource.name).contains(term) ||
                normalize(resource.category) == term;
    }),
  ];
}
