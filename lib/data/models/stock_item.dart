class StockItem {
  final String id, name, category, unit;
  final DateTime updatedAt;
  final int quantity, version;
  final bool publicQuantity, visible, distributable, acceptsDonation;
  StockItem(Map<String, dynamic> data)
      : id = data['id'] as String,
        name = data['name'] as String,
        category = data['category'] as String,
        unit = data['unit'] as String,
        quantity = data['quantity'] as int,
        version = data['version'] as int,
        updatedAt = DateTime.parse(data['updated_at'] as String),
        publicQuantity = data['public_quantity'] == 1,
        visible = data['visible'] == 1,
        distributable = data['distributable'] == 1,
        acceptsDonation = data['accepts_donation'] == 1;
}
