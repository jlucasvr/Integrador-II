import 'package:apoio_app/app/navigation.dart';
import 'package:apoio_app/data/models/support_point.dart';
import 'package:apoio_app/data/repositories/management_repository.dart';
import 'package:apoio_app/ui/core/layout/page_body.dart';
import 'package:apoio_app/ui/core/widgets/app_top_bar.dart';
import 'package:apoio_app/ui/support_points/widgets/resource_table.dart';
import 'package:flutter/material.dart';

class DetailPage extends StatelessWidget {
  final SupportPoint point;
  final ManagementRepository? managementApi;
  const DetailPage({super.key, required this.point, this.managementApi});
  void _explain(BuildContext context, String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
  @override
  Widget build(BuildContext context) => Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppTopBar(
          sectionTitle: 'Ponto de atendimento',
          onManagement: () => openManagement(context, managementApi)),
      body: Builder(
          builder: (context) => SingleChildScrollView(
              padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
              child: PageBody(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    Text(point.name,
                        style: Theme.of(context).textTheme.headlineSmall),
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
                    ResourceTable(resources: point.resources),
                    Text('Estoque atualizado: ${point.updatedAt}'),
                    const SizedBox(height: 24),
                    Text('Doações aceitas',
                        style: Theme.of(context).textTheme.titleLarge),
                    ...point.resources.where((r) => r.acceptsDonation).map(
                        (r) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(r.name))),
                    const SizedBox(height: 16),
                    Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: Theme.of(context).colorScheme.outline)),
                        child: const Text(
                            'Antes de se deslocar, confirme disponibilidade e atendimento pelos canais da instituição.',
                            style: TextStyle(fontSize: 12))),
                    const SizedBox(height: 12),
                    FilledButton(
                        onPressed: () => _explain(context,
                            'Contato externo ainda não integrado. Nenhuma mensagem foi enviada.'),
                        child: const Text('Consultar contato da instituição')),
                    const SizedBox(height: 24),
                    const Text(
                        'A plataforma não realiza transporte ou entrega.'),
                    const SizedBox(height: 16),
                  ])))));
}
