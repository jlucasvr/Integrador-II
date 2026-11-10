import 'package:apoio_app/core/utils/date_formatters.dart';
import 'package:apoio_app/data/models/stock_item.dart';
import 'package:apoio_app/ui/management/widgets/operation_layout.dart';
import 'package:flutter/material.dart';

class StockItemCard extends StatelessWidget {
  const StockItemCard({
    super.key,
    required this.item,
    required this.onMove,
    required this.onPublication,
    required this.onHistory,
    required this.wide,
  });

  static const columns = [18, 19, 16, 19, 28];
  final StockItem item;
  final VoidCallback onMove, onHistory, onPublication;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final name = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(item.name, style: theme.titleMedium),
        Text(item.category, style: theme.bodySmall),
      ],
    );
    final balance = Text(
      'Saldo: ${item.quantity} ${item.unit}',
      style: theme.titleSmall,
    );
    final available = item.distributable && item.quantity > 0;
    final distribution = OperationStatus(
      available
          ? 'Disponível para distribuição'
          : 'Indisponível para distribuição',
      available ? Icons.check_circle_outline : Icons.remove_circle_outline,
    );
    final publication = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OperationStatus(
          item.visible
              ? 'Exibição pública habilitada'
              : 'Item oculto da consulta pública',
          item.visible
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
        ),
        if (item.visible)
          Text(
            item.publicQuantity
                ? 'Quantidade publicada'
                : 'Quantidade não divulgada',
            style: theme.bodySmall,
          ),
        Text(
          item.acceptsDonation ? 'Aceita doação' : 'Não aceita doação',
          style: theme.bodySmall,
        ),
      ],
    );
    final actions = Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        FilledButton(onPressed: onMove, child: const Text('Movimentar')),
        TextButton(
          style: wide
              ? TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                )
              : null,
          onPressed: onPublication,
          child: const Text('Publicação'),
        ),
        TextButton(
          style: wide
              ? TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                )
              : null,
          onPressed: onHistory,
          child: const Text('Histórico'),
        ),
      ],
    );
    final date = Text(
      'Atualizado: ${dateLabel(item.updatedAt)}',
      style: theme.bodySmall,
    );

    if (wide) {
      return OperationColumns(
        widths: columns,
        cells: [
          name,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [balance, date],
          ),
          distribution,
          publication,
          actions,
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          name,
          const SizedBox(height: 8),
          balance,
          date,
          const SizedBox(height: 8),
          distribution,
          publication,
          const SizedBox(height: 8),
          actions,
          const Divider(),
        ],
      ),
    );
  }
}
