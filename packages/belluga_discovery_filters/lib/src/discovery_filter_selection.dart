import 'discovery_filter_policy.dart';

class DiscoveryFilterSelection {
  const DiscoveryFilterSelection({
    this.primaryKeys = const <String>{},
    this.taxonomyTermKeys = const <String, Set<String>>{},
  });

  factory DiscoveryFilterSelection.fromJson(Map<String, Object?> json) {
    final taxonomyTermKeys = <String, Set<String>>{};
    final rawTaxonomyTerms = json['taxonomy_terms'];

    if (rawTaxonomyTerms is Map) {
      for (final entry in rawTaxonomyTerms.entries) {
        final taxonomyKey = entry.key.toString();
        final termKeys = _readStringSet(entry.value);
        if (taxonomyKey.trim().isNotEmpty && termKeys.isNotEmpty) {
          taxonomyTermKeys[taxonomyKey] = termKeys;
        }
      }
    }

    return DiscoveryFilterSelection(
      primaryKeys: _readStringSet(
        json['primary_keys'] ?? json['filters'] ?? json['filter_keys'],
      ),
      taxonomyTermKeys: taxonomyTermKeys,
    );
  }

  final Set<String> primaryKeys;
  final Map<String, Set<String>> taxonomyTermKeys;

  bool get isEmpty => primaryKeys.isEmpty && taxonomyTermKeys.isEmpty;

  bool get isNotEmpty => !isEmpty;

  int get activeCount =>
      primaryKeys.length +
      taxonomyTermKeys.values.fold<int>(
        0,
        (total, terms) => total + terms.length,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'primary_keys': primaryKeys.toList(growable: false),
        'taxonomy_terms': taxonomyTermKeys.map(
          (key, value) => MapEntry<String, Object?>(
            key,
            value.toList(growable: false),
          ),
        ),
      };

  DiscoveryFilterSelection togglePrimary(
    String key, {
    DiscoveryFilterSelectionMode mode = DiscoveryFilterSelectionMode.single,
  }) {
    final normalized = key.trim();
    if (normalized.isEmpty) {
      return this;
    }

    if (mode == DiscoveryFilterSelectionMode.single) {
      return primaryKeys.contains(normalized)
          ? DiscoveryFilterSelection(taxonomyTermKeys: taxonomyTermKeys)
          : DiscoveryFilterSelection(
              primaryKeys: <String>{normalized},
              taxonomyTermKeys: taxonomyTermKeys,
            );
    }

    final next = Set<String>.of(primaryKeys);
    if (!next.add(normalized)) {
      next.remove(normalized);
    }

    return DiscoveryFilterSelection(
      primaryKeys: next,
      taxonomyTermKeys: taxonomyTermKeys,
    );
  }

  DiscoveryFilterSelection toggleTaxonomyTerm(
    String taxonomyKey,
    String termKey, {
    DiscoveryFilterSelectionMode mode = DiscoveryFilterSelectionMode.multiple,
  }) {
    final normalizedTaxonomy = taxonomyKey.trim();
    final normalizedTerm = termKey.trim();

    if (normalizedTaxonomy.isEmpty || normalizedTerm.isEmpty) {
      return this;
    }

    final next = taxonomyTermKeys.map(
      (key, value) => MapEntry<String, Set<String>>(key, Set<String>.of(value)),
    );

    if (mode == DiscoveryFilterSelectionMode.single) {
      final current = next[normalizedTaxonomy] ?? const <String>{};
      if (current.contains(normalizedTerm)) {
        next.remove(normalizedTaxonomy);
      } else {
        next[normalizedTaxonomy] = <String>{normalizedTerm};
      }
    } else {
      final terms = next.putIfAbsent(normalizedTaxonomy, () => <String>{});
      if (!terms.add(normalizedTerm)) {
        terms.remove(normalizedTerm);
      }
      if (terms.isEmpty) {
        next.remove(normalizedTaxonomy);
      }
    }

    return DiscoveryFilterSelection(
      primaryKeys: primaryKeys,
      taxonomyTermKeys: next,
    );
  }
}

Set<String> _readStringSet(Object? value) {
  if (value == null) {
    return const <String>{};
  }
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? const <String>{} : <String>{trimmed};
  }
  if (value is Iterable) {
    return value
        .whereType<Object?>()
        .map((value) => value?.toString().trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toSet();
  }
  return const <String>{};
}
