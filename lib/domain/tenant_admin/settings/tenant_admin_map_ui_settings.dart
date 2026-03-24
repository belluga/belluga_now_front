import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_default_origin.dart';
import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_catalog_item.dart';
import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_query.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_dynamic_map_value.dart';

class TenantAdminMapUiSettings {
  TenantAdminMapUiSettings({
    required this.rawMapUiValue,
    required this.defaultOrigin,
    required this.filters,
  });

  TenantAdminMapUiSettings.empty()
      : rawMapUiValue = TenantAdminDynamicMapValue(),
        defaultOrigin = null,
        filters = const <TenantAdminMapFilterCatalogItem>[];

  final TenantAdminDynamicMapValue rawMapUiValue;
  final TenantAdminMapDefaultOrigin? defaultOrigin;
  final List<TenantAdminMapFilterCatalogItem> filters;

  Map<String, dynamic> get rawMapUi => rawMapUiValue.value;

  TenantAdminMapUiSettings applyDefaultOrigin(
    TenantAdminMapDefaultOrigin? origin,
  ) {
    final nextRaw = Map<String, dynamic>.from(rawMapUi);
    if (origin == null) {
      nextRaw['default_origin'] = const <String, dynamic>{
        'lat': null,
        'lng': null,
        'label': null,
      };
    } else {
      nextRaw['default_origin'] = origin.toJson();
    }
    return TenantAdminMapUiSettings(
      rawMapUiValue: TenantAdminDynamicMapValue(
          Map<String, dynamic>.unmodifiable(nextRaw)),
      defaultOrigin: origin,
      filters: List<TenantAdminMapFilterCatalogItem>.unmodifiable(filters),
    );
  }

  TenantAdminMapUiSettings applyFilters(
    List<TenantAdminMapFilterCatalogItem> nextFilters,
  ) {
    final sanitized = nextFilters
        .map(
          (item) => TenantAdminMapFilterCatalogItem(
            key: item.key,
            label: item.label,
            imageUri: item.imageUri,
            query: TenantAdminMapFilterQuery(
              source: item.query.source,
              types: item.query.types,
              taxonomy: item.query.taxonomy,
            ),
          ),
        )
        .where((item) => item.key.isNotEmpty && item.label.isNotEmpty)
        .toList(growable: false);

    final nextRaw = Map<String, dynamic>.from(rawMapUi);
    nextRaw['filters'] = sanitized.map((item) => item.toJson()).toList();
    return TenantAdminMapUiSettings(
      rawMapUiValue: TenantAdminDynamicMapValue(
          Map<String, dynamic>.unmodifiable(nextRaw)),
      defaultOrigin: defaultOrigin,
      filters: List<TenantAdminMapFilterCatalogItem>.unmodifiable(sanitized),
    );
  }
}
