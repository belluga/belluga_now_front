import 'dart:convert';

import 'package:belluga_now/domain/app_data/discovery_filter_selection_snapshot.dart';
import 'package:belluga_now/domain/app_data/value_object/app_data_discovery_filter_token_value.dart';

class AppDataDiscoveryFilterSelectionCodec {
  const AppDataDiscoveryFilterSelectionCodec();

  AppDataDiscoveryFilterSelectionSnapshot? decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return null;
    }
    final map = decoded.map(
      (key, value) => MapEntry<String, Object?>(key.toString(), value),
    );
    return AppDataDiscoveryFilterSelectionSnapshot(
      primaryKeys: _readTokenList(map['primary_keys']),
      taxonomySelections: _readTaxonomySelections(map['taxonomy_terms']),
    );
  }

  String encode(AppDataDiscoveryFilterSelectionSnapshot selection) {
    return jsonEncode(<String, Object?>{
      'primary_keys': selection.primaryKeys
          .map((value) => value.value)
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
      'taxonomy_terms': <String, Object?>{
        for (final taxonomy in selection.taxonomySelections)
          if (!taxonomy.isEmpty)
            taxonomy.taxonomyKey.value: taxonomy.termKeys
                .map((value) => value.value)
                .where((value) => value.isNotEmpty)
                .toList(growable: false),
      },
    });
  }

  bool isEmpty(AppDataDiscoveryFilterSelectionSnapshot selection) =>
      selection.isEmpty;

  List<AppDataDiscoveryFilterTokenValue> _readTokenList(Object? raw) {
    if (raw is! Iterable) {
      return const <AppDataDiscoveryFilterTokenValue>[];
    }
    return raw
        .map(AppDataDiscoveryFilterTokenValue.fromRaw)
        .where((value) => value.value.isNotEmpty)
        .toList(growable: false);
  }

  List<AppDataDiscoveryFilterTaxonomySelection> _readTaxonomySelections(
    Object? raw,
  ) {
    if (raw is! Map) {
      return const <AppDataDiscoveryFilterTaxonomySelection>[];
    }
    final selections = <AppDataDiscoveryFilterTaxonomySelection>[];
    for (final entry in raw.entries) {
      final taxonomyKey = AppDataDiscoveryFilterTokenValue.fromRaw(entry.key);
      final termKeys = _readTokenList(entry.value);
      if (taxonomyKey.value.isEmpty || termKeys.isEmpty) {
        continue;
      }
      selections.add(
        AppDataDiscoveryFilterTaxonomySelection(
          taxonomyKey: taxonomyKey,
          termKeys: termKeys,
        ),
      );
    }
    return selections;
  }
}
