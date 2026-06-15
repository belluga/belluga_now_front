import 'discovery_filter_catalog.dart';
import 'discovery_filter_entity_registry.dart';

class DiscoveryFilterRuntimeFacets {
  const DiscoveryFilterRuntimeFacets({
    required this.surface,
    this.filterKeys = const <String>{},
    this.taxonomyOptionsByKey =
        const <String, DiscoveryFilterTaxonomyGroupOption>{},
  });

  factory DiscoveryFilterRuntimeFacets.fromJson(Map<String, Object?> json) {
    final taxonomyOptionsByKey = <String, DiscoveryFilterTaxonomyGroupOption>{};
    final rawTaxonomyOptions = _runtimeReadMap(json['taxonomy_options']);

    for (final entry in rawTaxonomyOptions.entries) {
      final taxonomyKey = _runtimeReadString(entry.key);
      if (taxonomyKey == null) {
        continue;
      }

      final option = DiscoveryFilterTaxonomyGroupOption.fromJson(
        taxonomyKey,
        _runtimeReadMap(entry.value),
      );
      if (option.isValid) {
        taxonomyOptionsByKey[taxonomyKey] = option;
      }
    }

    return DiscoveryFilterRuntimeFacets(
      surface: _runtimeReadString(json['surface']) ?? '',
      filterKeys: _runtimeReadStringSet(json['filter_keys']),
      taxonomyOptionsByKey: taxonomyOptionsByKey,
    );
  }

  final String surface;
  final Set<String> filterKeys;
  final Map<String, DiscoveryFilterTaxonomyGroupOption> taxonomyOptionsByKey;

  bool get isEmpty => filterKeys.isEmpty && taxonomyOptionsByKey.isEmpty;

  DiscoveryFilterCatalog applyToCatalog(
    DiscoveryFilterCatalog baseline, {
    bool preservePrimaryFilters = false,
  }) {
    final normalizedKeys = filterKeys
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();

    final filters = preservePrimaryFilters
        ? baseline.filters.toList(growable: false)
        : baseline.filters
            .where((item) => normalizedKeys.contains(item.key))
            .toList(growable: false);

    final typeOptionsByEntity = <String, List<DiscoveryFilterTypeOption>>{};
    for (final entry in baseline.typeOptionsByEntity.entries) {
      final filtered = preservePrimaryFilters
          ? entry.value.toList(growable: false)
          : entry.value
              .where((option) => normalizedKeys.contains(option.value))
              .toList(growable: false);
      if (filtered.isNotEmpty) {
        typeOptionsByEntity[entry.key] = filtered;
      }
    }

    final taxonomyOptions = <String, DiscoveryFilterTaxonomyGroupOption>{};
    for (final entry in taxonomyOptionsByKey.entries) {
      final baselineOption = baseline.taxonomyOptionsByKey[entry.key];
      taxonomyOptions[entry.key] = DiscoveryFilterTaxonomyGroupOption(
        key: entry.value.key,
        label: baselineOption?.label ?? entry.value.label,
        terms: entry.value.terms,
        termsTruncated: entry.value.termsTruncated,
        termsLimit: entry.value.termsLimit,
      );
    }

    return DiscoveryFilterCatalog(
      surface: baseline.surface,
      filters: filters,
      typeOptionsByEntity: typeOptionsByEntity,
      taxonomyOptionsByKey: taxonomyOptions,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'surface': surface,
        'filter_keys': filterKeys.toList(growable: false),
        'taxonomy_options': taxonomyOptionsByKey.map(
          (key, value) => MapEntry<String, Object?>(key, value.toJson()),
        ),
      };
}

Map<String, Object?> _runtimeReadMap(Object? value) {
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

String? _runtimeReadString(Object? value) {
  if (value is! String) {
    return null;
  }

  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

Set<String> _runtimeReadStringSet(Object? value) {
  if (value == null) {
    return const <String>{};
  }
  if (value is String) {
    final normalized = _runtimeReadString(value);
    return normalized == null ? const <String>{} : <String>{normalized};
  }
  if (value is Iterable) {
    return value.map(_runtimeReadString).whereType<String>().toSet();
  }
  return const <String>{};
}
