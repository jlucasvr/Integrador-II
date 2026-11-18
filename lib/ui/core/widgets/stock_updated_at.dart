import 'package:flutter/material.dart';

String stockUpdateDate(String value) {
  final formatted = RegExp(
    r'^(\d{1,2})/(\d{1,2})/(\d{4})(?:\b|,)',
  ).firstMatch(value.trim());
  if (formatted != null) {
    final day = int.parse(formatted[1]!);
    final month = int.parse(formatted[2]!);
    final year = int.parse(formatted[3]!);
    final date = DateTime(year, month, day);
    if (date.day == day && date.month == month && date.year == year) {
      return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
    }
    return 'Data não informada';
  }
  final date = DateTime.tryParse(value.trim())?.toLocal();
  if (date == null) return 'Data não informada';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class StockUpdatedAt extends StatelessWidget {
  const StockUpdatedAt({super.key, required this.value});
  final String value;

  @override
  Widget build(BuildContext context) {
    final date = stockUpdateDate(value);
    final description = date == 'Data não informada'
        ? 'Data de atualização do estoque não informada'
        : 'Última atualização do estoque: $date';
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: description,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.update_rounded, size: 14, color: colors.onSurfaceVariant),
          const SizedBox(width: 5),
          Flexible(
            child: Tooltip(
              message: description,
              excludeFromSemantics: true,
              triggerMode: TooltipTriggerMode.manual,
              child: Text(
                date,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall!.copyWith(fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
