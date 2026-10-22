import 'package:apoio_app/data/models/resource.dart';

String resourceStatus(Resource resource) {
  if (!resource.available) return 'Indisponível para distribuição';
  if (resource.publicQuantity == null) {
    return 'Disponível · quantidade não divulgada';
  }
  return '${resource.publicQuantity} ${resource.unit} disponíveis';
}
