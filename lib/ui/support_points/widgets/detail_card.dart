import 'package:flutter/material.dart';

class DetailCard extends StatelessWidget {
  const DetailCard({super.key, required this.child, this.padding = 20});
  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(28),
    ),
    foregroundDecoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outline),
      borderRadius: BorderRadius.circular(28),
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: EdgeInsets.all(padding), child: child),
  );
}
