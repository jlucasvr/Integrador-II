import 'package:apoio_app/app/navigation.dart';
import 'package:apoio_app/data/models/search_intent.dart';
import 'package:apoio_app/data/models/search_query.dart';
import 'package:apoio_app/data/repositories/management_repository.dart';
import 'package:apoio_app/data/repositories/point_repository.dart';
import 'package:apoio_app/data/services/location_service.dart';
import 'package:apoio_app/ui/core/layout/page_body.dart';
import 'package:apoio_app/ui/core/widgets/app_top_bar.dart';
import 'package:apoio_app/ui/search/view_models/location_view_model.dart';
import 'package:apoio_app/ui/search/views/results_page.dart';
import 'package:apoio_app/ui/search/widgets/home_search_options.dart';
import 'package:apoio_app/ui/search/widgets/search_dock.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  final PointRepository repository;
  final ManagementRepository? managementApi;
  final LocationService locationService;

  const SearchPage(
      {super.key,
      required this.repository,
      required this.locationService,
      this.managementApi});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _form = GlobalKey<FormState>();
  final _item = TextEditingController(text: 'Água potável');
  late final LocationViewModel _location;
  SearchIntent _intent = SearchIntent.help;

  @override
  void initState() {
    super.initState();
    _location = LocationViewModel(widget.locationService)
      ..addListener(_refresh);
  }

  void _refresh() => setState(() {});

  Future<void> _search() async {
    if (_location.busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    if (_location.coordinates == null && !await _location.capture()) return;
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => ResultsPage(
            repository: widget.repository,
            locationService: widget.locationService,
            query: SearchQuery(_item.text.trim(), _intent,
                coordinates: _location.coordinates!),
            managementApi: widget.managementApi,
            onTermChanged: (term) => _item.text = term)));
  }

  @override
  void dispose() {
    _location.dispose();
    _item.dispose();
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
          controls: HomeSearchOptions(
              intent: _intent,
              onIntentChanged: (value) => setState(() => _intent = value),
              onCategorySelected: (category) => _item.text = category),
          onLocate: _location.capture),
      body: Builder(
          builder: (context) => SingleChildScrollView(
              padding: EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top,
                  bottom: MediaQuery.paddingOf(context).bottom),
              child: PageBody(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    Text('Como podemos ajudar?',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall!
                            .copyWith(
                                fontSize: 48,
                                height: 1.15,
                                letterSpacing: -1,
                                fontWeight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    const Text(
                        'Encontre recursos ou um lugar para doar perto de você.',
                        style: TextStyle(fontSize: 18, height: 1.5)),
                    const SizedBox(height: 24),
                    const Text(
                        'Use sua localização para encontrar pontos de atendimento. Ao buscar, solicitaremos acesso à localização se necessário.'),
                  ])))));
}
