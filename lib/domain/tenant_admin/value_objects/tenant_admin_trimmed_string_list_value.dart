class TenantAdminTrimmedStringListValue {
  TenantAdminTrimmedStringListValue([Iterable<String>? rawValues])
      : _value = List<String>.unmodifiable(_sanitize(rawValues));

  final List<String> _value;

  List<String> get value => _value;

  bool get isEmpty => _value.isEmpty;

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
