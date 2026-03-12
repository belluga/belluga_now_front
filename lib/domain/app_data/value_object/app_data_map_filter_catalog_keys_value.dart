class AppDataMapFilterCatalogKeysValue {
  AppDataMapFilterCatalogKeysValue([Iterable<String>? rawKeys])
      : _value = List<String>.unmodifiable(_sanitize(rawKeys));

  final List<String> _value;

  List<String> get value => _value;

  static List<String> _sanitize(Iterable<String>? rawKeys) {
    if (rawKeys == null) {
      return const <String>[];
    }

    final ordered = <String>[];
    final seen = <String>{};
    for (final raw in rawKeys) {
      final normalized = raw.trim().toLowerCase();
      if (normalized.isEmpty || !seen.add(normalized)) {
        continue;
      }
      ordered.add(normalized);
    }
    return ordered;
  }
}
