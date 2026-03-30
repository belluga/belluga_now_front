import 'dart:collection';

class TenantAdminDynamicMapValue extends MapBase<String, dynamic> {
  TenantAdminDynamicMapValue([Map<String, dynamic>? rawMap])
      : _value = Map<String, dynamic>.unmodifiable(
          rawMap == null
              ? const <String, dynamic>{}
              : Map<String, dynamic>.from(rawMap),
        );

  final Map<String, dynamic> _value;

  Map<String, dynamic> get value => _value;

  @override
  bool get isEmpty => _value.isEmpty;

  @override
  dynamic operator [](Object? key) => _value[key];

  @override
  void operator []=(String key, dynamic value) {
    throw UnsupportedError('TenantAdminDynamicMapValue is immutable.');
  }

  @override
  void clear() {
    throw UnsupportedError('TenantAdminDynamicMapValue is immutable.');
  }

  @override
  Iterable<String> get keys => _value.keys;

  @override
  dynamic remove(Object? key) {
    throw UnsupportedError('TenantAdminDynamicMapValue is immutable.');
  }
}
