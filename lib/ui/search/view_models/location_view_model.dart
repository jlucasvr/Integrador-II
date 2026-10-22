import 'package:apoio_app/core/errors/location_failure.dart';
import 'package:apoio_app/data/models/geo_coordinates.dart';
import 'package:apoio_app/data/services/location_service.dart';
import 'package:flutter/foundation.dart';

class LocationViewModel extends ChangeNotifier {
  final LocationService _service;
  GeoCoordinates? coordinates;
  bool busy = false;
  String? error;
  bool _disposed = false;

  LocationViewModel(this._service, {this.coordinates});

  Future<bool> capture() async {
    if (busy) return false;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final result = await _service.current();
      if (_disposed) return false;
      coordinates = result;
      return true;
    } on LocationFailure catch (failure) {
      error = failure.message;
      return false;
    } catch (_) {
      error =
          'Localização indisponível. Verifique a permissão do navegador e tente novamente.';
      return false;
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
