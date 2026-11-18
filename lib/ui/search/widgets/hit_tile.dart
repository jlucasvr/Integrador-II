import 'package:apoio_app/data/models/resource.dart';
import 'package:apoio_app/data/models/search_hit.dart';
import 'package:apoio_app/data/models/search_intent.dart';
import 'package:apoio_app/ui/core/widgets/stock_updated_at.dart';
import 'package:apoio_app/ui/search/widgets/result_badge.dart';
import 'package:apoio_app/ui/support_points/widgets/resource_availability_indicator.dart';
import 'package:apoio_app/ui/support_points/widgets/resource_card.dart';
import 'package:flutter/material.dart';

class HitTile extends StatelessWidget {
  final SearchHit hit;
  final SearchIntent intent;
  final List<Resource>? resources;
  final VoidCallback onOpen;

  const HitTile({
    super.key,
    required this.hit,
    required this.intent,
    required this.onOpen,
    this.resources,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final distance = hit.point.distanceKm;
    final hasDistance = distance != null && distance.isFinite && distance >= 0;
    final region = hit.point.region.trim();
    final items = resources ?? [hit.resource];

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: colors.outline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox.square(
                      dimension: 44,
                      child: Icon(
                        Icons.apartment_rounded,
                        size: 22,
                        color: colors.surface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hit.point.name,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hit.point.institution,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (hasDistance || region.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasDistance)
                      Tooltip(
                        message: 'Distância em linha reta aproximada',
                        child: ResultBadge(
                          label:
                              '${distance.toStringAsFixed(distance < .1 ? 2 : 1).replaceAll('.', ',')} km',
                          icon: Icons.near_me_outlined,
                        ),
                      ),
                    if (hasDistance && region.isNotEmpty)
                      const SizedBox(width: 8),
                    if (region.isNotEmpty)
                      Flexible(
                        child: Tooltip(
                          message: region,
                          child: ResultBadge(
                            label: region,
                            icon: Icons.location_on_outlined,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.outline),
                ),
                child: Column(
                  children: [
                    for (var index = 0; index < items.length; index++) ...[
                      if (index > 0)
                        const Divider(height: 1, indent: 16, endIndent: 16),
                      _ResultResourceRow(
                        resource: items[index],
                        intent: intent,
                        fallbackDate: hit.point.updatedAt,
                      ),
                    ],
                  ],
                ),
              ),
              if (hit.alternative) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.swap_horiz_rounded,
                      size: 16,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Alternativa da mesma categoria',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),

              FilledButton(
                onPressed: onOpen,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: Text('Ver detalhes do ponto')),
                      SizedBox(width: 12),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultResourceRow extends StatelessWidget {
  const _ResultResourceRow({
    required this.resource,
    required this.intent,
    required this.fallbackDate,
  });
  final Resource resource;
  final SearchIntent intent;
  final String fallbackDate;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final donating = intent == SearchIntent.donate;
    final donationColor = resource.acceptsDonation
        ? const Color(0xff23804b)
        : const Color(0xffb23b31);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final name = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(resourceIcon(resource.category), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      resource.name,
                      style: theme.textTheme.titleSmall!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              );
              final indicator = ResourceAvailabilityIndicator(
                key: ValueKey('result-stock-${resource.name}'),
                resource: resource,
                compact: true,
              );
              if (constraints.maxWidth < 180 ||
                  MediaQuery.textScalerOf(context).scale(14) > 20) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    name,
                    const SizedBox(height: 10),
                    SizedBox(width: 180, child: indicator),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: name),
                  const SizedBox(width: 12),
                  SizedBox(width: 110, child: indicator),
                ],
              );
            },
          ),
          if (donating) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.volunteer_activism_outlined,
                  size: 16,
                  color: donationColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    resource.acceptsDonation
                        ? 'Aceita sua doação'
                        : 'Não recebe doação deste item',
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: donationColor,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),
          StockUpdatedAt(value: resource.updatedAt ?? fallbackDate),
        ],
      ),
    );
  }
}
