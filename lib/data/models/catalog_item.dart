class CatalogItem {
  final String id, name, category, unit;

  CatalogItem(Map<String, dynamic> data)
      : id = data['id'] as String,
        name = data['name'] as String,
        category = data['category'] as String,
        unit = data['unit'] as String;
}
