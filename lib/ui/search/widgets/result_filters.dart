import 'package:apoio_app/data/models/search_intent.dart';
import 'package:flutter/material.dart';

class ResultFilters extends StatelessWidget {
  static const maximumRadius = 50.0;
  const ResultFilters({
    super.key,
    required this.intent,
    required this.showRadius,
    required this.radius,
    required this.availableOnly,
    required this.onRadiusChanged,
    required this.onAvailableChanged,
  });
  final SearchIntent intent;
  final bool showRadius;
  final double? radius;
  final bool availableOnly;
  final ValueChanged<double?> onRadiusChanged;
  final ValueChanged<bool> onAvailableChanged;

  static double? radiusFor(double value) =>
      value <= 0 || value >= maximumRadius ? null : value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (showRadius) ...[
        Text(
          'Distância máxima',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          radiusFor(radius ?? 0) == null
              ? 'Todas as distâncias'
              : 'Até ${radius!.toStringAsFixed(0)} km',
        ),
        Slider(
          key: const ValueKey('distance-range'),
          min: 0,
          max: maximumRadius,
          divisions: 50,
          value: (radius ?? 0).clamp(0, maximumRadius),
          label: radiusFor(radius ?? 0) == null
              ? 'Todas'
              : '${radius!.toStringAsFixed(0)} km',
          semanticFormatterCallback: (value) => radiusFor(value) == null
              ? 'Todas as distâncias'
              : 'Até ${value.toStringAsFixed(0)} quilômetros',
          onChanged: (value) => onRadiusChanged(value),
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Todas', style: TextStyle(fontSize: 12)),
            Text('50 km · Todas', style: TextStyle(fontSize: 12)),
          ],
        ),
        const SizedBox(height: 20),
      ],
      if (intent == SearchIntent.help)
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          shape: const StadiumBorder(),
          title: const Text('Somente disponíveis'),
          value: availableOnly,
          onChanged: (value) => onAvailableChanged(value ?? false),
        ),
    ],
  );
}
