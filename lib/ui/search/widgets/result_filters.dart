import 'package:apoio_app/data/models/search_intent.dart';
import 'package:apoio_app/ui/core/widgets/field_heading.dart';
import 'package:flutter/material.dart';

class ResultFilters extends StatelessWidget {
  final SearchIntent intent;
  final double? radius;
  final bool availableOnly;
  final ValueChanged<double?> onRadiusChanged;
  final ValueChanged<bool> onAvailableChanged;

  const ResultFilters({
    super.key,
    required this.intent,
    required this.radius,
    required this.availableOnly,
    required this.onRadiusChanged,
    required this.onAvailableChanged,
  });

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 16),
        const FieldHeading('Distância máxima'),
        DropdownButtonFormField<double>(
            isExpanded: true,
            initialValue: radius,
            decoration: const InputDecoration(),
            items: const [
              DropdownMenuItem(value: null, child: Text('Todas as distâncias')),
              DropdownMenuItem(value: 2, child: Text('Até 2 km')),
              DropdownMenuItem(value: 5, child: Text('Até 5 km')),
            ],
            onChanged: onRadiusChanged),
        if (intent == SearchIntent.help)
          CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Somente disponíveis'),
              value: availableOnly,
              onChanged: (value) => onAvailableChanged(value ?? false)),
      ]);
}
