import 'package:apoio_app/core/utils/date_formatters.dart';
import 'package:apoio_app/data/models/stock_item.dart';
import 'package:flutter/material.dart';

class StockItemCard extends StatelessWidget {
  final StockItem item;
  final VoidCallback onMove, onHistory;
  const StockItemCard(
      {super.key,
      required this.item,
      required this.onMove,
      required this.onHistory});
  @override
  Widget build(BuildContext context) {
    final s = item;
    return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(s.name, style: Theme.of(context).textTheme.titleMedium),
          Text('Saldo: ${s.quantity} ${s.unit}'),
          Text('Atualizado: ${dateLabel(s.updatedAt)}'),
          Text(!s.visible
              ? 'Item oculto da consulta pública'
              : s.publicQuantity
                  ? 'Quantidade publicada'
                  : 'Quantidade não divulgada'),
          Text(s.distributable && s.quantity > 0
              ? 'Disponível para distribuição'
              : 'Indisponível para distribuição'),
          Text(s.acceptsDonation ? 'Aceita doação' : 'Não aceita doação'),
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 8, children: [
            FilledButton(
                onPressed: () => onMove(), child: const Text('Movimentar')),
            OutlinedButton(
                onPressed: () => onHistory(), child: const Text('Histórico')),
          ]),
          const SizedBox(height: 12),
          const Divider(),
        ]));
  }
}
