import 'package:flutter/material.dart';

class PageBody extends StatelessWidget {
  final Widget child;
  const PageBody({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Padding(padding: const EdgeInsets.all(20), child: child)));
}
