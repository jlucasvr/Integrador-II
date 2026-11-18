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

  static double compactHeight(BuildContext context, double width) {
    final style = Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 11);
    var height = 14.0;
    for (final label in [
      'Estoque bom',
      'Estoque médio',
      'Poucas unidades',
      'Sem estoque',
      'Disponível',
      'Indisponível',
    ]) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: width - 18);
      if (painter.height > height) height = painter.height;
      painter.dispose();
    }
    return height + 5 + 7;
  }

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
      ResourceAvailability.undisclosed => const Color(0xff23804b),
    };
    final textColor = availability == ResourceAvailability.medium
        ? const Color(0xff7c5b08)
        : color;
    final label = !hasBar
        ? resource.available
              ? 'Disponível'
              : 'Indisponível'
        : !compact
        ? availability.label
        : switch (availability) {
            ResourceAvailability.high => 'Estoque bom',
            ResourceAvailability.medium => 'Estoque médio',
            ResourceAvailability.low => 'Poucas unidades',
            ResourceAvailability.empty => 'Sem estoque',
            _ => 'Indisponível',
          };
    final textStyle = Theme.of(context).textTheme.bodySmall!;
    final showConfirmation = !compact && !hasBar && resource.available;
    final description = showConfirmation
        ? '$label · confirme no contato'
        : hasBar
        ? availability.label
        : label;
    final status = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          resource.available ? Icons.check_rounded : Icons.close_rounded,
          size: compact ? 14 : 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: textStyle.copyWith(
              fontSize: compact ? 11 : 12,
              color: textColor,
            ),
          ),
        ),
      ],
    );
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: compact
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        if (!hasBar)
          Wrap(
            alignment: compact ? WrapAlignment.center : WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              status,
              if (showConfirmation)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('·', style: textStyle),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'confirme no contato',
                        textAlign: TextAlign.start,
                        style: textStyle.copyWith(fontSize: 11),
                      ),
                    ),
                  ],
                ),
            ],
          )
        else
          Text(
            label,
            textAlign: compact ? TextAlign.center : TextAlign.start,
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
        ],
      ],
    );
    return Semantics(
      label: '${resource.name}: $description',
      excludeSemantics: true,
      child: Tooltip(
        message: description,
        excludeFromSemantics: true,
        child: compact
            ? content
            : ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Align(alignment: Alignment.centerLeft, child: content),
              ),
      ),
    );
  }
}
