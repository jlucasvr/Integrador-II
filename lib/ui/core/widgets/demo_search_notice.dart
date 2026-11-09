import 'package:flutter/material.dart';

class DemoSearchNotice extends StatelessWidget {
  const DemoSearchNotice({super.key});

  @override
  Widget build(BuildContext context) => Text(
        'Demonstração · dados fictícios',
        style: Theme.of(context).textTheme.labelLarge,
      );
}
