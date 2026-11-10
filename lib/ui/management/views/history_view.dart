import 'package:apoio_app/data/models/stock_item.dart';
import 'package:apoio_app/data/models/stock_movement.dart';
import 'package:apoio_app/data/repositories/management_repository.dart';
import 'package:apoio_app/ui/core/view_models/async_list_view_model.dart';
import 'package:apoio_app/ui/core/widgets/loading_indicator.dart';
import 'package:apoio_app/ui/management/widgets/load_failure.dart';
import 'package:apoio_app/ui/management/widgets/operation_layout.dart';
import 'package:apoio_app/ui/management/widgets/stock_movement_tile.dart';
import 'package:flutter/material.dart';

class HistoryView extends StatefulWidget {
  final ManagementRepository api;
  final StockItem item;
  const HistoryView({super.key, required this.api, required this.item});
  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  late final AsyncListViewModel<StockMovement> _viewModel;
  @override
  void initState() {
    super.initState();
    _viewModel = AsyncListViewModel(() => widget.api.history(widget.item.id))
      ..addListener(_refresh);
  }

  void _refresh() => setState(() {});
  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<StockMovement>>(
    future: _viewModel.request,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const LoadingIndicator();
      }
      if (snapshot.hasError) {
        return LoadFailure(error: snapshot.error, onRetry: _viewModel.reload);
      }
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          OperationHeading(
            title: widget.item.name,
            description: 'Até 100 movimentações mais recentes.',
            actions: [
              TextButton.icon(
                onPressed: _viewModel.reload,
                icon: const Icon(Icons.refresh),
                label: const Text('Atualizar histórico'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (snapshot.data!.isEmpty)
            const OperationEmpty(
              'Nenhuma movimentação registrada',
              'Entradas, saídas e ajustes deste item aparecerão aqui.',
            ),
          ...snapshot.data!.map(
            (m) => StockMovementTile(movement: m, unit: widget.item.unit),
          ),
        ],
      );
    },
  );
}
