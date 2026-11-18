import 'package:apoio_app/data/models/resource.dart';
import 'package:apoio_app/data/models/geo_coordinates.dart';

class SupportPoint {
  final String id, name, institution, address, hours, updatedAt;
  final String contact, region;
  final double? distanceKm;
  final List<Resource> resources;
  final GeoCoordinates? coordinates;
  const SupportPoint({
    required this.id,
    this.contact = '',
    this.region = '',
    this.coordinates,
    required this.name,
    required this.institution,
    required this.address,
    required this.hours,
    required this.updatedAt,
    required this.distanceKm,
    required this.resources,
  });
}
