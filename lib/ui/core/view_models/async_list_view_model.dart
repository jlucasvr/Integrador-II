import 'package:flutter/foundation.dart';

/// Owns the request and refresh lifecycle for a list screen.
class AsyncListViewModel<T> extends ChangeNotifier {
  final Future<List<T>> Function() _load;
  late Future<List<T>> request;

  AsyncListViewModel(this._load) {
    request = _load();
  }

  void reload() {
    request = _load();
    notifyListeners();
  }
}
