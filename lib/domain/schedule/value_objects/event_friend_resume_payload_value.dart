import 'dart:collection';

class EventFriendResumePayloadValue extends MapBase<String, dynamic> {
  EventFriendResumePayloadValue(Map<String, dynamic> raw)
      : _value = Map<String, dynamic>.unmodifiable(
          Map<String, dynamic>.from(raw),
        );

  final Map<String, dynamic> _value;

  Map<String, dynamic> get value => _value;

  @override
  dynamic operator [](Object? key) => _value[key];

  @override
  void operator []=(String key, dynamic value) {
    throw UnsupportedError('EventFriendResumePayloadValue is immutable.');
  }

  @override
  void clear() {
    throw UnsupportedError('EventFriendResumePayloadValue is immutable.');
  }

  @override
  Iterable<String> get keys => _value.keys;

  @override
  dynamic remove(Object? key) {
    throw UnsupportedError('EventFriendResumePayloadValue is immutable.');
  }
}
