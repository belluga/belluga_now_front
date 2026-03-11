class TenantAdminDynamicMapValue {
  TenantAdminDynamicMapValue([Map<String, dynamic>? rawMap])
      : _value = Map<String, dynamic>.unmodifiable(
          rawMap == null
              ? const <String, dynamic>{}
              : Map<String, dynamic>.from(rawMap),
        );

  final Map<String, dynamic> _value;

  Map<String, dynamic> get value => _value;

  bool get isEmpty => _value.isEmpty;
}
