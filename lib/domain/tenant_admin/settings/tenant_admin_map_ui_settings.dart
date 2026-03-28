import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_default_origin.dart';
import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_catalog_item.dart';
import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_marker_override.dart';
import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_query.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_dynamic_map_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';

typedef TenantAdminMapUiSettingsPrimString = String;
typedef TenantAdminMapUiSettingsPrimInt = int;
typedef TenantAdminMapUiSettingsPrimBool = bool;
typedef TenantAdminMapUiSettingsPrimDouble = double;
typedef TenantAdminMapUiSettingsPrimDateTime = DateTime;
typedef TenantAdminMapUiSettingsPrimDynamic = dynamic;

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
            keyValue: item.keyValue,
            labelValue: item.labelValue,
            imageUriValue: item.imageUriValue,
            overrideMarkerValue: TenantAdminFlagValue(item.overrideMarker),
            markerOverride: _sanitizeMarkerOverride(
              item.markerOverride,
              fallbackImageUri: item.imageUri,
            ),
            query: TenantAdminMapFilterQuery(
              source: item.query.source,
              typeValues: item.query.typeValues,
              taxonomyValues: item.query.taxonomyValues,
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

  TenantAdminMapFilterMarkerOverride? _sanitizeMarkerOverride(
    TenantAdminMapFilterMarkerOverride? markerOverride, {
    required Object? fallbackImageUri,
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

    final fallbackImageUriValue = TenantAdminOptionalUrlValue();
    fallbackImageUriValue.parse(fallbackImageUri?.toString());
    final resolvedImageUri =
        markerOverride.imageUriValue?.nullableValue?.trim().isNotEmpty == true
            ? markerOverride.imageUriValue!.nullableValue!.trim()
            : (fallbackImageUriValue.nullableValue?.trim() ?? '');
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
