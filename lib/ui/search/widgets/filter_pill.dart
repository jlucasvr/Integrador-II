import 'package:flutter/material.dart';
import 'package:apoio_app/ui/core/theme/interaction_colors.dart';

class FilterPill extends StatelessWidget {
  final bool expanded;
  final VoidCallback onPressed;

  const FilterPill(
      {super.key, required this.expanded, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = expanded ? colors.onPrimary : colors.onSurface;
    return Semantics(
        button: true,
        expanded: expanded,
        child: Material(
            color: expanded ? colors.primary : colors.surface,
            elevation: 4,
            shadowColor: Colors.black26,
            shape: StadiumBorder(
                side: BorderSide(
                    color: expanded ? colors.primary : colors.outline)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
                overlayColor: InteractionColors.overlay(dark: expanded),
                onTap: onPressed,
                customBorder: const StadiumBorder(),
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('Filtros',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge!
                              .copyWith(color: foreground)),
                      const SizedBox(width: 8),
                      Icon(Icons.tune_rounded, size: 20, color: foreground),
                    ])))));
  }
}
