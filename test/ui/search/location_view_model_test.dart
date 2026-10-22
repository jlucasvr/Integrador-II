import 'dart:async';

import 'package:apoio_app/data/models/geo_coordinates.dart';
import 'package:apoio_app/ui/search/view_models/location_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/location_service_fixture.dart';

void main() {
  test('descarta uma captura que termina depois da saída da tela', () async {
    final service = FakeLocationService()
      ..pending = Completer<GeoCoordinates>();
    final model = LocationViewModel(service);
    final capture = model.capture();
    model.dispose();
    service.pending!.complete(const GeoCoordinates(-23.55, -46.63));
    expect(await capture, isFalse);
    expect(model.coordinates, isNull);
  });
}
