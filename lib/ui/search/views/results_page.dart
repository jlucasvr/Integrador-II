import 'package:apoio_app/app/navigation.dart';
import 'package:apoio_app/data/models/search_hit.dart';
import 'package:apoio_app/data/models/search_query.dart';
import 'package:apoio_app/data/repositories/management_repository.dart';
import 'package:apoio_app/data/repositories/point_repository.dart';
import 'package:apoio_app/data/services/location_service.dart';
import 'package:apoio_app/ui/core/layout/page_body.dart';
import 'package:apoio_app/ui/core/widgets/app_top_bar.dart';
import 'package:apoio_app/ui/search/view_models/location_view_model.dart';
import 'package:apoio_app/ui/search/view_models/results_view_model.dart';
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
  final ManagementRepository? managementApi;

  const ResultsPage(
      {super.key,
      required this.repository,
      required this.query,
      required this.locationService,
      this.onTermChanged,
      this.managementApi});

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
    _location = LocationViewModel(widget.locationService,
        coordinates: widget.query.coordinates)
      ..addListener(_refresh);
  }

  void _refresh() => setState(() {});

  void _toggleFilters() {
    FocusScope.of(context).unfocus();
    _viewModel.toggleFilters();
  }

  void _search() {
    if (_location.busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final term = _item.text.trim();
    _viewModel.search(term, coordinates: _location.coordinates);
    widget.onTermChanged?.call(term);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _locate() async {
    if (await _location.capture() && mounted) {
      _viewModel.search(_viewModel.query.term,
          coordinates: _location.coordinates);
    }
  }

  void _open(SearchHit hit) =>
      Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => DetailPage(
              point: hit.point, managementApi: widget.managementApi)));

  @override
  void dispose() {
    _location.dispose();
    _viewModel.dispose();
    _item.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppTopBar(
          onManagement: () => openManagement(context, widget.managementApi)),
      bottomNavigationBar: SearchDock(
          formKey: _form,
          controller: _item,
          location: _location,
          onSearch: _search,
          onLocate: _locate),
      body: Builder(
          builder: (context) => Stack(children: [
                SingleChildScrollView(
                    padding: EdgeInsets.only(
                        top: MediaQuery.paddingOf(context).top,
                        bottom: MediaQuery.paddingOf(context).bottom),
                    controller: _scroll,
                    child: PageBody(
                        child: FutureBuilder<List<SearchHit>>(
                            future: _viewModel.request,
                            builder: (context, snapshot) {
                              final loading = snapshot.connectionState !=
                                  ConnectionState.done;
                              final hits =
                                  _viewModel.filter(snapshot.data ?? []);
                              final count = !loading && !snapshot.hasError
                                  ? hits.length
                                  : null;
                              final eyebrow = count == null
                                  ? 'Resultados para'
                                  : count == 1
                                      ? '1 resultado para'
                                      : '$count resultados para';
                              return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(eyebrow,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                    const SizedBox(height: 4),
                                    Text(_viewModel.query.term,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall),
                                    const SizedBox(height: 16),
                                    const SizedBox(height: 12),
                                    if (loading)
                                      const Padding(
                                          padding: EdgeInsets.all(32),
                                          child: Column(children: [
                                            CircularProgressIndicator(),
                                            SizedBox(height: 12),
                                            Text('Buscando pontos…'),
                                          ]))
                                    else if (snapshot.hasError)
                                      Column(children: [
                                        const Text(
                                            'Não foi possível carregar os pontos. Sua busca foi mantida.'),
                                        FilledButton(
                                            onPressed: _viewModel.reload,
                                            child:
                                                const Text('Tentar novamente')),
                                      ])
                                    else if (hits.isEmpty)
                                      const Column(children: [
                                        Icon(Icons.search_off, size: 48),
                                        SizedBox(height: 12),
                                        Text(
                                            'Nenhum ponto encontrado. Altere os filtros ou pesquise outro item na barra abaixo.'),
                                      ])
                                    else ...[
                                      if (hits.every((hit) =>
                                          hit.point.distanceKm == null))
                                        const Text(
                                            'Distâncias não disponíveis para estes pontos.'),
                                      if (hits.first.alternative)
                                        Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                            child: Text(
                                                'Nenhum resultado exato. Alternativas da categoria ${hits.first.resource.category}:')),
                                      ...hits.map((hit) => HitTile(
                                          hit: hit,
                                          intent: _viewModel.query.intent,
                                          onOpen: () => _open(hit))),
                                    ],
                                    const SizedBox(height: 24),
                                  ]);
                            }))),
                // This overlay never contributes to the header or scroll layout.
                if (_viewModel.showFilters) ...[
                  Positioned.fill(
                      child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: _toggleFilters,
                          child: const SizedBox.expand())),
                  Positioned(
                      top: MediaQuery.paddingOf(context).top + 52,
                      left: 0,
                      right: 0,
                      child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 620),
                              child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Align(
                                      alignment: Alignment.centerRight,
                                      child: SizedBox(
                                          width: 320,
                                          child: Material(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surface,
                                              elevation: 6,
                                              shadowColor: Colors.black26,
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                              clipBehavior: Clip.antiAlias,
                                              child: ConstrainedBox(
                                                  constraints: BoxConstraints(
                                                      maxHeight:
                                                          MediaQuery.sizeOf(context)
                                                                  .height *
                                                              .5),
                                                  child: SingleChildScrollView(
                                                      padding: const EdgeInsets.fromLTRB(
                                                          16, 0, 16, 16),
                                                      child: ResultFilters(intent: _viewModel.query.intent, radius: _viewModel.radius, availableOnly: _viewModel.availableOnly, onRadiusChanged: _viewModel.setRadius, onAvailableChanged: _viewModel.setAvailableOnly)))))))))),
                ],
                Positioned(
                    top: MediaQuery.paddingOf(context).top - 8,
                    left: 0,
                    right: 0,
                    child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 620),
                            child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Align(
                                    alignment: Alignment.centerRight,
                                    child: SizedBox(
                                        height: 48,
                                        child: FilterPill(
                                            expanded: _viewModel.showFilters,
                                            onPressed: _toggleFilters))))))),
              ])));
}
