import 'package:apoio_app/app/navigation.dart';
import 'package:apoio_app/data/models/search_intent.dart';
import 'package:apoio_app/data/models/search_query.dart';
import 'package:apoio_app/data/repositories/management_repository.dart';
import 'package:apoio_app/data/repositories/point_repository.dart';
import 'package:apoio_app/data/services/location_service.dart';
import 'package:apoio_app/ui/core/layout/page_body.dart';
import 'package:apoio_app/ui/core/widgets/app_top_bar.dart';
import 'package:apoio_app/ui/core/widgets/demo_search_notice.dart';
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

  Future<void> _search({bool withoutLocation = false}) async {
    if (_location.busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final useLocation = !withoutLocation && !widget.repository.isDemo;
    if (useLocation &&
        _location.coordinates == null &&
        !await _location.capture()) {
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => ResultsPage(
            repository: widget.repository,
            locationService: widget.locationService,
            query: SearchQuery(_item.text.trim(), _intent,
                coordinates: useLocation ? _location.coordinates : null),
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
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 600 || size.height < 760;
    final options = HomeSearchOptions(
        intent: _intent,
        onIntentChanged: (value) => setState(() => _intent = value),
        onCategorySelected: (category) => _item.text = category);
    return Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: false,
        resizeToAvoidBottomInset: false,
        appBar: AppTopBar(
            showLogo: true,
            onManagement: () => openManagement(context, widget.managementApi)),
        bottomNavigationBar: SearchDock(
            formKey: _form,
            controller: _item,
            location: _location,
            onSearch: _search,
            onSearchWithoutLocation: widget.repository.isDemo
                ? null
                : () => _search(withoutLocation: true),
            controls: compact ? null : options,
            onLocate: widget.repository.isDemo ? null : _location.capture),
        body: Builder(
            builder: (context) => SingleChildScrollView(
                padding: EdgeInsets.only(
                    top: 0, bottom: MediaQuery.paddingOf(context).bottom),
                child: PageBody(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                      Text('Como podemos ajudar?',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall!
                              .copyWith(
                                  fontSize: size.width < 360 ? 40 : 48,
                                  height: 1.15,
                                  letterSpacing: -1,
                                  fontWeight: FontWeight.w800)),
                      const SizedBox(height: 16),
                      if (widget.repository.isDemo) ...[
                        const DemoSearchNotice(),
                        const SizedBox(height: 8),
                      ],
                      const Text('Encontre recursos ou um lugar para doar.',
                          style: TextStyle(fontSize: 18, height: 1.5)),
                      if (!widget.repository.isDemo) ...[
                        const SizedBox(height: 24),
                        const Text(
                            'Use sua localização para ver pontos próximos.'),
                      ],
                      if (compact) ...[
                        const SizedBox(height: 24),
                        options,
                      ],
                    ])))));
  }
}
