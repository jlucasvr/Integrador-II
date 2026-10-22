import 'package:apoio_app/core/errors/management_failure.dart';
import 'package:flutter/material.dart';

class LoadFailure extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;
  const LoadFailure({super.key, required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(error is ManagementFailure
            ? (error as ManagementFailure).message
            : 'Não foi possível carregar as informações.'),
        const SizedBox(height: 16),
        OutlinedButton(
            onPressed: onRetry, child: const Text('Tentar novamente')),
      ]));
}
