import 'package:apoio_app/data/models/managed_point.dart';
import 'package:apoio_app/data/models/stock_item.dart';
import 'package:apoio_app/data/repositories/management_repository.dart';
import 'package:apoio_app/ui/core/widgets/loading_indicator.dart';
import 'package:apoio_app/ui/management/view_models/stock_view_model.dart';
import 'package:apoio_app/ui/management/views/link_stock_item_page.dart';
import 'package:apoio_app/ui/management/widgets/load_failure.dart';
import 'package:apoio_app/ui/management/widgets/stock_item_card.dart';
import 'package:flutter/material.dart';
import 'package:apoio_app/ui/management/views/publication_form.dart';

class StockView extends StatefulWidget {
  final ManagementRepository api;
  final ManagedPoint point;
  final ValueChanged<StockItem> onMove, onHistory;
  const StockView(
      {super.key,
      required this.api,
      required this.point,
      required this.onMove,
      required this.onHistory});
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

  Future<void> _openCatalog() async {
    final linked = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) =>
              LinkStockItemPage(api: widget.api, point: widget.point)),
    );
    if (!mounted) return;
    if (linked == true) {
      _search.clear();
      _viewModel.search('');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Item vinculado. Registre uma entrada para atualizar o saldo.')));
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
  Widget build(BuildContext context) => CustomScrollView(slivers: [
        SliverToBoxAdapter(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(widget.point.name,
                          style: Theme.of(context).textTheme.titleLarge),
                      Text(widget.point.hours),
                      const SizedBox(height: 16),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        FilledButton.icon(
                            onPressed: _openCatalog,
                            icon: const Icon(Icons.add),
                            label: const Text('Vincular item do catálogo')),
                        TextButton.icon(
                            onPressed: _viewModel.reload,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Recarregar estoque')),
                      ]),
                      const SizedBox(height: 16),
                      TextField(
                          controller: _search,
                          decoration: const InputDecoration(
                              labelText: 'Buscar no estoque',
                              prefixIcon: Icon(Icons.search)),
                          onChanged: _viewModel.search),
                    ]))),
        FutureBuilder<List<StockItem>>(
            future: _viewModel.request,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SliverToBoxAdapter(child: LoadingIndicator());
              }
              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                    child: LoadFailure(
                        error: snapshot.error, onRetry: _viewModel.reload));
              }
              final stock = snapshot.data!;
              final stocks = _viewModel.filter(stock);
              if (stocks.isEmpty) {
                return SliverToBoxAdapter(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(stock.isEmpty
                            ? 'O estoque está vazio. Vincule um item do catálogo para registrar a primeira entrada.'
                            : 'Nenhum item do estoque corresponde à busca.')));
              }
              return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList.builder(
                      itemCount: stocks.length,
                      itemBuilder: (context, index) {
                        final s = stocks[index];
                        return StockItemCard(
                            item: s,
                            onPublication: () async {
                              await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => PublicationForm(
                                          api: widget.api, item: s)));
                              if (mounted) _viewModel.reload();
                            },
                            onMove: () => widget.onMove(s),
                            onHistory: () => widget.onHistory(s));
                      }));
            }),
      ]);
}
