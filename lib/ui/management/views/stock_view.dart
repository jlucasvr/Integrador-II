import 'package:apoio_app/data/models/managed_point.dart';
import 'package:apoio_app/data/models/stock_item.dart';
import 'package:apoio_app/data/repositories/management_repository.dart';
import 'package:apoio_app/ui/core/widgets/loading_indicator.dart';
import 'package:apoio_app/ui/management/view_models/stock_view_model.dart';
import 'package:apoio_app/ui/management/views/link_stock_item_page.dart';
import 'package:apoio_app/ui/management/widgets/load_failure.dart';
import 'package:apoio_app/ui/management/widgets/operation_layout.dart';
import 'package:apoio_app/ui/management/widgets/stock_item_card.dart';
import 'package:flutter/material.dart';
import 'package:apoio_app/ui/management/views/publication_form.dart';

class StockView extends StatefulWidget {
  final ManagementRepository api;
  final ManagedPoint point;
  final ValueChanged<StockItem> onMove, onHistory;
  final int revision;
  const StockView({
    super.key,
    required this.api,
    required this.point,
    this.revision = 0,
    required this.onMove,
    required this.onHistory,
  });
  @override
  State<StockView> createState() => _StockViewState();
}

class _StockViewState extends State<StockView> {
  final _search = TextEditingController();
  late final StockViewModel _viewModel;
  @override
  void initState() {
    super.initState();
    _viewModel = StockViewModel(widget.api, widget.point)
      ..addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void didUpdateWidget(covariant StockView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revision != widget.revision) _viewModel.reload();
  }

  Future<void> _openPublication(StockItem item) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PublicationForm(
          api: widget.api,
          item: item,
          pointName: widget.point.name,
        ),
      ),
    );
    if (!mounted) return;
    _viewModel.reload();
    if (saved == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Publicação atualizada.')));
    }
  }

  Future<void> _openCatalog() async {
    final linked = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LinkStockItemPage(api: widget.api, point: widget.point),
      ),
    );
    if (!mounted) return;
    if (linked == true) {
      _search.clear();
      _viewModel.search('');
      _viewModel.select(StockFilter.all);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Item vinculado. Registre uma entrada para atualizar o saldo.',
          ),
        ),
      );
    }
    _viewModel.reload();
  }

  @override
  void dispose() {
    _search.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide =
          constraints.maxWidth >= 1000 &&
          MediaQuery.textScalerOf(context).scale(14) <= 17;
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OperationHeading(
                    title: widget.point.name,
                    description:
                        '${widget.point.institution} · ${widget.point.active ? 'Ponto ativo' : 'Ponto inativo'}\n${widget.point.hours}',
                    actions: [
                      FilledButton.icon(
                        onPressed: _openCatalog,
                        icon: const Icon(Icons.add),
                        label: const Text('Vincular item do catálogo'),
                      ),
                      if (constraints.maxWidth < 480)
                        IconButton(
                          onPressed: _viewModel.reload,
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Recarregar estoque',
                        )
                      else
                        TextButton.icon(
                          onPressed: _viewModel.reload,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Recarregar estoque'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          FutureBuilder<List<StockItem>>(
            future: _viewModel.request,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SliverToBoxAdapter(child: LoadingIndicator());
              }
              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: LoadFailure(
                    error: snapshot.error,
                    onRetry: _viewModel.reload,
                  ),
                );
              }
              final stock = snapshot.data!;
              final stocks = _viewModel.filter(stock);
              if (stock.isEmpty) {
                return SliverToBoxAdapter(
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: OperationEmpty(
                      'O estoque está vazio',
                      'Vincule um item do catálogo para registrar a primeira entrada. O item ficará oculto até você publicá-lo.',
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 72),
                sliver: SliverList.builder(
                  itemCount: stocks.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _search,
                            decoration: const InputDecoration(
                              labelText: 'Buscar no estoque',
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: _viewModel.search,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              for (final filter in StockFilter.values)
                                OperationFilterChip(
                                  label: filter.label,
                                  selected: filter == _viewModel.status,
                                  onSelect: () => _viewModel.select(filter),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              '${stocks.length} de ${stock.length} itens',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (stocks.isEmpty)
                            const OperationEmpty(
                              'Nenhum item encontrado',
                              'Tente outro termo ou selecione Todos para remover o filtro de situação.',
                            )
                          else if (wide)
                            const OperationColumns(
                              heading: true,
                              widths: StockItemCard.columns,
                              cells: [
                                Text('Item'),
                                Text('Saldo'),
                                Text('Distribuição'),
                                Text('Publicação'),
                                Text('Ações'),
                              ],
                            ),
                        ],
                      );
                    }
                    final s = stocks[index - 1];
                    return StockItemCard(
                      item: s,
                      wide: wide,
                      onPublication: () => _openPublication(s),
                      onMove: () => widget.onMove(s),
                      onHistory: () => widget.onHistory(s),
                    );
                  },
                ),
              );
            },
          ),
        ],
      );
    },
  );
}
