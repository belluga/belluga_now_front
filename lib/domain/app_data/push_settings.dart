class PushSettings {
  final bool enabled;
  final List<String> types;
  final Map<String, dynamic> throttles;

  const PushSettings({
    required this.enabled,
    required this.types,
    required this.throttles,
  });

  static PushSettings? tryFromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final enabled = map['enabled'];
    final typesRaw = map['types'];
    final throttlesRaw = map['throttles'];

    final parsedEnabled = enabled is bool ? enabled : false;
    final parsedTypes = (typesRaw is List)
        ? typesRaw.map((e) => e.toString()).toList(growable: false)
        : const <String>[];
    final parsedThrottles = throttlesRaw is Map<String, dynamic>
        ? Map<String, dynamic>.unmodifiable(throttlesRaw)
        : const <String, dynamic>{};

    return PushSettings(
      enabled: parsedEnabled,
      types: parsedTypes,
      throttles: parsedThrottles,
    );
  }
}
