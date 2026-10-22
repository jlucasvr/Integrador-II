import 'package:flutter/material.dart';

class ResultBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool emphasized;

  const ResultBadge(
      {super.key,
      required this.label,
      required this.icon,
      this.emphasized = false});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = emphasized ? colors.onPrimary : colors.onSurfaceVariant;
    return DecoratedBox(
        decoration: ShapeDecoration(
            color: emphasized ? colors.primary : colors.surfaceContainerHighest,
            shape: StadiumBorder(
                side: BorderSide(
                    color: emphasized ? colors.primary : colors.outline))),
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 15, color: foreground),
              const SizedBox(width: 6),
              Flexible(
                  child: Text(label,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall!
                          .copyWith(color: foreground))),
            ])));
  }
}
