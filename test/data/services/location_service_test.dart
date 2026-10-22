import 'dart:async';

import 'package:apoio_app/core/errors/location_failure.dart';
import 'package:apoio_app/data/services/location_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

class TestGeolocator extends GeolocatorPlatform {
  Object? failure;
  double latitude = -23.55;
  LocationSettings? settings;

  @override
  Future<Position> getCurrentPosition(
      {LocationSettings? locationSettings}) async {
    settings = locationSettings;
    if (failure != null) throw failure!;
    return Position(
        latitude: latitude,
        longitude: -46.63,
        timestamp: DateTime(2026),
        accuracy: 5,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0);
  }
}

void main() {
  late TestGeolocator platform;
  late GeolocatorPlatform original;
  const service = GeolocatorLocationService();

  setUp(() {
    original = GeolocatorPlatform.instance;
    platform = TestGeolocator();
    GeolocatorPlatform.instance = platform;
  });
  tearDown(() => GeolocatorPlatform.instance = original);

  test('captura coordenadas pelo plugin com limite de tempo', () async {
    final coordinates = await service.current();
    expect(coordinates.latitude, -23.55);
    expect(coordinates.longitude, -46.63);
    expect(platform.settings!.timeLimit, const Duration(seconds: 20));
  });

  for (final scenario in [
    (const PermissionDeniedException('denied'), 'Permita o acesso'),
    (TimeoutException('timeout'), 'demorou para responder'),
    (const LocationServiceDisabledException(), 'Ative a localização'),
    (UnsupportedError('unsupported'), 'não disponibilizou a localização'),
  ]) {
    test('apresenta orientação para ${scenario.$1.runtimeType}', () async {
      platform.failure = scenario.$1;
      await expectLater(
          service.current(),
          throwsA(isA<LocationFailure>().having(
              (failure) => failure.message, 'message', contains(scenario.$2))));
    });
  }

  test('não aceita coordenadas inválidas recebidas do dispositivo', () async {
    platform.latitude = double.nan;
    await expectLater(service.current(), throwsA(isA<LocationFailure>()));
  });
}
