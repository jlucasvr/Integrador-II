import 'package:apoio_app/data/models/resource.dart';
import 'package:apoio_app/data/models/support_point.dart';

class SearchHit {
  final SupportPoint point;
  final Resource resource;
  final bool alternative;
  const SearchHit(this.point, this.resource, this.alternative);
}
