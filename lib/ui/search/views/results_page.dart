import 'package:apoio_app/app/navigation.dart';
import 'package:apoio_app/data/models/search_hit.dart';
import 'package:apoio_app/data/models/search_query.dart';
import 'package:apoio_app/data/repositories/management_repository.dart';
import 'package:apoio_app/data/repositories/point_repository.dart';
import 'package:apoio_app/data/services/location_service.dart';
import 'package:apoio_app/ui/core/layout/page_body.dart';
import 'package:apoio_app/ui/core/layout/public_layout.dart';
import 'package:apoio_app/ui/core/layout/adaptive_card_grid.dart';
import 'package:apoio_app/ui/core/widgets/app_top_bar.dart';
import 'package:apoio_app/ui/core/widgets/demo_search_notice.dart';
import 'package:apoio_app/ui/search/view_models/location_view_model.dart';
import 'package:apoio_app/ui/search/view_models/results_view_model.dart';
import 'package:apoio_app/ui/search/view_models/result_resources.dart';
import 'package:apoio_app/ui/search/widgets/hit_tile.dart';
import 'package:apoio_app/ui/search/widgets/filter_pill.dart';
import 'package:apoio_app/ui/search/widgets/result_filters.dart';
import 'package:apoio_app/ui/search/widgets/search_dock.dart';
import 'package:apoio_app/ui/support_points/views/detail_page.dart';
import 'package:flutter/material.dart';

class ResultsPage extends StatefulWidget {
  final PointRepository repository;
  final SearchQuery query;
  final LocationService locationService;
  final ValueChanged<String>? onTermChanged;
  final ValueChanged<SearchQuery>? onQueryChanged;
  final ManagementRepository? managementApi;

  const ResultsPage({
    super.key,
    required this.repository,
    required this.query,
    required this.locationService,
    this.onTermChanged,
    this.onQueryChanged,
    this.managementApi,
  });

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  final _form = GlobalKey<FormState>();
  final _scroll = ScrollController();
  late final TextEditingController _item;
  late final ResultsViewModel _viewModel;
  late final LocationViewModel _location;

  @override
  void initState() {
    super.initState();
    _item = TextEditingController(text: widget.query.term);
    _viewModel = ResultsViewModel(widget.repository, widget.query)
      ..addListener(_refresh);
    _location = LocationViewModel(
      widget.locationService,
      coordinates: widget.query.coordinates,
    )..addListener(_refresh);
  }

  void _refresh() {
    widget.onQueryChanged?.call(_viewModel.query);
    setState(() {});
  }

  Future<void> _toggleFilters() async {
    if (_viewModel.showFilters) return;
    FocusScope.of(context).unfocus();
    var radius = _viewModel.query.radiusKm;
    var available = _viewModel.query.availableOnly;
    _viewModel.toggleFilters();
    final apply = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 440,
              maxHeight: MediaQuery.sizeOf(context).height * .85,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Filtre sua busca',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Fechar filtros',
                        onPressed: () => Navigator.pop(context, false),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ResultFilters(
                    intent: _viewModel.query.intent,
                    showRadius: _viewModel.canFilterByDistance,
                    radius: radius,
                    availableOnly: available,
                    onRadiusChanged: (value) => update(() => radius = value),
                    onAvailableChanged: (value) =>
                        update(() => available = value),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Aplicar filtros'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (!mounted) return;
    _viewModel.toggleFilters();
    if (apply == true) {
      _viewModel.applyFilters(
        radius: ResultFilters.radiusFor(radius ?? 0),
        availableOnly: available,
      );
    }
  }

  Future<void> _search() async {
    if (_location.busy || !_form.currentState!.validate()) return;
    if (_location.coordinates == null && !await _location.capture()) return;
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    final term = _item.text.trim();
    _viewModel.search(term, coordinates: _location.coordinates);
    widget.onTermChanged?.call(term);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _locate() async {
    if (await _location.capture() && mounted) {
      _viewModel.search(
        _viewModel.query.term,
        coordinates: _location.coordinates,
      );
    }
  }

  void _open(SearchHit hit) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => DetailPage(
        point: hit.point,
        isDemo: widget.repository.isDemo,
        managementApi: widget.managementApi,
      ),
    ),
  );

  @override
  void dispose() {
    _location.dispose();
    _viewModel.dispose();
    _item.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final headerInset =
        MediaQuery.paddingOf(context).top +
        const AppTopBar().preferredSize.height;
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: AppTopBar(
        maxWidth: PublicLayout.contentWidth(context),
        onManagement: () => openManagement(context, widget.managementApi),
      ),
      bottomNavigationBar: SearchDock(
        maxWidth: PublicLayout.isExpanded(context) ? 800 : 620,
        formKey: _form,
        controller: _item,
        location: _location,
        onSearch: _search,
        onLocate: _locate,
      ),
      body: Builder(
        builder: (context) => Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.only(
                top: headerInset,
                bottom: MediaQuery.paddingOf(context).bottom,
              ),
              controller: _scroll,
              child: PageBody(
                maxWidth: PublicLayout.contentWidth(context),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: FutureBuilder<List<SearchHit>>(
                  future: _viewModel.request,
                  builder: (context, snapshot) {
                    final loading =
                        snapshot.connectionState != ConnectionState.done;
                    final hits = snapshot.data ?? [];
                    final count = !loading && !snapshot.hasError
                        ? hits.length
                        : null;
                    final eyebrow = count == null
                        ? 'Resultados para'
                        : count == 1
                        ? '1 resultado para'
                        : '$count resultados para';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            right: _viewModel.canFilter
                                ? FilterPill.widthFor(context) + 12
                                : 0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                eyebrow,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _viewModel.query.term,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                            ],
                          ),
                        ),
                        if (widget.repository.isDemo) ...[
                          const SizedBox(height: 8),
                          const DemoSearchNotice(),
                        ] else if (!_viewModel.canFilterByDistance) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Distância indisponível. Use sua localização para filtrar por distância.',
                          ),
                        ],
                        const SizedBox(height: 28),
                        if (loading)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Column(
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 12),
                                Text('Buscando pontos…'),
                              ],
                            ),
                          )
                        else if (snapshot.hasError)
                          Column(
                            children: [
                              const Text(
                                'Não foi possível carregar os pontos. Sua busca foi mantida.',
                              ),
                              FilledButton(
                                onPressed: _viewModel.reload,
                                child: const Text('Tentar novamente'),
                              ),
                            ],
                          )
                        else if (hits.isEmpty)
                          const Column(
                            children: [
                              Icon(Icons.search_off, size: 48),
                              SizedBox(height: 12),
                              Text(
                                'Nenhum ponto encontrado. Altere os filtros ou pesquise outro item na barra abaixo.',
                              ),
                            ],
                          )
                        else ...[
                          if (hits.first.alternative)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'Nenhum resultado exato. Alternativas da categoria ${hits.first.resource.category}:',
                              ),
                            ),
                          if (PublicLayout.isExpanded(context))
                            AdaptiveCardGrid(
                              key: const ValueKey('results-grid'),
                              children: hits
                                  .map(
                                    (hit) => HitTile(
                                      hit: hit,
                                      topSpacing: 0,
                                      resources: resultResources(
                                        hit,
                                        _viewModel.query,
                                      ),
                                      intent: _viewModel.query.intent,
                                      onOpen: () => _open(hit),
                                    ),
                                  )
                                  .toList(),
                            )
                          else
                            ...hits.map(
                              (hit) => HitTile(
                                hit: hit,
                                resources: resultResources(
                                  hit,
                                  _viewModel.query,
                                ),
                                intent: _viewModel.query.intent,
                                onOpen: () => _open(hit),
                              ),
                            ),
                        ],
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
              ),
            ),
            if (_viewModel.canFilter)
              Positioned(
                top: headerInset,
                left: 0,
                right: 0,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: PublicLayout.contentWidth(context),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          height: 48,
                          child: FilterPill(
                            expanded: _viewModel.showFilters,
                            onPressed: _toggleFilters,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
