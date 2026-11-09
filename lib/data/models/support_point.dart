import 'package:apoio_app/data/models/resource.dart';

class SupportPoint {
  final String id, name, institution, address, hours, updatedAt;
  final String contact, region;
  final double? distanceKm;
  final List<Resource> resources;
  const SupportPoint(
      {required this.id,
      this.contact = '',
      this.region = '',
      required this.name,
      required this.institution,
      required this.address,
      required this.hours,
      required this.updatedAt,
      required this.distanceKm,
      required this.resources});
}
