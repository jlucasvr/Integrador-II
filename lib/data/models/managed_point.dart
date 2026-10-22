class ManagedPoint {
  final String id, name, institution, address, hours;
  ManagedPoint(Map<String, dynamic> data)
      : id = data['id'] as String,
        name = data['name'] as String,
        institution = data['institution'] as String? ?? '',
        address = data['address'] as String,
        hours = data['hours'] as String;
}
