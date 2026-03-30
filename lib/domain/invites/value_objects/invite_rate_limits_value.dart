import 'dart:collection';

class InviteRateLimitsValue extends MapBase<String, int> {
  InviteRateLimitsValue([Map<String, int>? raw])
      : value = Map<String, int>.unmodifiable(raw ?? const <String, int>{});

  final Map<String, int> value;

  @override
  int? operator [](Object? key) => value[key];

  @override
  void operator []=(String key, int value) {
    throw UnsupportedError('InviteRateLimitsValue is immutable.');
  }

  @override
  void clear() {
    throw UnsupportedError('InviteRateLimitsValue is immutable.');
  }

  @override
  Iterable<String> get keys => value.keys;

  @override
  int? remove(Object? key) {
    throw UnsupportedError('InviteRateLimitsValue is immutable.');
  }
}
