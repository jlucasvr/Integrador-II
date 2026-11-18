import 'package:flutter/material.dart';
import 'package:apoio_app/ui/support_points/widgets/resource_card.dart';

class CategoryPicker extends StatelessWidget {
  final ValueChanged<String> onSelected;
  final String? selected;

  const CategoryPicker({super.key, required this.onSelected, this.selected});

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 12,
    runSpacing: 12,
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
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.standard,
                  minimumSize: const Size(0, 32),
                  fixedSize: Size.fromHeight(
                    (MediaQuery.textScalerOf(context).scale(18) + 14).clamp(
                      32,
                      double.infinity,
                    ),
                  ),
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
