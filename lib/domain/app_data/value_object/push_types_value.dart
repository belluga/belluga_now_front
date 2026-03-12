class PushTypesValue {
  PushTypesValue([Iterable<String>? rawTypes])
      : _value = List<String>.unmodifiable(_sanitize(rawTypes));

  final List<String> _value;

  List<String> get value => _value;

  static List<String> _sanitize(Iterable<String>? rawTypes) {
    if (rawTypes == null) {
      return const <String>[];
    }

    final ordered = <String>[];
    final seen = <String>{};
    for (final raw in rawTypes) {
      final normalized = raw.trim();
      if (normalized.isEmpty || !seen.add(normalized)) {
        continue;
      }
      ordered.add(normalized);
    }
    return ordered;
  }
}
