import 'package:apoio_app/data/models/managed_point.dart';
import 'package:apoio_app/data/models/stock_item.dart';
import 'package:apoio_app/data/repositories/management_repository.dart';
import 'package:apoio_app/ui/core/widgets/loading_indicator.dart';
import 'package:apoio_app/ui/management/view_models/stock_view_model.dart';
import 'package:apoio_app/ui/management/widgets/load_failure.dart';
import 'package:apoio_app/ui/management/widgets/stock_item_card.dart';
import 'package:flutter/material.dart';

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
  late final StockViewModel _viewModel;
  @override
  void initState() {
    super.initState();
    _viewModel = StockViewModel(widget.api, widget.point)
      ..addListener(_refresh);
  }

  void _refresh() => setState(() {});
  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(widget.point.name,
                      style: Theme.of(context).textTheme.titleLarge),
                  Text(widget.point.hours),
                  const SizedBox(height: 16),
                  TextField(
                      decoration: const InputDecoration(
                          labelText: 'Buscar no estoque',
                          prefixIcon: Icon(Icons.search)),
                      onChanged: _viewModel.search),
                  Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                          onPressed: _viewModel.reload,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Recarregar estoque'))),
                ])),
        Expanded(
            child: FutureBuilder<List<StockItem>>(
                future: _viewModel.request,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const LoadingIndicator();
                  }
                  if (snapshot.hasError) {
                    return LoadFailure(
                        error: snapshot.error, onRetry: _viewModel.reload);
                  }
                  final stocks = _viewModel.filter(snapshot.data!);
                  if (stocks.isEmpty) {
                    return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                            'Nenhum item encontrado no estoque deste ponto.'));
                  }
                  return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: stocks.length,
                      itemBuilder: (context, index) {
                        final s = stocks[index];
                        return StockItemCard(
                            item: s,
                            onMove: () => widget.onMove(s),
                            onHistory: () => widget.onHistory(s));
                      });
                })),
      ]);
}
