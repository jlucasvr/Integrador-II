enum InstitutionStatus {
  pending('Pendente'),
  verified('Verificada'),
  suspended('Suspensa');

  const InstitutionStatus(this.label);
  final String label;
}

class MunicipalInstitution {
  MunicipalInstitution(Map<String, dynamic> data)
    : id = data['id'] as String,
      name = data['name'] as String,
      status = InstitutionStatus.values.byName(data['status'] as String);

  final String id, name;
  final InstitutionStatus status;
}
