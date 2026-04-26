import 'package:belluga_now/application/tenant_admin/settings/tenant_admin_discovery_filters_settings_canonicalizer.dart';
import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_marker_override.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_dynamic_map_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_hex_color_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/models/tenant_admin_discovery_filter_catalog_item.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/models/tenant_admin_discovery_filter_catalog_items.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/models/tenant_admin_discovery_filter_query.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/models/tenant_admin_discovery_filter_surface_definition.dart';

class TenantAdminDiscoveryFiltersSettings {
  TenantAdminDiscoveryFiltersSettings({
    required this.rawDiscoveryFiltersValue,
  });

  TenantAdminDiscoveryFiltersSettings.empty()
      : rawDiscoveryFiltersValue = TenantAdminDynamicMapValue();

  final TenantAdminDynamicMapValue rawDiscoveryFiltersValue;

  TenantAdminDynamicMapValue get rawDiscoveryFilters =>
      rawDiscoveryFiltersValue;

  TenantAdminDiscoveryFilterCatalogItems filtersForSurface(
    String surfaceKey,
  ) {
    final surfaces = _mapOf(rawDiscoveryFiltersValue.value['surfaces']);
    final surface = _mapOf(surfaces[surfaceKey]);
    final rawFilters = surface['filters'];
    if (rawFilters is! Iterable) {
      return const TenantAdminDiscoveryFilterCatalogItems.empty();
    }

    final items = TenantAdminDiscoveryFilterCatalogItems();
    for (final raw in rawFilters) {
      final item = _itemFromRaw(_mapOf(raw));
      if (item != null) {
        items.add(item);
      }
    }
    return items;
  }

  TenantAdminDiscoveryFiltersSettings applyFilters({
    required TenantAdminDiscoveryFilterSurfaceDefinition surface,
    required TenantAdminDiscoveryFilterCatalogItems filters,
  }) {
    final nextRaw = Map<String, dynamic>.from(rawDiscoveryFiltersValue.value);
    final surfaces = _mutableMap(nextRaw['surfaces']);
    final currentSurface = _mutableMap(surfaces[surface.key]);
    currentSurface['target'] = surface.target;
    currentSurface['primary_selection_mode'] = surface.primarySelectionMode;
    currentSurface['filters'] = filters
        .map(
          (item) => item
              .toJson(
                surface: surface.key,
                target: surface.target,
                primarySelectionMode: surface.primarySelectionMode,
              )
              .value,
        )
        .toList(growable: false);
    surfaces[surface.key] = currentSurface;
    nextRaw['surfaces'] = surfaces;
    return TenantAdminDiscoveryFiltersSettings(
      rawDiscoveryFiltersValue: TenantAdminDynamicMapValue(
        Map<String, dynamic>.unmodifiable(nextRaw),
      ),
    );
  }

  static TenantAdminDiscoveryFiltersSettings fromRaw({
    required Map<String, dynamic> discoveryFilters,
    Map<String, dynamic>? legacyMapUi,
  }) {
    final next =
        const TenantAdminDiscoveryFiltersSettingsCanonicalizer().canonicalize(
      discoveryFilters: discoveryFilters,
      legacyMapUi: legacyMapUi,
    );
    return TenantAdminDiscoveryFiltersSettings(
      rawDiscoveryFiltersValue: TenantAdminDynamicMapValue(
        Map<String, dynamic>.unmodifiable(next),
      ),
    );
  }

  static TenantAdminDiscoveryFilterCatalogItem? _itemFromRaw(
    Map<String, dynamic> raw,
  ) {
    final key = _normalizeToken(raw['key']);
    final label = raw['label']?.toString().trim() ?? '';
    if (key.isEmpty || label.isEmpty) {
      return null;
    }

    return TenantAdminDiscoveryFilterCatalogItem(
      keyValue: _tokenValue(key),
      labelValue: _requiredTextValue(label),
      imageUriValue: _optionalUrlValue(raw['image_uri']),
      overrideMarkerValue: TenantAdminFlagValue(_parseBool(
        raw['override_marker'],
      )),
      markerOverride: _markerOverrideFromRaw(
        raw['marker_override'],
        fallbackImageUri: raw['image_uri']?.toString(),
      ),
      query: TenantAdminDiscoveryFilterQuery.fromJson(
        raw['query'] is Map
            ? Map<String, dynamic>.from(raw['query'] as Map)
            : null,
      ),
    );
  }

  static TenantAdminMapFilterMarkerOverride? _markerOverrideFromRaw(
    Object? raw, {
    required String? fallbackImageUri,
  }) {
    if (raw is! Map) {
      return null;
    }
    final marker = Map<String, dynamic>.from(raw);
    final mode = _normalizeToken(marker['mode']);
    if (mode == TenantAdminMapFilterMarkerOverrideMode.icon.apiValue) {
      final icon = marker['icon']?.toString().trim() ?? '';
      final color = marker['color']?.toString().trim() ?? '';
      final iconColor =
          marker['icon_color']?.toString().trim().isNotEmpty == true
              ? marker['icon_color'].toString().trim()
              : '#FFFFFF';
      if (icon.isEmpty || color.isEmpty) {
        return null;
      }
      return TenantAdminMapFilterMarkerOverride.icon(
        iconValue: _requiredTextValue(icon),
        colorValue: _hexColorValue(color),
        iconColorValue: _hexColorValue(iconColor),
      );
    }
    if (mode == TenantAdminMapFilterMarkerOverrideMode.image.apiValue) {
      final imageUri = marker['image_uri']?.toString().trim().isNotEmpty == true
          ? marker['image_uri'].toString().trim()
          : (fallbackImageUri?.trim() ?? '');
      final imageUriValue = _optionalUrlValue(imageUri);
      if (imageUriValue == null) {
        return null;
      }
      return TenantAdminMapFilterMarkerOverride.image(
        imageUriValue: imageUriValue,
      );
    }
    return null;
  }

  static Map<String, dynamic> _mutableMap(Object? raw) {
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return <String, dynamic>{};
  }

  static Map<String, dynamic> _mapOf(Object? raw) {
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return const <String, dynamic>{};
  }

  static bool _parseBool(Object? raw) {
    if (raw is bool) {
      return raw;
    }
    final normalized = raw?.toString().trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }

  static String _normalizeToken(Object? raw) =>
      (raw?.toString() ?? '').trim().toLowerCase();

  static TenantAdminLowercaseTokenValue _tokenValue(String raw) =>
      TenantAdminLowercaseTokenValue.fromRaw(raw);

  static TenantAdminRequiredTextValue _requiredTextValue(String raw) =>
      TenantAdminRequiredTextValue()..parse(raw);

  static TenantAdminOptionalUrlValue? _optionalUrlValue(Object? raw) {
    final value = raw?.toString().trim() ?? '';
    if (value.isEmpty) {
      return null;
    }
    final parsed = TenantAdminOptionalUrlValue();
    parsed.parse(value);
    return parsed;
  }

  static TenantAdminHexColorValue _hexColorValue(String raw) =>
      TenantAdminHexColorValue()..parse(raw);
}
