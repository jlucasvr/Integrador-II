import 'package:apoio_app/core/errors/management_failure.dart';
import 'package:apoio_app/data/models/movement_type.dart';
import 'package:apoio_app/data/models/stock_item.dart';
import 'package:apoio_app/data/repositories/management_repository.dart';
import 'package:flutter/foundation.dart';

class MovementViewModel extends ChangeNotifier {
  final ManagementRepository _repository;
  final StockItem item;
  MovementType type = MovementType.entry;
  bool busy = false;
  bool needsReload = false;
  String? error;
  bool _disposed = false;

  MovementViewModel(this._repository, this.item);

  void setType(MovementType value) {
    type = value;
    notifyListeners();
  }

  int? balance(String quantity) {
    final q = int.tryParse(quantity);
    if (q == null || q < 0 || q > 1000000000) return null;
    return switch (type) {
      MovementType.entry => item.quantity + q,
      MovementType.exit => item.quantity - q,
      MovementType.adjustment => q,
    };
  }

  String? validateQuantity(String? value) {
    final q = int.tryParse(value ?? '');
    if (q == null || q < 0 || q > 1000000000) {
      return 'Informe uma quantidade inteira válida.';
    }
    if (type != MovementType.adjustment && q == 0) {
      return 'Informe uma quantidade maior que zero.';
    }
    if (type == MovementType.exit && q > item.quantity) {
      return 'A saída excede o saldo de ${item.quantity}.';
    }
    if (type == MovementType.entry && item.quantity + q > 1000000000) {
      return 'O saldo máximo foi excedido.';
    }
    return null;
  }

  Future<bool> submit(String quantity, String note) async {
    if (busy || needsReload || validateQuantity(quantity) != null) return false;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await _repository.move(item, type, int.parse(quantity), note);
      return true;
    } on ManagementFailure catch (failure) {
      needsReload = failure.status == 409 || failure.uncertain;
      error = failure.uncertain
          ? 'Não recebemos confirmação. Confira o saldo e o histórico antes de repetir a movimentação.'
          : failure.message;
      return false;
    } catch (_) {
      needsReload = true;
      error = 'Confira o saldo e o histórico antes de tentar novamente.';
      return false;
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
