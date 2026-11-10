import 'package:apoio_app/core/utils/normalize.dart';
import 'package:apoio_app/data/models/managed_point.dart';
import 'package:apoio_app/data/repositories/management_repository.dart';
import 'package:apoio_app/ui/core/view_models/async_list_view_model.dart';
import 'package:apoio_app/ui/core/widgets/loading_indicator.dart';
import 'package:apoio_app/ui/management/widgets/load_failure.dart';
import 'package:apoio_app/ui/management/widgets/operation_layout.dart';
import 'package:flutter/material.dart';
import 'package:apoio_app/ui/management/views/point_form.dart';

class PointsView extends StatefulWidget {
  final ManagementRepository api;
  final ValueChanged<ManagedPoint> onSelect;
  const PointsView({super.key, required this.api, required this.onSelect});
  @override
  State<PointsView> createState() => _PointsViewState();
}

class _PointsViewState extends State<PointsView> {
  late final AsyncListViewModel<ManagedPoint> _viewModel;
  final _search = TextEditingController();
  String _query = '';
  @override
  void initState() {
    super.initState();
    _viewModel = AsyncListViewModel(widget.api.points)..addListener(_refresh);
  }

  void _refresh() => setState(() {});
  Future<void> _edit([ManagedPoint? point]) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PointForm(api: widget.api, point: point),
      ),
    );
    if (mounted) _viewModel.reload();
  }

  @override
  void dispose() {
    _search.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<ManagedPoint>>(
    future: _viewModel.request,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const LoadingIndicator();
      }
      if (snapshot.hasError) {
        return LoadFailure(error: snapshot.error, onRetry: _viewModel.reload);
      }
      final points = snapshot.data!;
      final results = points.where(
        (point) =>
            normalize('${point.name} ${point.institution}').contains(_query),
      );
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          OperationHeading(
            title: 'Pontos sob sua gestão',
            description:
                'Consulte os pontos das suas instituições e abra o estoque para trabalhar.',
            actions: [
              FilledButton.icon(
                onPressed: () => _edit(),
                icon: const Icon(Icons.add),
                label: const Text('Cadastrar ponto'),
              ),
              TextButton.icon(
                onPressed: _viewModel.reload,
                icon: const Icon(Icons.refresh),
                label: const Text('Atualizar pontos'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (points.isNotEmpty) ...[
            TextField(
              controller: _search,
              decoration: const InputDecoration(
                labelText: 'Buscar ponto ou instituição',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = normalize(value)),
            ),
            const SizedBox(height: 12),
          ],
          if (points.isEmpty)
            const OperationEmpty(
              'Nenhum ponto cadastrado',
              'Cadastre um ponto em uma instituição vinculada à sua conta. Se não tiver vínculo, solicite acesso à prefeitura.',
            ),
          if (points.isNotEmpty && results.isEmpty)
            const OperationEmpty(
              'Nenhum ponto encontrado',
              'Confira o nome ou tente outro termo.',
            ),
          for (final point in results)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    point.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(point.institution),
                      Text(point.address),
                      OperationStatus(
                        point.active ? 'Ativo' : 'Inativo',
                        point.active
                            ? Icons.check_circle_outline
                            : Icons.pause_circle_outline,
                      ),
                    ],
                  ),
                  onTap: () => widget.onSelect(point),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => widget.onSelect(point),
                      icon: const Icon(Icons.inventory_2_outlined, size: 18),
                      label: const Text('Abrir estoque'),
                    ),
                    TextButton.icon(
                      onPressed: () => _edit(point),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Editar ponto'),
                    ),
                  ],
                ),
                const Divider(),
              ],
            ),
        ],
      );
    },
  );
}
