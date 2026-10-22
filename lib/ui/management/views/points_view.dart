import 'package:apoio_app/data/models/managed_point.dart';
import 'package:apoio_app/data/repositories/management_repository.dart';
import 'package:apoio_app/ui/core/view_models/async_list_view_model.dart';
import 'package:apoio_app/ui/core/widgets/loading_indicator.dart';
import 'package:apoio_app/ui/management/widgets/load_failure.dart';
import 'package:flutter/material.dart';

class PointsView extends StatefulWidget {
  final ManagementRepository api;
  final ValueChanged<ManagedPoint> onSelect;
  const PointsView({super.key, required this.api, required this.onSelect});
  @override
  State<PointsView> createState() => _PointsViewState();
}

class _PointsViewState extends State<PointsView> {
  late final AsyncListViewModel<ManagedPoint> _viewModel;
  @override
  void initState() {
    super.initState();
    _viewModel = AsyncListViewModel(widget.api.points)..addListener(_refresh);
  }

  void _refresh() => setState(() {});
  @override
  void dispose() {
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
        return ListView(padding: const EdgeInsets.all(24), children: [
          Text('Olá, ${widget.api.session?.name ?? ''}',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Escolha o ponto cujo estoque você quer administrar.'),
          Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                  onPressed: _viewModel.reload,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Atualizar pontos'))),
          if (points.isEmpty)
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                    'Você ainda não tem pontos vinculados. Solicite à prefeitura o acesso à sua instituição.')),
          ...points.map((p) => Column(children: [
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(p.name),
                    subtitle: Text('${p.institution}\n${p.address}'),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => widget.onSelect(p)),
                const Divider()
              ])),
        ]);
      });
}
