import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_default_origin.dart';
import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_catalog_item.dart';
import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_catalog_items.dart';
import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_marker_override.dart';
import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_query.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_dynamic_map_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';

class TenantAdminMapUiSettings {
  TenantAdminMapUiSettings({
    required this.rawMapUiValue,
    required this.defaultOrigin,
    required this.filters,
  });

  TenantAdminMapUiSettings.empty()
      : rawMapUiValue = TenantAdminDynamicMapValue(),
        defaultOrigin = null,
        filters = const TenantAdminMapFilterCatalogItems.empty();

  final TenantAdminDynamicMapValue rawMapUiValue;
  final TenantAdminMapDefaultOrigin? defaultOrigin;
  final TenantAdminMapFilterCatalogItems filters;

  TenantAdminDynamicMapValue get rawMapUi => rawMapUiValue;

  TenantAdminMapUiSettings applyDefaultOrigin(
    TenantAdminMapDefaultOrigin? origin,
  ) {
    final nextRaw = Map<String, dynamic>.from(rawMapUiValue.value);
    if (origin == null) {
      nextRaw['default_origin'] = const <String, dynamic>{
        'lat': null,
        'lng': null,
        'label': null,
      };
    } else {
      nextRaw['default_origin'] = origin.toJson().value;
    }
    return TenantAdminMapUiSettings(
      rawMapUiValue: TenantAdminDynamicMapValue(
          Map<String, dynamic>.unmodifiable(nextRaw)),
      defaultOrigin: origin,
      filters: _cloneFilters(filters),
    );
  }

  TenantAdminMapUiSettings applyFilters(
    TenantAdminMapFilterCatalogItems nextFilters,
  ) {
    final sanitized = TenantAdminMapFilterCatalogItems();
    for (final item in nextFilters) {
      final sanitizedItem = TenantAdminMapFilterCatalogItem(
        keyValue: item.keyValue,
        labelValue: item.labelValue,
        imageUriValue: item.imageUriValue,
        overrideMarkerValue: TenantAdminFlagValue(item.overrideMarker),
        markerOverride: _sanitizeMarkerOverride(
          item.markerOverride,
          fallbackImageUriValue: item.imageUriValue,
        ),
        query: TenantAdminMapFilterQuery(
          source: item.query.source,
          typeValues: item.query.typeValues,
          taxonomyValues: item.query.taxonomyValues,
        ),
      );
      if (sanitizedItem.key.isEmpty || sanitizedItem.label.isEmpty) {
        continue;
      }
      sanitized.add(sanitizedItem);
    }

    final nextRaw = Map<String, dynamic>.from(rawMapUiValue.value);
    nextRaw['filters'] =
        sanitized.map((item) => item.toJson().value).toList(growable: false);
    return TenantAdminMapUiSettings(
      rawMapUiValue: TenantAdminDynamicMapValue(
          Map<String, dynamic>.unmodifiable(nextRaw)),
      defaultOrigin: defaultOrigin,
      filters: sanitized,
    );
  }

  static TenantAdminMapFilterCatalogItems _cloneFilters(
    TenantAdminMapFilterCatalogItems filters,
  ) {
    final cloned = TenantAdminMapFilterCatalogItems();
    for (final item in filters) {
      cloned.add(item);
    }
    return cloned;
  }

  TenantAdminMapFilterMarkerOverride? _sanitizeMarkerOverride(
    TenantAdminMapFilterMarkerOverride? markerOverride, {
    required TenantAdminOptionalUrlValue? fallbackImageUriValue,
  }) {
    if (markerOverride == null) {
      return null;
    }

    if (markerOverride.mode == TenantAdminMapFilterMarkerOverrideMode.icon) {
      if (!markerOverride.isValid) {
        return null;
      }
      return TenantAdminMapFilterMarkerOverride.icon(
        iconValue: markerOverride.iconValue!,
        colorValue: markerOverride.colorValue!,
        iconColorValue: markerOverride.iconColorValue!,
      );
    }

    final resolvedImageUri =
        markerOverride.imageUriValue?.nullableValue?.trim().isNotEmpty == true
            ? markerOverride.imageUriValue!.nullableValue!.trim()
            : (fallbackImageUriValue?.nullableValue?.trim() ?? '');
    if (resolvedImageUri.isEmpty) {
      return null;
    }

    final imageUriValue = TenantAdminOptionalUrlValue();
    imageUriValue.parse(resolvedImageUri);
    return TenantAdminMapFilterMarkerOverride.image(
      imageUriValue: imageUriValue,
    );
  }
}
