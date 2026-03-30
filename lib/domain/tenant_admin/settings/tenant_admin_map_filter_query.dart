import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_source.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_dynamic_map_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';

class TenantAdminMapFilterQuery {
  TenantAdminMapFilterQuery({
    this.source,
    List<TenantAdminLowercaseTokenValue>? typeValues,
    List<TenantAdminLowercaseTokenValue>? taxonomyValues,
  })  : typeValues = List<TenantAdminLowercaseTokenValue>.unmodifiable(
          _normalizeTokens(typeValues),
        ),
        taxonomyValues = List<TenantAdminLowercaseTokenValue>.unmodifiable(
          _normalizeTokens(taxonomyValues),
        );

  final TenantAdminMapFilterSource? source;
  final List<TenantAdminLowercaseTokenValue> typeValues;
  final List<TenantAdminLowercaseTokenValue> taxonomyValues;

  List<TenantAdminLowercaseTokenValue> get types =>
      List<TenantAdminLowercaseTokenValue>.unmodifiable(typeValues);
  List<TenantAdminLowercaseTokenValue> get taxonomy =>
      List<TenantAdminLowercaseTokenValue>.unmodifiable(taxonomyValues);

  bool get isEmpty =>
      source == null && typeValues.isEmpty && taxonomyValues.isEmpty;

  TenantAdminMapFilterQuery copyWith({
    TenantAdminMapFilterSource? source,
    List<TenantAdminLowercaseTokenValue>? typeValues,
    List<TenantAdminLowercaseTokenValue>? taxonomyValues,
    TenantAdminFlagValue? clearSourceValue,
  }) {
    final clearSource = clearSourceValue?.value ?? false;
    return TenantAdminMapFilterQuery(
      source: clearSource ? null : (source ?? this.source),
      typeValues: typeValues ?? this.typeValues,
      taxonomyValues: taxonomyValues ?? this.taxonomyValues,
    );
  }

  TenantAdminDynamicMapValue toJson() {
    return TenantAdminDynamicMapValue({
      if (source != null) 'source': source!.apiValue,
      if (types.isNotEmpty)
        'types': types.map((entry) => entry.value).toList(growable: false),
      if (taxonomy.isNotEmpty)
        'taxonomy':
            taxonomy.map((entry) => entry.value).toList(growable: false),
    });
  }

  static List<TenantAdminLowercaseTokenValue> _normalizeTokens(
    List<TenantAdminLowercaseTokenValue>? rawValues,
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
      normalized.add(TenantAdminLowercaseTokenValue.fromRaw(value));
    }
    return normalized;
  }
}
