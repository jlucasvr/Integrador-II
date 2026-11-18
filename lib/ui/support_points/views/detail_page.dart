import 'package:apoio_app/app/navigation.dart';
import 'package:apoio_app/data/models/support_point.dart';
import 'package:apoio_app/data/repositories/management_repository.dart';
import 'package:apoio_app/ui/core/layout/page_body.dart';
import 'package:apoio_app/ui/core/widgets/app_top_bar.dart';
import 'package:apoio_app/ui/core/widgets/demo_search_notice.dart';
import 'package:apoio_app/ui/core/widgets/stock_updated_at.dart';
import 'package:apoio_app/ui/support_points/widgets/detail_card.dart';
import 'package:apoio_app/ui/support_points/widgets/point_actions.dart';
import 'package:apoio_app/ui/support_points/widgets/point_location_card.dart';
import 'package:apoio_app/ui/support_points/widgets/resource_card.dart';
import 'package:flutter/material.dart';

class DetailPage extends StatefulWidget {
  final SupportPoint point;
  final ManagementRepository? managementApi;
  final bool isDemo;
  const DetailPage({
    super.key,
    required this.point,
    this.managementApi,
    this.isDemo = false,
  });
  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final _itemsKey = GlobalKey();
  final _locationKey = GlobalKey();

  void _scrollTo(GlobalKey key) {
    final target = key.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 300),
        alignment:
            ((MediaQuery.paddingOf(context).top +
                        const AppTopBar().preferredSize.height +
                        28) /
                    MediaQuery.sizeOf(context).height)
                .clamp(0, 1),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final point = widget.point;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final resources = point.resources;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppTopBar(
        onManagement: () => openManagement(context, widget.managementApi),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top:
              MediaQuery.paddingOf(context).top +
              const AppTopBar().preferredSize.height,
        ),
        child: PageBody(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Ponto de atendimento', style: theme.textTheme.bodySmall),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox.square(
                      dimension: 56,
                      child: Icon(
                        Icons.apartment_rounded,
                        size: 28,
                        color: colors.surface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          point.name,
                          style: theme.textTheme.headlineSmall!.copyWith(
                            fontSize: 26,
                            height: 1.25,
                          ),
                        ),
                        if (point.institution != point.name) ...[
                          const SizedBox(height: 6),
                          Text(
                            point.institution,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (widget.isDemo) ...[
                const SizedBox(height: 16),
                const DemoSearchNotice(),
                const SizedBox(height: 4),
                Text(
                  'Endereços e pontos no mapa são ilustrativos.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => _scrollTo(_itemsKey),
                    icon: const Icon(Icons.inventory_2_outlined, size: 18),
                    label: const Text('Ver itens'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _scrollTo(_locationKey),
                    icon: const Icon(Icons.near_me_outlined, size: 18),
                    label: const Text('Como chegar'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => showPointContact(context, point),
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 18,
                    ),
                    label: const Text('Contato'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              DetailCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.schedule_rounded, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Quando ir', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            point.hours.isEmpty
                                ? 'Horário não informado'
                                : point.hours,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Itens e doações',
                key: _itemsKey,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(
                'Veja o que tem para retirar e o que você pode doar.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              if (resources.isEmpty)
                DetailCard(
                  child: Column(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 32),
                      const SizedBox(height: 12),
                      const Text(
                        'Esta organização ainda não informou seus itens.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => showPointContact(context, point),
                        child: const Text('Consultar a organização'),
                      ),
                    ],
                  ),
                )
              else
                ...resources.map(
                  (resource) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ResourceCard(resource: resource),
                  ),
                ),
              if (resources.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: const [
                    _LevelLegend(Color(0xff23804b), 'Boa'),
                    _LevelLegend(Color(0xffc49516), 'Moderada'),
                    _LevelLegend(Color(0xffc3473b), 'Baixa'),
                    _LevelLegend(
                      Color(0xff767676),
                      'Sem estoque',
                      hollow: true,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'As barras indicam faixas de disponibilidade.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
              if (point.resources.isNotEmpty) ...[
                const SizedBox(height: 12),
                StockUpdatedAt(value: point.updatedAt),
              ],
              const SizedBox(height: 20),
              DetailCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Confirme antes de ir',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Os itens podem acabar. Fale com a organização para confirmar o atendimento.',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => showPointContact(context, point),
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 18,
                      ),
                      label: const Text('Consultar contato'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Onde fica',
                key: _locationKey,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              PointLocationCard(point: point),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.directions_walk_rounded,
                    size: 18,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'A retirada e a doação são feitas no local. A plataforma não faz entregas.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelLegend extends StatelessWidget {
  const _LevelLegend(this.color, this.label, {this.hollow = false});
  final Color color;
  final String label;
  final bool hollow;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      DecoratedBox(
        decoration: BoxDecoration(
          color: hollow ? null : color,
          border: hollow ? Border.all(color: color) : null,
          shape: BoxShape.circle,
        ),
        child: const SizedBox.square(dimension: 8),
      ),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}
