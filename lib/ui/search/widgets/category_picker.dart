import 'package:flutter/material.dart';
import 'package:apoio_app/ui/support_points/widgets/resource_card.dart';

class CategoryPicker extends StatelessWidget {
  final ValueChanged<String> onSelected;
  final String? selected;

  const CategoryPicker({super.key, required this.onSelected, this.selected});

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 8,
    runSpacing: 8,
    children:
        [
              'Água',
              'Alimentos',
              'Higiene',
              'Abrigo',
              'Roupas',
              'Agasalhos',
              'Calçados',
              'Cobertores',
              'Medicamentos',
              'Infantil',
            ]
            .map(
              (category) => OutlinedButton.icon(
                icon: Icon(resourceIcon(category), size: 15),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  fixedSize: const Size.fromHeight(32),
                  backgroundColor: selected == category
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : null,
                  side: BorderSide(
                    color: selected == category
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                ),
                onPressed: () => onSelected(category),
                label: Text(category, style: const TextStyle(fontSize: 12)),
              ),
            )
            .toList(),
  );
}
