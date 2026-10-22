import 'package:apoio_app/core/utils/date_formatters.dart';
import 'package:apoio_app/data/models/movement_type.dart';
import 'package:apoio_app/data/models/stock_movement.dart';
import 'package:flutter/material.dart';

class StockMovementTile extends StatelessWidget {
  final StockMovement movement;
  final String unit;
  const StockMovementTile(
      {super.key, required this.movement, required this.unit});
  @override
  Widget build(BuildContext context) {
    final m = movement;
    return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(
              '${MovementType.values.firstWhere((t) => t.name == m.type).label}: ${m.quantity} $unit',
              style: Theme.of(context).textTheme.titleMedium),
          Text('Saldo: ${m.previousBalance} → ${m.resultingBalance}'),
          Text(dateLabel(m.createdAt)),
          Text('Responsável: ${m.responsible}'),
          if (m.note.isNotEmpty) Text(m.note),
          const Divider(),
        ]));
  }
}
