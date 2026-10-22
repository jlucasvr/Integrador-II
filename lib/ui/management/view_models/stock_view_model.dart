import 'package:apoio_app/core/utils/normalize.dart';
import 'package:apoio_app/data/models/managed_point.dart';
import 'package:apoio_app/data/models/stock_item.dart';
import 'package:apoio_app/data/repositories/management_repository.dart';
import 'package:apoio_app/ui/core/view_models/async_list_view_model.dart';

class StockViewModel extends AsyncListViewModel<StockItem> {
  String _search = '';

  StockViewModel(ManagementRepository repository, ManagedPoint point)
      : super(() => repository.stock(point.id));

  void search(String value) {
    _search = normalize(value);
    notifyListeners();
  }

  List<StockItem> filter(List<StockItem> items) => items
      .where((item) =>
          normalize('${item.name} ${item.category}').contains(_search))
      .toList();
}
