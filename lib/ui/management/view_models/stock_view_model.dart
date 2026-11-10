import 'package:apoio_app/core/utils/normalize.dart';
import 'package:apoio_app/data/models/managed_point.dart';
import 'package:apoio_app/data/models/stock_item.dart';
import 'package:apoio_app/data/repositories/management_repository.dart';
import 'package:apoio_app/ui/core/view_models/async_list_view_model.dart';

enum StockFilter {
  all('Todos'),
  empty('Sem saldo'),
  hidden('Ocultos'),
  available('Para distribuição');

  const StockFilter(this.label);
  final String label;

  bool matches(StockItem item) => switch (this) {
    all => true,
    empty => item.quantity == 0,
    hidden => !item.visible,
    available => item.distributable && item.quantity > 0,
  };
}

class StockViewModel extends AsyncListViewModel<StockItem> {
  String _search = '';
  StockFilter _status = StockFilter.all;
  StockFilter get status => _status;

  StockViewModel(ManagementRepository repository, ManagedPoint point)
    : super(() => repository.stock(point.id));

  void search(String value) {
    _search = normalize(value);
    notifyListeners();
  }

  void select(StockFilter value) {
    _status = value;
    notifyListeners();
  }

  List<StockItem> filter(List<StockItem> items) => items
      .where(
        (item) =>
            _status.matches(item) &&
            normalize('${item.name} ${item.category}').contains(_search),
      )
      .toList();
}
