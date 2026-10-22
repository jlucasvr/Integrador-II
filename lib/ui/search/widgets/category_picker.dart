import 'package:flutter/material.dart';

class CategoryPicker extends StatelessWidget {
  final ValueChanged<String> onSelected;

  const CategoryPicker({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) => Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
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
          .map((category) => OutlinedButton(
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  fixedSize: const Size.fromHeight(32),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
              onPressed: () => onSelected(category),
              child: Text(category, style: const TextStyle(fontSize: 12))))
          .toList());
}
