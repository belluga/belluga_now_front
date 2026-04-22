import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_dynamic_map_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';

class TenantAdminDiscoveryFilterQuery {
  TenantAdminDiscoveryFilterQuery({
    Iterable<TenantAdminLowercaseTokenValue>? entityValues,
    Map<String, Iterable<TenantAdminLowercaseTokenValue>>? typeValuesByEntity,
    Map<String, Iterable<TenantAdminLowercaseTokenValue>>?
        taxonomyValuesByGroup,
  })  : entityValues = List<TenantAdminLowercaseTokenValue>.unmodifiable(
          _normalizeTokens(entityValues),
        ),
        typeValuesByEntity =
            Map<String, List<TenantAdminLowercaseTokenValue>>.unmodifiable(
                _normalizeTokenMap(typeValuesByEntity)),
        taxonomyValuesByGroup =
            Map<String, List<TenantAdminLowercaseTokenValue>>.unmodifiable(
          _normalizeTokenMap(taxonomyValuesByGroup),
        );

  final List<TenantAdminLowercaseTokenValue> entityValues;
  final Map<String, List<TenantAdminLowercaseTokenValue>> typeValuesByEntity;
  final Map<String, List<TenantAdminLowercaseTokenValue>> taxonomyValuesByGroup;

  List<String> get entities =>
      entityValues.map((entry) => entry.value).toList(growable: false);

  bool get isEmpty =>
      entityValues.isEmpty &&
      typeValuesByEntity.isEmpty &&
      taxonomyValuesByGroup.isEmpty;

  TenantAdminDiscoveryFilterQuery copyWith({
    Iterable<TenantAdminLowercaseTokenValue>? entityValues,
    Map<String, Iterable<TenantAdminLowercaseTokenValue>>? typeValuesByEntity,
    Map<String, Iterable<TenantAdminLowercaseTokenValue>>?
        taxonomyValuesByGroup,
  }) {
    return TenantAdminDiscoveryFilterQuery(
      entityValues: entityValues ?? this.entityValues,
      typeValuesByEntity: typeValuesByEntity ?? this.typeValuesByEntity,
      taxonomyValuesByGroup:
          taxonomyValuesByGroup ?? this.taxonomyValuesByGroup,
    );
  }

  TenantAdminDynamicMapValue toJson() {
    return TenantAdminDynamicMapValue({
      if (entityValues.isNotEmpty)
        'entities':
            entityValues.map((entry) => entry.value).toList(growable: false),
      if (typeValuesByEntity.isNotEmpty)
        'types_by_entity': {
          for (final entry in typeValuesByEntity.entries)
            entry.key:
                entry.value.map((token) => token.value).toList(growable: false),
        },
      if (taxonomyValuesByGroup.isNotEmpty)
        'taxonomy': {
          for (final entry in taxonomyValuesByGroup.entries)
            entry.key:
                entry.value.map((token) => token.value).toList(growable: false),
        },
    });
  }

  static TenantAdminDiscoveryFilterQuery fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return TenantAdminDiscoveryFilterQuery();
    }
    final entities = _stringList(json['entities'] ?? json['entity'])
        .map(_tokenValue)
        .toList(growable: false);

    final typesByEntity = <String, List<TenantAdminLowercaseTokenValue>>{};
    final rawTypesByEntity = json['types_by_entity'];
    if (rawTypesByEntity is Map) {
      rawTypesByEntity.forEach((rawEntity, rawTypes) {
        final entity = _normalizeToken(rawEntity);
        if (entity.isEmpty) {
          return;
        }
        final types = _stringList(rawTypes).map(_tokenValue).toList();
        if (types.isNotEmpty) {
          typesByEntity[entity] = types;
        }
      });
    } else if (entities.length == 1) {
      final legacyTypes = _stringList(json['types']).map(_tokenValue).toList();
      if (legacyTypes.isNotEmpty) {
        typesByEntity[entities.first.value] = legacyTypes;
      }
    }

    final taxonomyByGroup = <String, List<TenantAdminLowercaseTokenValue>>{};
    final rawTaxonomy = json['taxonomy'];
    if (rawTaxonomy is Map) {
      rawTaxonomy.forEach((rawGroup, rawValues) {
        final group = _normalizeToken(rawGroup);
        if (group.isEmpty) {
          return;
        }
        final values = _stringList(rawValues).map(_tokenValue).toList();
        if (values.isNotEmpty) {
          taxonomyByGroup[group] = values;
        }
      });
    } else {
      for (final token in _stringList(rawTaxonomy)) {
        final separator = token.indexOf(':');
        final group = separator <= 0 ? 'legacy' : token.substring(0, separator);
        final value = separator <= 0 ? token : token.substring(separator + 1);
        final groupKey = _normalizeToken(group);
        final termValue = _normalizeToken(value);
        if (groupKey.isEmpty || termValue.isEmpty) {
          continue;
        }
        taxonomyByGroup
            .putIfAbsent(groupKey, () => <TenantAdminLowercaseTokenValue>[])
            .add(_tokenValue(termValue));
      }
    }

    return TenantAdminDiscoveryFilterQuery(
      entityValues: entities,
      typeValuesByEntity: typesByEntity,
      taxonomyValuesByGroup: taxonomyByGroup,
    );
  }

  static List<TenantAdminLowercaseTokenValue> _normalizeTokens(
    Iterable<TenantAdminLowercaseTokenValue>? rawValues,
  ) {
    if (rawValues == null) {
      return const <TenantAdminLowercaseTokenValue>[];
    }
    final normalized = <TenantAdminLowercaseTokenValue>[];
    final seen = <String>{};
    for (final raw in rawValues) {
      final value = raw.value.trim().toLowerCase();
      if (value.isEmpty || !seen.add(value)) {
        continue;
      }
      normalized.add(_tokenValue(value));
    }
    return normalized;
  }

  static Map<String, List<TenantAdminLowercaseTokenValue>> _normalizeTokenMap(
    Map<String, Iterable<TenantAdminLowercaseTokenValue>>? rawValue,
  ) {
    if (rawValue == null) {
      return const <String, List<TenantAdminLowercaseTokenValue>>{};
    }
    final normalized = <String, List<TenantAdminLowercaseTokenValue>>{};
    for (final entry in rawValue.entries) {
      final key = _normalizeToken(entry.key);
      if (key.isEmpty) {
        continue;
      }
      final values = _normalizeTokens(entry.value);
      if (values.isNotEmpty) {
        normalized[key] = values;
      }
    }
    return normalized;
  }

  static List<String> _stringList(Object? raw) {
    final source = raw is Iterable ? raw : [raw];
    final normalized = <String>[];
    final seen = <String>{};
    for (final item in source) {
      final value = _normalizeToken(item);
      if (value.isNotEmpty && seen.add(value)) {
        normalized.add(value);
      }
    }
    return normalized;
  }

  static String _normalizeToken(Object? raw) =>
      (raw?.toString() ?? '').trim().toLowerCase();

  static TenantAdminLowercaseTokenValue _tokenValue(String raw) =>
      TenantAdminLowercaseTokenValue.fromRaw(raw);
}
