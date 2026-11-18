import 'package:apoio_app/ui/support_points/formatters/organization_map_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'mapa branco preserva vias e nomes sem prédios nem pontos de interesse',
    () {
      final original = const vt.ThemeReader().read({
        'layers': [
          {
            'id': 'background',
            'type': 'background',
            'paint': {'background-color': '#ededed'},
          },
          {
            'id': 'highway_minor',
            'type': 'line',
            'source': 'map',
            'source-layer': 'transportation',
            'paint': {'line-color': '#dddddd'},
          },
          {
            'id': 'highway-name-minor',
            'type': 'symbol',
            'source': 'map',
            'source-layer': 'transportation_name',
            'layout': {'text-field': '{name}'},
          },
          {
            'id': 'building',
            'type': 'fill',
            'source': 'map',
            'source-layer': 'building',
          },
          {
            'id': 'poi',
            'type': 'symbol',
            'source': 'map',
            'source-layer': 'poi',
            'layout': {'text-field': '{name}'},
          },
        ],
      });
      final theme = organizationMapTheme(original);
      expect(theme.backgroundColor(15), Colors.white);
      expect(
        theme.layers.map((layer) => layer.id),
        containsAll(['highway_minor', 'highway-name-minor']),
      );
      expect(
        theme.referencedSourceLayers['map'],
        containsAll(['transportation', 'transportation_name']),
      );
      expect(theme.referencedSourceLayers['map'], isNot(contains('building')));
      expect(theme.referencedSourceLayers['map'], isNot(contains('poi')));
    },
  );
}
