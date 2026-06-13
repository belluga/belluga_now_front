import 'package:get_it/get_it.dart';

class RouteInstanceStore {
  RouteInstanceStore({
    GetIt? getIt,
  }) : _getIt = getIt ?? GetIt.I;

  final GetIt _getIt;
  final Map<Type, Object> _instances = <Type, Object>{};

  T get<T extends Object>() {
    final existing = _instances[T];
    if (existing != null) {
      return existing as T;
    }

    final created = _getIt.get<T>();
    _instances[T] = created;
    return created;
  }

  bool contains<T extends Object>() => _instances.containsKey(T);

  void dispose() {
    final instances = _instances.values.toList(growable: false).reversed;
    _instances.clear();
    for (final instance in instances) {
      if (instance is Disposable) {
        instance.onDispose();
      }
    }
  }
}
