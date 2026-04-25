import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_source.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';

class TenantAdminLegacyMapFilterCanonicalizer {
  const TenantAdminLegacyMapFilterCanonicalizer();

  Map<String, dynamic>? canonicalize(Object? raw) {
    final payload = _mapOf(raw);
    final key = _normalizeToken(payload['key']);
    final label = payload['label']?.toString().trim() ?? '';
    if (key.isEmpty || label.isEmpty) {
      return null;
    }

    final query = _mapOf(payload['query']);
    final source = _normalizeToken(query['source']);
    final entity = _legacySourceToEntity(source);
    final types = _stringList(query['types']);
    final taxonomy = _legacyTaxonomy(query['taxonomy']);

    return {
      'key': key,
      'surface': 'public_map.primary',
      'target': 'map_poi',
      'label': label,
      'primary_selection_mode': 'single',
      if (payload['image_uri'] != null) 'image_uri': payload['image_uri'],
      'override_marker': _parseBool(payload['override_marker']),
      if (payload['marker_override'] is Map)
        'marker_override': payload['marker_override'],
      'query': {
        if (entity != null) 'entities': [entity],
        if (entity != null && types.isNotEmpty)
          'types_by_entity': {entity: types},
        if (taxonomy.isNotEmpty) 'taxonomy': taxonomy,
      },
    };
  }

  String? _legacySourceToEntity(String source) {
    final sourceValue = TenantAdminMapFilterSource.fromRaw(
      TenantAdminLowercaseTokenValue.fromRaw(
        source,
        isRequired: false,
      ),
    );
    return sourceValue?.apiValue;
  }

  Map<String, List<String>> _legacyTaxonomy(Object? raw) {
    final mapped = <String, List<String>>{};
    for (final token in _stringList(raw)) {
      final separator = token.indexOf(':');
      final group = separator <= 0 ? 'legacy' : token.substring(0, separator);
      final value = separator <= 0 ? token : token.substring(separator + 1);
      final groupKey = _normalizeToken(group);
      final termValue = _normalizeToken(value);
      if (groupKey.isEmpty || termValue.isEmpty) {
        continue;
      }
      mapped.putIfAbsent(groupKey, () => <String>[]).add(termValue);
    }
    return mapped;
  }

  Map<String, dynamic> _mapOf(Object? raw) {
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return const <String, dynamic>{};
  }

  List<String> _stringList(Object? raw) {
    final source = raw is Iterable ? raw : [raw];
    final values = <String>[];
    final seen = <String>{};
    for (final item in source) {
      final value = _normalizeToken(item);
      if (value.isNotEmpty && seen.add(value)) {
        values.add(value);
      }
    }
    return values;
  }

  bool _parseBool(Object? raw) {
    if (raw is bool) {
      return raw;
    }
    final normalized = raw?.toString().trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }

  String _normalizeToken(Object? raw) =>
      (raw?.toString() ?? '').trim().toLowerCase();
}
