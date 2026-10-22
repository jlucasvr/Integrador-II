import 'dart:async';

import 'package:apoio_app/core/errors/location_failure.dart';
import 'package:apoio_app/data/models/geo_coordinates.dart';
import 'package:geolocator/geolocator.dart';

abstract class LocationService {
  Future<GeoCoordinates> current();
}

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<GeoCoordinates> current() async {
    try {
      // getCurrentPosition requests browser permission when necessary.
      final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 20)));
      if (!position.latitude.isFinite ||
          !position.longitude.isFinite ||
          position.latitude.abs() > 90 ||
          position.longitude.abs() > 180) {
        throw const LocationFailure(
            'Não foi possível obter coordenadas válidas. Tente novamente.');
      }
      return GeoCoordinates(position.latitude, position.longitude);
    } on PermissionDeniedException {
      throw const LocationFailure(
          'Permita o acesso à localização nas configurações do navegador e tente novamente.');
    } on LocationServiceDisabledException {
      throw const LocationFailure(
          'Ative a localização do dispositivo e tente novamente.');
    } on TimeoutException {
      throw const LocationFailure(
          'A localização demorou para responder. Tente novamente.');
    } on UnsupportedError {
      throw const LocationFailure(
          'Este navegador não disponibilizou a localização. Abra em localhost ou HTTPS e tente novamente.');
    }
  }
}
