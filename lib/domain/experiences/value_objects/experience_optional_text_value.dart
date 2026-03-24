class ExperienceOptionalTextValue {
  ExperienceOptionalTextValue([String? raw]) : value = _sanitize(raw);

  final String? value;

  static String? _sanitize(String? raw) {
    final normalized = raw?.trim();
    return (normalized == null || normalized.isEmpty) ? null : normalized;
  }
}
