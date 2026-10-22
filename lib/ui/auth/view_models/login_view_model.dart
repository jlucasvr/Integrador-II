import 'package:apoio_app/core/errors/management_failure.dart';
import 'package:apoio_app/data/repositories/management_repository.dart';
import 'package:flutter/foundation.dart';

class LoginViewModel extends ChangeNotifier {
  final ManagementRepository _repository;
  bool busy = false;
  String? error;
  bool _disposed = false;

  LoginViewModel(this._repository);

  Future<void> login(String email, String password) async {
    if (busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await _repository.login(email, password);
    } on ManagementFailure catch (failure) {
      error = failure.message;
    } catch (_) {
      error = 'Não foi possível concluir o acesso. Tente novamente.';
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
