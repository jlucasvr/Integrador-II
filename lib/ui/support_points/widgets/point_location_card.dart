import 'package:apoio_app/data/models/support_point.dart';
import 'package:apoio_app/ui/support_points/formatters/organization_map_theme.dart';
import 'package:apoio_app/ui/support_points/widgets/detail_card.dart';
import 'package:apoio_app/ui/support_points/widgets/point_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;
import 'package:latlong2/latlong.dart';

class PointLocationCard extends StatefulWidget {
  const PointLocationCard({
    super.key,
    required this.point,
    this.mapHeight = 240,
  });
  final SupportPoint point;
  final double mapHeight;
  @override
  State<PointLocationCard> createState() => _PointLocationCardState();
}

class _PointLocationCardState extends State<PointLocationCard> {
  final _controller = MapController();
  bool _failed = false;
  int _attempt = 0;
  Future<vt.Style>? _style;

  @override
  void initState() {
    super.initState();
    if (widget.point.coordinates != null) _style = _readStyle();
  }

  Future<vt.Style> _readStyle() async {
    final style = await vt.StyleReader(
      uri: 'https://tiles.openfreemap.org/styles/positron',
      language: 'pt',
      cache: false,
      logger: vt.Logger.custom(
        onWarn: (message) {
          if (message.startsWith('tile request ')) _tileFailed();
        },
      ),
    ).read();
    return vt.Style(
      theme: organizationMapTheme(style.theme),
      providers: style.providers,
      rasterSources: style.rasterSources,
      sprites: style.sprites,
      glyphs: style.glyphs,
      attributions: style.attributions,
    );
  }

  void _retry() {
    final previous = _style;
    setState(() {
      _failed = false;
      _attempt++;
      _style = _readStyle();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      previous?.then((style) => style.dispose()).ignore();
    });
  }

  void _tileFailed() {
    if (_failed || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_failed) setState(() => _failed = true);
    });
  }

  @override
  void dispose() {
    _style?.then((style) => style.dispose()).ignore();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final point = widget.point;
    final coordinates = point.coordinates;
    final center = coordinates == null
        ? null
        : LatLng(coordinates.latitude, coordinates.longitude);
    final theme = Theme.of(context);
    return DetailCard(
      padding: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (center != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: SizedBox(
                height: widget.mapHeight,
                child: Stack(
                  children: [
                    Semantics(
                      label: 'Mapa da localização de ${point.name}',
                      child: FlutterMap(
                        mapController: _controller,
                        options: MapOptions(
                          backgroundColor: Colors.white,
                          initialCenter: center,
                          initialZoom: 15,
                          minZoom: 3,
                          maxZoom: 18,
                          interactionOptions: const InteractionOptions(
                            flags:
                                InteractiveFlag.drag |
                                InteractiveFlag.pinchZoom |
                                InteractiveFlag.doubleTapZoom,
                          ),
                        ),
                        children: [
                          FutureBuilder<vt.Style>(
                            key: ValueKey(_attempt),
                            future: _style,
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                _tileFailed();
                                return const SizedBox.shrink();
                              }
                              final style = snapshot.data;
                              if (snapshot.connectionState !=
                                      ConnectionState.done ||
                                  style == null) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    semanticsLabel: 'Carregando mapa',
                                  ),
                                );
                              }
                              return vt.VectorTileLayer(
                                theme: style.theme,
                                tileProviders: style.providers,
                                rasterSources: style.rasterSources,
                                sprites: style.sprites,
                                glyphs: style.glyphs,
                              );
                            },
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: center,
                                width: 52,
                                height: 60,
                                alignment: Alignment.topCenter,
                                child: Tooltip(
                                  message: point.name,
                                  child: const Icon(
                                    Icons.location_on_rounded,
                                    size: 52,
                                    color: Color(0xff292929),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: theme.colorScheme.outline),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on_outlined, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Local de atendimento',
                                style: TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!_failed)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Column(
                          children: [
                            _mapButton(
                              Icons.add,
                              'Aproximar mapa',
                              () => _controller.move(
                                _controller.camera.center,
                                (_controller.camera.zoom + 1).clamp(3, 18),
                              ),
                            ),
                            const SizedBox(height: 4),
                            _mapButton(
                              Icons.remove,
                              'Afastar mapa',
                              () => _controller.move(
                                _controller.camera.center,
                                (_controller.camera.zoom - 1).clamp(3, 18),
                              ),
                            ),
                            const SizedBox(height: 4),
                            _mapButton(
                              Icons.my_location,
                              'Centralizar organização',
                              () => _controller.move(center, 15),
                            ),
                          ],
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: ColoredBox(
                        color: Colors.white,
                        child: Wrap(
                          children: [
                            _attribution(
                              'OpenFreeMap',
                              'https://openfreemap.org/',
                            ),
                            _attribution(
                              '© OpenMapTiles',
                              'https://openmaptiles.org/',
                            ),
                            _attribution(
                              '© OpenStreetMap',
                              'https://www.openstreetmap.org/copyright',
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_failed)
                      Positioned.fill(
                        child: ColoredBox(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.map_outlined, size: 32),
                                const SizedBox(height: 8),
                                const Text(
                                  'Não foi possível carregar o mapa.',
                                  textAlign: TextAlign.center,
                                ),
                                OutlinedButton.icon(
                                  onPressed: _retry,
                                  icon: const Icon(Icons.refresh, size: 18),
                                  label: const Text('Tentar novamente'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            point.address.isEmpty
                                ? 'Endereço não informado'
                                : point.address,
                            style: theme.textTheme.titleSmall,
                          ),
                          if (point.region.isNotEmpty)
                            Text(
                              point.region,
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (center == null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Localização no mapa ainda não informada.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: center != null || point.address.isNotEmpty
                      ? () => openPointLink(context, mapsDirections(point))
                      : null,
                  icon: const Icon(Icons.directions_outlined, size: 20),
                  label: const Text('Abrir no mapa'),
                ),
                if (point.address.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(
                          text: [
                            point.address,
                            point.region,
                          ].where((s) => s.isNotEmpty).join(', '),
                        ),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Endereço copiado.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy_outlined, size: 16),
                    label: const Text('Copiar endereço'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _attribution(String label, String url) => TextButton(
    style: TextButton.styleFrom(
      minimumSize: const Size(44, 44),
      side: BorderSide.none,
      backgroundColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    ),
    onPressed: () => openPointLink(context, Uri.parse(url)),
    child: Text(label, style: const TextStyle(fontSize: 9)),
  );

  Widget _mapButton(IconData icon, String tooltip, VoidCallback onPressed) =>
      IconButton.filledTonal(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon, size: 20),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xff292929),
          minimumSize: const Size.square(48),
          side: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
      );
}
