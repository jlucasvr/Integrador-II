class StockMovement {
  final String type, note, responsible;
  final int quantity, previousBalance, resultingBalance;
  final DateTime createdAt;
  StockMovement(Map<String, dynamic> data)
      : type = data['type'] as String,
        note = data['note'] as String,
        responsible = data['user_name'] as String? ?? data['user_id'] as String,
        quantity = data['quantity'] as int,
        previousBalance = data['previous_balance'] as int,
        resultingBalance = data['resulting_balance'] as int,
        createdAt = DateTime.parse(data['created_at'] as String);
}
