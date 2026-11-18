import 'package:flutter/material.dart';

class PageBody extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const PageBody({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: Padding(padding: padding, child: child),
    ),
  );
}
