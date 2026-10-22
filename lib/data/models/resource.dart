class Resource {
  final String name;
  final String category;
  final String unit;
  final bool available;
  final bool acceptsDonation;
  final int? publicQuantity;
  final String? updatedAt;
  const Resource(this.name, this.category, this.unit, this.available,
      this.acceptsDonation, this.publicQuantity,
      {this.updatedAt});
}
