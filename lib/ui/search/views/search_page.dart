import 'package:apoio_app/app/navigation.dart';
import 'package:apoio_app/data/models/search_intent.dart';
import 'package:apoio_app/data/models/search_query.dart';
import 'package:apoio_app/data/repositories/management_repository.dart';
import 'package:apoio_app/data/repositories/point_repository.dart';
import 'package:apoio_app/data/services/location_service.dart';
import 'package:apoio_app/ui/core/layout/page_body.dart';
import 'package:apoio_app/ui/core/layout/step_layout.dart';
import 'package:apoio_app/ui/core/widgets/app_top_bar.dart';
import 'package:apoio_app/ui/core/widgets/demo_search_notice.dart';
import 'package:apoio_app/ui/search/view_models/location_view_model.dart';
import 'package:apoio_app/ui/search/views/results_page.dart';
import 'package:apoio_app/ui/search/widgets/category_picker.dart';
import 'package:apoio_app/ui/search/widgets/search_dock.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({
    super.key,
    required this.repository,
    required this.locationService,
    this.managementApi,
  });
  final PointRepository repository;
  final ManagementRepository? managementApi;
  final LocationService locationService;
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _form = GlobalKey<FormState>();
  final _item = TextEditingController();
  final _scroll = ScrollController();
  late final LocationViewModel _location;
  SearchIntent _intent = SearchIntent.help;
  SearchQuery? _lastQuery;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _item.addListener(_refresh);
    _location = LocationViewModel(widget.locationService)
      ..addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _go(int step) {
    FocusScope.of(context).unfocus();
    setState(() => _step = step);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _back() {
    if (_step == 0) {
      _go(3);
    } else {
      _go(_step - 1);
    }
  }

  void _nextItem() {
    if (_form.currentState!.validate()) _go(2);
  }

  Future<void> _locate() async {
    await _location.capture();
  }

  Future<void> _search() async {
    if (_location.busy ||
        _item.text.trim().isEmpty ||
        _location.coordinates == null) {
      return;
    }
    final query = SearchQuery(
      _item.text.trim(),
      _intent,
      coordinates: _location.coordinates,
      radiusKm: _lastQuery?.radiusKm,
      availableOnly:
          _intent == SearchIntent.help && (_lastQuery?.availableOnly ?? false),
    );
    _remember(query);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ResultsPage(
          repository: widget.repository,
          locationService: widget.locationService,
          managementApi: widget.managementApi,
          query: query,
          onQueryChanged: _remember,
        ),
      ),
    );
    if (!mounted) return;

    _go(3);
  }

  void _remember(SearchQuery query) {
    _lastQuery = query;
    _item.text = query.term;
    _intent = query.intent;
    _location.coordinates = query.coordinates;
  }

  @override
  void dispose() {
    _location.dispose();
    _item.removeListener(_refresh);
    _item.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerInset =
        MediaQuery.paddingOf(context).top +
        const AppTopBar().preferredSize.height;
    final busy = _location.busy;
    final hasItem = _item.text.trim().isNotEmpty;
    final ready = hasItem && _location.coordinates != null && !busy;
    final canBack = _step > 0 && _step < 3;
    final title = switch (_step) {
      0 => 'Como podemos ajudar?',
      1 =>
        _intent == SearchIntent.help
            ? 'O que você procura?'
            : 'O que você quer doar?',
      2 => 'Onde buscar?',
      _ =>
        _intent == SearchIntent.help
            ? 'Encontre o apoio que você precisa'
            : 'Encontre um lugar para doar',
    };
    return PopScope(
      canPop: !canBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !busy) _back();
      },
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false,
        bottomNavigationBar: _step >= 1
            ? SearchDock(
                formKey: _form,
                controller: _item,
                location: _location,
                onSearch: _step == 1 ? _nextItem : () => _search(),
                actionEnabled: _step == 1 ? hasItem : ready,
                actionIcon: _step == 1
                    ? Icons.arrow_forward_rounded
                    : Icons.search,
                actionLabel: _step == 1
                    ? 'Continuar'
                    : 'Buscar pontos de atendimento',
                onChanged: (_) => _refresh(),
                onLocate: _step >= 2 ? _locate : null,
                locationKey: const ValueKey('wizard-locate'),
                highlightLocation: _step == 2,
                highlightAction: _step == 1 ? hasItem : _step == 2 && ready,
              )
            : null,
        appBar: AppTopBar(
          showLogo: true,
          navigationEnabled: !busy,
          onBack: canBack ? _back : null,
          onManagement: () => openManagement(context, widget.managementApi),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            controller: _scroll,
            padding: EdgeInsets.only(
              top: headerInset,
              bottom: MediaQuery.paddingOf(context).bottom,
            ),
            child: PageBody(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      (constraints.maxHeight -
                              headerInset -
                              20 -
                              MediaQuery.paddingOf(context).bottom)
                          .clamp(0, double.infinity),
                ),
                child: StepLayout(
                  centerContent: _step < 3,
                  header: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_step < 3) ...[
                        Text(
                          'Etapa ${_step + 1} de 3',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: (_step + 1) / 3,
                          minHeight: 9,
                          borderRadius: BorderRadius.circular(20),
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                        ),
                        const SizedBox(height: 24),
                      ],
                      Text(
                        title,
                        style: theme.textTheme.headlineSmall!.copyWith(
                          fontSize: MediaQuery.sizeOf(context).width < 360
                              ? 32
                              : 40,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.8,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(switch (_step) {
                        0 => 'Encontre apoio ou um lugar para doar.',
                        1 => 'Escolha uma categoria ou escreva na busca.',
                        2 =>
                          'Ative sua localização para encontrar pontos próximos de você.',
                        _ => 'Ajuste sua busca aqui mesmo.',
                      }),
                      const SizedBox(height: 16),
                      if (widget.repository.isDemo) ...[
                        const DemoSearchNotice(),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                  content: Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 580),
                        child: _stepContent(context),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepContent(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_step == 0 || _step == 3) ...[
          for (final intent in SearchIntent.values) ...[
            _intentButton(intent),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          if (_step == 0)
            Text(
              'Você não precisa criar uma conta.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
        ],
        if (_step == 1 || _step == 3) ...[
          CategoryPicker(
            selected: _item.text,
            onSelected: (value) => setState(() => _item.text = value),
          ),
          const SizedBox(height: 24),
        ],
        if (_step == 2)
          const Icon(
            Icons.near_me_outlined,
            key: ValueKey('location-step-symbol'),
            size: 56,
          ),
        if (_step == 3) ...[
          OutlinedButton.icon(
            onPressed: () => _go(0),
            icon: const Icon(Icons.route_outlined),
            label: const Text('Voltar ao passo a passo'),
          ),
          if (_lastQuery?.availableOnly == true &&
              _intent == SearchIntent.help) ...[
            const SizedBox(height: 16),
            Text('Somente disponíveis', style: theme.textTheme.bodySmall),
          ],
          if (_lastQuery?.radiusKm case final radius?) ...[
            const SizedBox(height: 8),
            Text(
              'Até ${radius.toStringAsFixed(0)} km',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ],
    );
  }

  Widget _intentButton(SearchIntent intent) {
    final selected = _intent == intent;
    final label = Text(
      intent == SearchIntent.help ? 'Preciso de ajuda' : 'Quero ajudar',
    );
    final icon = Icon(
      intent == SearchIntent.help
          ? Icons.shopping_bag_outlined
          : Icons.volunteer_activism_outlined,
      size: 22,
    );
    void choose() {
      _intent = intent;
      if (_step == 3) {
        setState(() {});
      } else {
        _go(1);
      }
    }

    return Semantics(
      selected: selected,
      child: selected
          ? FilledButton.icon(onPressed: choose, icon: icon, label: label)
          : OutlinedButton.icon(onPressed: choose, icon: icon, label: label),
    );
  }
}
