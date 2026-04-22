import 'discovery_filter_catalog.dart';
import 'discovery_filter_selection.dart';

part 'discovery_filter_taxonomy_query_entry.dart';

class DiscoveryFilterQueryPayload {
  const DiscoveryFilterQueryPayload({
    this.entities = const <String>{},
    this.typesByEntity = const <String, Set<String>>{},
    this.taxonomyTermsByGroup = const <String, Set<String>>{},
  });

  factory DiscoveryFilterQueryPayload.compile({
    required DiscoveryFilterCatalog catalog,
    required DiscoveryFilterSelection selection,
  }) {
    final selectedItems = catalog.filters
        .where((item) => selection.primaryKeys.contains(item.key))
        .toList(growable: false);
    final entities = <String>{};
    final typesByEntity = <String, Set<String>>{};
    final taxonomyTermsByGroup = <String, Set<String>>{};

    for (final item in selectedItems) {
      entities.addAll(item.entities);
      for (final entry in item.typesByEntity.entries) {
        typesByEntity
            .putIfAbsent(entry.key, () => <String>{})
            .addAll(entry.value);
      }

      if (item.typesByEntity.isEmpty &&
          item.types.isNotEmpty &&
          item.entities.length == 1) {
        typesByEntity
            .putIfAbsent(item.entities.single, () => <String>{})
            .addAll(item.types);
      }

      for (final entry in item.taxonomyValuesByGroup.entries) {
        taxonomyTermsByGroup
            .putIfAbsent(entry.key, () => <String>{})
            .addAll(entry.value);
      }
    }

    for (final entry in selection.taxonomyTermKeys.entries) {
      taxonomyTermsByGroup
          .putIfAbsent(entry.key, () => <String>{})
          .addAll(entry.value);
    }

    return DiscoveryFilterQueryPayload(
      entities: entities,
      typesByEntity: typesByEntity,
      taxonomyTermsByGroup: taxonomyTermsByGroup,
    );
  }

  final Set<String> entities;
  final Map<String, Set<String>> typesByEntity;
  final Map<String, Set<String>> taxonomyTermsByGroup;

  bool get isEmpty =>
      entities.isEmpty && typesByEntity.isEmpty && taxonomyTermsByGroup.isEmpty;

  Set<String> typesForEntity(String entity) {
    final normalized = entity.trim();
    return normalized.isEmpty
        ? const <String>{}
        : Set<String>.of(typesByEntity[normalized] ?? const <String>{});
  }

  List<DiscoveryFilterTaxonomyQueryEntry> get taxonomyEntries =>
      taxonomyTermsByGroup.entries
          .expand(
            (entry) => entry.value.map(
              (value) => DiscoveryFilterTaxonomyQueryEntry(
                type: entry.key,
                value: value,
              ),
            ),
          )
          .toList(growable: false);

  Map<String, Object?> toJson() => <String, Object?>{
        'entities': entities.toList(growable: false),
        'types_by_entity': typesByEntity.map(
          (key, value) => MapEntry<String, Object?>(
            key,
            value.toList(growable: false),
          ),
        ),
        'taxonomy': taxonomyTermsByGroup.map(
          (key, value) => MapEntry<String, Object?>(
            key,
            value.toList(growable: false),
          ),
        ),
      };
}
