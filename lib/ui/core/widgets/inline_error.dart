import 'package:flutter/material.dart';

class InlineError extends StatelessWidget {
  final String message;

  const InlineError(this.message, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Semantics(
          liveRegion: true,
          child: Text(message,
              style: TextStyle(color: Theme.of(context).colorScheme.error))));
}
