import 'package:apoio_app/data/models/resource.dart';
import 'package:apoio_app/ui/support_points/formatters/resource_availability.dart';
import 'package:flutter/material.dart';

class ResourceAvailabilityIndicator extends StatelessWidget {
  const ResourceAvailabilityIndicator({
    super.key,
    required this.resource,
    this.compact = false,
  });
  final Resource resource;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final availability = ResourceAvailability.of(resource);
    final hasBar =
        availability.fill != null &&
        (!compact || resource.publicQuantity != null);
    final color = switch (availability) {
      ResourceAvailability.high => const Color(0xff23804b),
      ResourceAvailability.medium => const Color(0xffc49516),
      ResourceAvailability.low ||
      ResourceAvailability.unavailable => const Color(0xffc3473b),
      ResourceAvailability.empty => const Color(0xff767676),
      ResourceAvailability.undisclosed =>
        compact ? const Color(0xff23804b) : const Color(0xff767676),
    };
    final textColor = availability == ResourceAvailability.medium
        ? const Color(0xff7c5b08)
        : color;
    final label = !compact
        ? availability.label
        : !hasBar
        ? resource.available
              ? 'Disponível'
              : 'Indisponível'
        : switch (availability) {
            ResourceAvailability.high => 'Estoque bom',
            ResourceAvailability.medium => 'Estoque médio',
            ResourceAvailability.low => 'Poucas unidades',
            ResourceAvailability.empty => 'Sem estoque',
            _ => 'Indisponível',
          };
    final textStyle = Theme.of(context).textTheme.bodySmall!;
    return Semantics(
      label: '${resource.name}: ${hasBar ? availability.label : label}',
      excludeSemantics: true,
      child: Tooltip(
        message: hasBar ? availability.label : label,
        excludeFromSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (compact && !hasBar)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    resource.available
                        ? Icons.check_circle_outline
                        : Icons.remove_circle_outline,
                    size: 14,
                    color: color,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      style: textStyle.copyWith(fontSize: 11, color: textColor),
                    ),
                  ),
                ],
              )
            else
              Text(
                label,
                style: compact
                    ? textStyle.copyWith(fontSize: 11, color: textColor)
                    : textStyle,
              ),
            if (hasBar) ...[
              SizedBox(height: compact ? 5 : 8),
              LinearProgressIndicator(
                value: availability.fill,
                minHeight: compact ? 7 : 9,
                borderRadius: BorderRadius.circular(20),
                color: color,
                backgroundColor: color.withValues(alpha: .12),
              ),
            ] else if (!compact &&
                availability == ResourceAvailability.undisclosed) ...[
              const SizedBox(height: 8),
              const Text(
                'Nível de estoque não informado',
                style: TextStyle(fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
