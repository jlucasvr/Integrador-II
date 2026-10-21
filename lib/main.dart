import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'data.dart';
import 'api_repository.dart';
import 'management_api.dart';
import 'management_page.dart';
import 'wireframe_theme.dart';

void main() {
  const apiUrl = String.fromEnvironment('API_BASE_URL');
  runApp(ApoioApp(
      managementApi: apiUrl.isEmpty ? null : ManagementApi(apiUrl),
      repository:
          apiUrl.isEmpty ? MockPointRepository() : ApiPointRepository(apiUrl)));
}

class ApoioApp extends StatelessWidget {
  final PointRepository repository;
  final ManagementApi? managementApi;
  const ApoioApp({super.key, required this.repository, this.managementApi});
  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'Encontrar apoio',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: wireframeTheme(),
      home: SearchPage(repository: repository, managementApi: managementApi));
}

class PageBody extends StatelessWidget {
  final Widget child;
  const PageBody({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Padding(padding: const EdgeInsets.all(20), child: child)));
}

class SearchPage extends StatefulWidget {
  final PointRepository repository;
  final ManagementApi? managementApi;
  const SearchPage({super.key, required this.repository, this.managementApi});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _form = GlobalKey<FormState>();
  final _item = TextEditingController(text: 'Água potável');
  final _location = TextEditingController(text: 'Centro, Cidade Exemplo');
  SearchIntent _intent = SearchIntent.help;
  String? _locationNotice;
  @override
  void dispose() {
    _item.dispose();
    _location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Plataforma de apoio'), actions: [
        const Text('Consulta pública', style: TextStyle(fontSize: 12)),
        TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => ManagementPage(api: widget.managementApi))),
            child: const Text('Gestão')),
      ]),
      body: SingleChildScrollView(
          child: PageBody(
              child: Form(
                  key: _form,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Como podemos ajudar?',
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        const Text('Encontre recursos ou um lugar para doar.'),
                        const SizedBox(height: 24),
                        SegmentedButton<SearchIntent>(
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(
                                  value: SearchIntent.help,
                                  label: Text('Preciso de ajuda')),
                              ButtonSegment(
                                  value: SearchIntent.donate,
                                  label: Text('Quero doar'))
                            ],
                            selected: {_intent},
                            onSelectionChanged: (v) =>
                                setState(() => _intent = v.first)),
                        const SizedBox(height: 24),
                        const FieldHeading('Qual item você procura?'),
                        TextFormField(
                            controller: _item,
                            decoration: const InputDecoration(
                                labelText: 'Item ou categoria',
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.never,
                                hintText: 'Ex.: água, alimentos, cobertor'),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Informe um item ou categoria.'
                                : null),
                        const SizedBox(height: 16),
                        const FieldHeading('Ou escolha uma categoria'),
                        Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: ['Água', 'Alimentos', 'Higiene', 'Abrigo']
                                .map((c) => OutlinedButton(
                                    child: Text(c,
                                        style: const TextStyle(fontSize: 12)),
                                    onPressed: () => _item.text = c))
                                .toList()),
                        const SizedBox(height: 24),
                        const FieldHeading('Onde você está?'),
                        OutlinedButton(
                            child: const Text('Usar minha localização'),
                            onPressed: () => setState(() => _locationNotice =
                                'Localização automática indisponível nesta demonstração. Informe um bairro ou cidade.')),
                        if (_locationNotice != null)
                          Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(_locationNotice!)),
                        const SizedBox(height: 12),
                        const Text('Ou informe um bairro ou cidade',
                            style: TextStyle(fontSize: 12)),
                        const SizedBox(height: 8),
                        TextFormField(
                            controller: _location,
                            decoration: const InputDecoration(
                                labelText: 'Bairro ou cidade',
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.never,
                                hintText: 'Bairro ou cidade'),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Informe um bairro ou cidade.'
                                : null),
                        const SizedBox(height: 24),
                        FilledButton(
                            onPressed: () {
                              if (_form.currentState!.validate()) {
                                Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                        builder: (_) => ResultsPage(
                                            repository: widget.repository,
                                            query: SearchQuery(
                                                _item.text.trim(),
                                                _location.text.trim(),
                                                _intent))));
                              }
                            },
                            child: const Text('Buscar pontos de atendimento')),
                        const SizedBox(height: 24),
                        const Text(
                            'Você pode consultar ajuda e doações sem criar uma conta.',
                            style: TextStyle(fontSize: 12)),
                        const SizedBox(height: 12),
                        const DemoNotice(),
                      ])))));
}

class FieldHeading extends StatelessWidget {
  final String text;
  const FieldHeading(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)));
}

class DemoNotice extends StatelessWidget {
  const DemoNotice({super.key});
  @override
  Widget build(BuildContext context) =>
      const Text('Dados fictícios para demonstração.',
          style: TextStyle(fontSize: 13));
}

class ResultsPage extends StatefulWidget {
  final PointRepository repository;
  final SearchQuery query;
  const ResultsPage({super.key, required this.repository, required this.query});
  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  late Future<List<SearchHit>> _request;
  bool _map = false, _availableOnly = false, _showFilters = false;
  double? _radius;
  String? _selectedId;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _request = widget.repository.search(widget.query);
  }

  void _open(SearchHit hit) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => DetailPage(point: hit.point)));
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(_map ? 'Mapa de pontos' : 'Resultados')),
      body: SingleChildScrollView(
          child: PageBody(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
            Text(widget.query.term,
                style: Theme.of(context).textTheme.headlineSmall),
            Text('Região: ${widget.query.location}'),
            Text(widget.query.intent == SearchIntent.help
                ? 'Recursos para distribuição'
                : 'Pontos que aceitam doações'),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Alterar busca'))),
              const SizedBox(width: 8),
              Expanded(
                  child: OutlinedButton(
                      onPressed: () =>
                          setState(() => _showFilters = !_showFilters),
                      child: const Text('Filtros'))),
            ]),
            if (_showFilters) ...[
              const SizedBox(height: 16),
              const FieldHeading('Distância máxima'),
              DropdownButtonFormField<double>(
                  isExpanded: true,
                  initialValue: _radius,
                  decoration: const InputDecoration(),
                  items: const [
                    DropdownMenuItem(
                        value: null, child: Text('Todas as distâncias')),
                    DropdownMenuItem(value: 2, child: Text('Até 2 km')),
                    DropdownMenuItem(value: 5, child: Text('Até 5 km'))
                  ],
                  onChanged: (v) => setState(() => _radius = v)),
              if (widget.query.intent == SearchIntent.help)
                CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Somente disponíveis'),
                    value: _availableOnly,
                    onChanged: (v) =>
                        setState(() => _availableOnly = v ?? false)),
            ],
            const SizedBox(height: 12),
            SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: false, label: Text('Lista')),
                  ButtonSegment(value: true, label: Text('Mapa')),
                ],
                selected: {_map},
                onSelectionChanged: (v) => setState(() => _map = v.first)),
            const SizedBox(height: 12),
            FutureBuilder<List<SearchHit>>(
                future: _request,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Buscando pontos…')
                        ]));
                  }
                  if (snapshot.hasError) {
                    return Column(children: [
                      const Text(
                          'Não foi possível carregar os pontos. Sua busca foi mantida.'),
                      FilledButton(
                          onPressed: () => setState(_load),
                          child: const Text('Tentar novamente'))
                    ]);
                  }
                  final hits = (snapshot.data ?? [])
                      .where((h) =>
                          (_radius == null ||
                              (h.point.distanceKm != null &&
                                  h.point.distanceKm! <= _radius!)) &&
                          (!_availableOnly || h.resource.available))
                      .toList()
                    ..sort((a, b) {
                      final availability = (b.resource.available ? 1 : 0)
                          .compareTo(a.resource.available ? 1 : 0);
                      if (availability != 0) return availability;
                      return (a.point.distanceKm ?? double.infinity)
                          .compareTo(b.point.distanceKm ?? double.infinity);
                    });
                  if (hits.isEmpty) {
                    return Column(children: [
                      const Icon(Icons.search_off, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                          'Nenhum ponto encontrado. Altere os filtros, o item ou a região.'),
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Alterar busca'))
                    ]);
                  }
                  final selected = hits.firstWhere(
                      (h) => h.point.id == _selectedId,
                      orElse: () => hits.first);
                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('${hits.length} pontos · disponíveis primeiro'),
                        if (hits.every((h) => h.point.distanceKm == null))
                          const Text(
                              'Distâncias ainda não disponíveis nesta demonstração.'),
                        if (hits.first.alternative)
                          Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                  'Nenhum resultado exato. Alternativas da categoria ${hits.first.resource.category}:')),
                        if (_map) ...[
                          const SizedBox(height: 12),
                          SchematicMap(
                              hits: hits,
                              selectedId: selected.point.id,
                              onSelect: (h) =>
                                  setState(() => _selectedId = h.point.id)),
                          Container(
                              color: const Color(0xffeeeeee),
                              padding: const EdgeInsets.all(14),
                              child: HitTile(
                                  hit: selected,
                                  intent: widget.query.intent,
                                  onOpen: () => _open(selected))),
                        ] else
                          ...hits.map((h) => HitTile(
                              hit: h,
                              intent: widget.query.intent,
                              onOpen: () => _open(h))),
                      ]);
                }),
            const SizedBox(height: 24),
            const DemoNotice(),
          ]))));
}

String resourceStatus(Resource resource) {
  if (!resource.available) return 'Indisponível para distribuição';
  if (resource.publicQuantity == null) {
    return 'Disponível · quantidade não divulgada';
  }
  return '${resource.publicQuantity} ${resource.unit} disponíveis';
}

class HitTile extends StatelessWidget {
  final SearchHit hit;
  final SearchIntent intent;
  final VoidCallback onOpen;
  const HitTile(
      {super.key,
      required this.hit,
      required this.intent,
      required this.onOpen});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(hit.point.name, style: Theme.of(context).textTheme.titleMedium),
        Text(hit.point.institution),
        Text(hit.point.distanceKm == null
            ? 'Distância não calculada'
            : '${hit.point.distanceKm!.toStringAsFixed(1).replaceAll('.', ',')} km · distância ilustrativa'),
        if (hit.alternative) const Text('Alternativa da mesma categoria'),
        Text(
            '${hit.resource.name}: ${intent == SearchIntent.donate ? 'Aceita doação' : resourceStatus(hit.resource)}'),
        Text(
            'Estoque atualizado: ${hit.resource.updatedAt ?? hit.point.updatedAt}'),
        const SizedBox(height: 8),
        OutlinedButton(
            onPressed: onOpen, child: const Text('Ver detalhes do ponto')),
        const Divider(),
      ]));
}

class SchematicMap extends StatelessWidget {
  final List<SearchHit> hits;
  final String selectedId;
  final ValueChanged<SearchHit> onSelect;
  const SchematicMap(
      {super.key,
      required this.hits,
      required this.selectedId,
      required this.onSelect});
  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
            height: 260,
            color: const Color(0xffeeeeee),
            child: LayoutBuilder(
                builder: (context, size) => Stack(children: [
                      const Positioned.fill(
                          child: CustomPaint(painter: _RoadPainter())),
                      for (var i = 0; i < hits.length; i++)
                        Positioned(
                            left: (size.maxWidth - 56) *
                                ((i + 1) / (hits.length + 1)),
                            top: 35.0 + (i % 3) * 60,
                            child: Semantics(
                                label: 'Selecionar ${hits[i].point.name}',
                                child: FilledButton(
                                    style: FilledButton.styleFrom(
                                        backgroundColor:
                                            hits[i].point.id == selectedId
                                                ? const Color(0xff333333)
                                                : const Color(0xff777777),
                                        shape: const CircleBorder(),
                                        minimumSize: const Size(48, 48)),
                                    onPressed: () => onSelect(hits[i]),
                                    child: Text('${i + 1}')))),
                    ]))),
        const Padding(
            padding: EdgeInsets.all(8),
            child: Text('Mapa esquemático. Marcadores sem coordenadas reais.')),
      ]);
}

class _RoadPainter extends CustomPainter {
  const _RoadPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 22;
    canvas.drawLine(Offset(0, size.height * .7),
        Offset(size.width, size.height * .2), paint);
    canvas.drawLine(Offset(size.width * .2, 0),
        Offset(size.width * .7, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _RoadPainter oldDelegate) => false;
}

class DetailPage extends StatelessWidget {
  final SupportPoint point;
  const DetailPage({super.key, required this.point});
  void _explain(BuildContext context, String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Ponto de atendimento')),
      body: SingleChildScrollView(
          child: PageBody(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
            Text(point.name, style: Theme.of(context).textTheme.headlineSmall),
            Text(point.institution),
            const SizedBox(height: 24),
            Text('Endereço e atendimento',
                style: Theme.of(context).textTheme.titleLarge),
            Text('${point.address}\nCidade Exemplo\n${point.hours}'),
            OutlinedButton.icon(
                onPressed: () => _explain(context,
                    'Rotas externas serão integradas depois. O endereço é fictício.'),
                icon: const Icon(Icons.directions_outlined),
                label: const Text('Como chegar · demonstração')),
            const SizedBox(height: 24),
            Text('Recursos para distribuição',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Table(
                columnWidths: const {
                  0: FlexColumnWidth(1),
                  1: FlexColumnWidth(1)
                },
                border: const TableBorder(
                    horizontalInside: BorderSide(color: Color(0xffaaaaaa))),
                children: [
                  const TableRow(children: [
                    Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Item',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12))),
                    Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Situação',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12)))
                  ]),
                  ...point.resources.map((r) => TableRow(children: [
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text('${r.name}\n${r.unit}')),
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(resourceStatus(r))),
                      ])),
                ]),
            Text('Estoque atualizado: ${point.updatedAt}'),
            const SizedBox(height: 24),
            Text('Doações aceitas',
                style: Theme.of(context).textTheme.titleLarge),
            ...point.resources.where((r) => r.acceptsDonation).map((r) =>
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(r.name))),
            const SizedBox(height: 16),
            Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xff777777))),
                child: const Text(
                    'Antes de se deslocar, confirme disponibilidade e atendimento pelos canais da instituição.',
                    style: TextStyle(fontSize: 12))),
            const SizedBox(height: 12),
            FilledButton(
                onPressed: () => _explain(context,
                    'Contato externo ainda não integrado. Nenhuma mensagem foi enviada.'),
                child: const Text('Consultar contato da instituição')),
            const SizedBox(height: 24),
            const Text('A plataforma não realiza transporte ou entrega.'),
            const SizedBox(height: 16),
            const DemoNotice(),
          ]))));
}
