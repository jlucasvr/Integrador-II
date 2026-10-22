import 'package:apoio_app/data/models/search_hit.dart';
import 'package:apoio_app/data/models/search_intent.dart';
import 'package:apoio_app/ui/search/widgets/result_badge.dart';
import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final donating = intent == SearchIntent.donate;
    final available =
        donating ? hit.resource.acceptsDonation : hit.resource.available;
    final status = donating
        ? available
            ? 'Aceita doação'
            : 'Não aceita doação'
        : available
            ? 'Disponível'
            : 'Indisponível';

    return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: colors.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: BorderSide(color: colors.outline)),
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
                                    color: colors.surfaceContainerHighest,
                                    shape: BoxShape.circle),
                                child: const SizedBox.square(
                                    dimension: 44,
                                    child: Icon(Icons.apartment_rounded,
                                        size: 22))),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(hit.point.name,
                                      style: theme.textTheme.titleMedium),
                                  const SizedBox(height: 4),
                                  Text(hit.point.institution,
                                      style: theme.textTheme.bodySmall),
                                ])),
                            const SizedBox(width: 8),
                            ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 110),
                                child: ResultBadge(
                                    label: hit.point.distanceKm == null
                                        ? 'Distância não calculada'
                                        : '${hit.point.distanceKm!.toStringAsFixed(1).replaceAll('.', ',')} km',
                                    icon: Icons.near_me_outlined)),
                          ]),
                      const SizedBox(height: 16),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                  child: Text(hit.resource.name,
                                      style: theme.textTheme.titleMedium)),
                              const SizedBox(width: 8),
                              Flexible(
                                  child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                    Icon(
                                        donating
                                            ? Icons.volunteer_activism_outlined
                                            : available
                                                ? Icons.check_circle_outline
                                                : Icons.remove_circle_outline,
                                        size: 14,
                                        color: colors.onSurfaceVariant),
                                    const SizedBox(width: 4),
                                    Flexible(
                                        child: Text(status,
                                            style: theme.textTheme.bodySmall)),
                                  ])),
                            ]),
                            if (hit.alternative) ...[
                              const SizedBox(height: 8),
                              Text('Alternativa da mesma categoria',
                                  style: theme.textTheme.bodySmall),
                            ],
                          ]),
                      const SizedBox(height: 16),
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 16, color: colors.onSurfaceVariant),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(
                                    'Estoque atualizado: ${hit.resource.updatedAt ?? hit.point.updatedAt}',
                                    style: theme.textTheme.bodySmall)),
                          ]),
                      const SizedBox(height: 16),
                      FilledButton(
                          onPressed: onOpen,
                          child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                        child: Text('Ver detalhes do ponto')),
                                    SizedBox(width: 12),
                                    Icon(Icons.arrow_forward_rounded, size: 18),
                                  ]))),
                    ]))));
  }
}
