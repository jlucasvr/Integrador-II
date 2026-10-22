import 'package:apoio_app/data/repositories/api_point_repository.dart';
import 'package:apoio_app/data/repositories/management_repository.dart';
import 'package:apoio_app/data/repositories/mock_point_repository.dart';
import 'package:apoio_app/data/repositories/point_repository.dart';
import 'package:flutter/foundation.dart';

class AppDependencies {
  final PointRepository points;
  final ManagementRepository? management;

  AppDependencies._({required this.points, this.management});

  factory AppDependencies.fromEnvironment() {
    const apiUrl = String.fromEnvironment('API_BASE_URL');
    // Temporary visual testing: keep geolocation capture, but use local results.
    const mockSearch =
        bool.fromEnvironment('MOCK_SEARCH', defaultValue: kDebugMode);
    return AppDependencies._(
      points: mockSearch || apiUrl.isEmpty
          ? MockPointRepository(locationFilteringEnabled: !mockSearch)
          : ApiPointRepository(apiUrl),
      management: apiUrl.isEmpty ? null : ManagementRepository(apiUrl),
    );
  }

  void dispose() {
    management?.dispose();
    final repository = points;
    if (repository is ApiPointRepository) repository.dispose();
  }
}
