class ManagedPoint {
  final String id, name, institution, address, hours;
  final String institutionId, region, contact;
  final double latitude, longitude;
  final bool active;
  final int version;
  ManagedPoint(Map<String, dynamic> data)
      : institutionId = data['institution_id'] as String? ?? '',
        region = data['region'] as String? ?? '',
        contact = data['contact'] as String? ?? '',
        latitude = (data['latitude'] as num? ?? 0).toDouble(),
        longitude = (data['longitude'] as num? ?? 0).toDouble(),
        active = data['active'] != 0,
        version = data['version'] as int? ?? 0,
        id = data['id'] as String,
        name = data['name'] as String,
        institution = data['institution'] as String? ?? '',
        address = data['address'] as String,
        hours = data['hours'] as String;
}
