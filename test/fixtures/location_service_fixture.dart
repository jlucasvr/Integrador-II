import 'dart:async';

import 'package:apoio_app/core/errors/location_failure.dart';
import 'package:apoio_app/data/models/geo_coordinates.dart';
import 'package:apoio_app/data/services/location_service.dart';

class FakeLocationService implements LocationService {
  GeoCoordinates coordinates;
  LocationFailure? failure;
  int calls = 0;
  Completer<GeoCoordinates>? pending;

  FakeLocationService(
      {this.coordinates = const GeoCoordinates(-23.55, -46.63)});

  @override
  Future<GeoCoordinates> current() async {
    calls++;
    if (failure != null) throw failure!;
    return pending?.future ?? coordinates;
  }
}
