import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;

/// Mantém vias, nomes e água como referências, sem prédios ou detalhes extras.
vt.Theme organizationMapTheme(vt.Theme base) {
  const hiddenPrefixes = [
    'background',
    'building',
    'poi',
    'housenumber',
    'landuse',
    'landcover',
    'park',
    'railway',
    'boundary',
    'aeroway',
    'airport',
    'highway-shield',
    'road_shield',
  ];
  final background = const vt.ThemeReader().read({
    'layers': [
      {
        'id': 'apoio-background',
        'type': 'background',
        'paint': {'background-color': '#ffffff'},
      },
    ],
  });
  return vt.Theme(
    id: '${base.id}-apoio-light-v1',
    layers: [
      ...background.layers,
      ...base.layers.where(
        (layer) => !hiddenPrefixes.any((prefix) => layer.id.startsWith(prefix)),
      ),
    ],
  );
}
