part 'discovery_filter_entity_provider.dart';
part 'discovery_filter_taxonomy_option.dart';
part 'discovery_filter_type_option.dart';

class DiscoveryFilterEntityRegistry {
  DiscoveryFilterEntityRegistry({
    Iterable<DiscoveryFilterEntityProvider> providers = const [],
  }) {
    for (final provider in providers) {
      register(provider);
    }
  }

  final Map<String, DiscoveryFilterEntityProvider> _providers =
      <String, DiscoveryFilterEntityProvider>{};

  void register(DiscoveryFilterEntityProvider provider) {
    final entity = provider.entity.trim().toLowerCase();
    if (entity.isEmpty) {
      throw ArgumentError.value(
        provider.entity,
        'provider.entity',
        'Discovery filter provider entity cannot be empty.',
      );
    }
    _providers[entity] = provider;
  }

  DiscoveryFilterEntityProvider? providerFor(String entity) {
    return _providers[entity.trim().toLowerCase()];
  }

  Set<String> get entities => _providers.keys.toSet();

  Map<String, List<DiscoveryFilterTypeOption>> typeOptionsForEntities(
    Iterable<String> entities,
  ) {
    final resolved = <String, List<DiscoveryFilterTypeOption>>{};
    for (final entity in entities) {
      final normalized = entity.trim().toLowerCase();
      final provider = providerFor(normalized);
      if (provider == null) {
        continue;
      }
      resolved[normalized] = provider
          .typeOptions()
          .where((option) => option.isValid)
          .toList(growable: false);
    }
    return resolved;
  }
}

Map<String, Object?> _readMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return value.map(
      (key, value) => MapEntry<String, Object?>(key.toString(), value),
    );
  }
  return const <String, Object?>{};
}

String? _readString(Object? value) {
  if (value is! String) {
    return null;
  }

  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

Set<String> _readStringSet(Object? value) {
  if (value == null) {
    return const <String>{};
  }
  if (value is String) {
    final normalized = _readString(value);
    return normalized == null ? const <String>{} : <String>{normalized};
  }
  if (value is Iterable) {
    return value.map(_readString).whereType<String>().toSet();
  }
  return const <String>{};
}
