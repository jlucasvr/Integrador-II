import 'package:apoio_app/data/repositories/api_point_repository.dart';
import 'package:apoio_app/data/repositories/management_repository.dart';
import 'package:apoio_app/data/repositories/mock_point_repository.dart';
import 'package:apoio_app/data/repositories/point_repository.dart';

class AppDependencies {
  final PointRepository points;
  final ManagementRepository? management;

  AppDependencies._({required this.points, this.management});

  factory AppDependencies.fromEnvironment() {
    const configuredUrl = String.fromEnvironment('API_BASE_URL');
    final apiUrl = configuredUrl.trim();
    const mockSearch =
        bool.fromEnvironment('MOCK_SEARCH', defaultValue: configuredUrl == '');
    if (!mockSearch && apiUrl.isEmpty) {
      throw StateError('Defina API_BASE_URL para iniciar no modo API.');
    }
    return AppDependencies._(
      points: mockSearch ? MockPointRepository() : ApiPointRepository(apiUrl),
      management: apiUrl.isEmpty ? null : ManagementRepository(apiUrl),
    );
  }

  void dispose() {
    management?.dispose();
    final repository = points;
    if (repository is ApiPointRepository) repository.dispose();
  }
}
