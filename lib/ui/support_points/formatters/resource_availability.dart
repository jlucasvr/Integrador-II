import 'package:apoio_app/data/models/resource.dart';

/// Faixas indicativas por item, não porcentagens de capacidade do estoque.
enum ResourceAvailability {
  unavailable('Indisponível', null),
  empty('Sem estoque', 0),
  low('Poucas unidades', .15),
  medium('Estoque moderado', .5),
  high('Boa disponibilidade', 1),
  undisclosed('Disponível · confirme no contato', null);

  const ResourceAvailability(this.label, this.fill);
  final String label;
  final double? fill;

  static ResourceAvailability of(Resource resource) {
    final quantity = resource.publicQuantity;
    if (!resource.available) return quantity == 0 ? empty : unavailable;
    if (quantity == null) return undisclosed;
    if (quantity <= 0) return empty;
    if (quantity <= 10) return low;
    if (quantity <= 50) return medium;
    return high;
  }
}
