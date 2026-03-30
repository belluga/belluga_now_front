import 'dart:collection';

class TenantAdminTrimmedStringListValue extends ListBase<String> {
  TenantAdminTrimmedStringListValue([Iterable<String>? rawValues])
      : _value = List<String>.unmodifiable(_sanitize(rawValues));

  final List<String> _value;

  List<String> get value => _value;

  bool get isEmpty => _value.isEmpty;

  @override
  int get length => _value.length;

  @override
  set length(int newLength) {
    throw UnsupportedError('TenantAdminTrimmedStringListValue is immutable.');
  }

  @override
  String operator [](int index) => _value[index];

  @override
  void operator []=(int index, String value) {
    throw UnsupportedError('TenantAdminTrimmedStringListValue is immutable.');
  }

  static List<String> _sanitize(Iterable<String>? rawValues) {
    if (rawValues == null) {
      return const <String>[];
    }

    final result = <String>[];
    final seen = <String>{};
    for (final raw in rawValues) {
      final normalized = raw.trim();
      if (normalized.isEmpty || !seen.add(normalized)) {
        continue;
      }
      result.add(normalized);
    }
    return result;
  }
}
