import 'dart:collection';

class InviteCooldownsValue extends MapBase<String, int> {
  InviteCooldownsValue([Map<String, int>? raw])
      : value = Map<String, int>.unmodifiable(raw ?? const <String, int>{});

  final Map<String, int> value;

  @override
  int? operator [](Object? key) => value[key];

  @override
  void operator []=(String key, int value) {
    throw UnsupportedError('InviteCooldownsValue is immutable.');
  }

  @override
  void clear() {
    throw UnsupportedError('InviteCooldownsValue is immutable.');
  }

  @override
  Iterable<String> get keys => value.keys;

  @override
  int? remove(Object? key) {
    throw UnsupportedError('InviteCooldownsValue is immutable.');
  }
}
