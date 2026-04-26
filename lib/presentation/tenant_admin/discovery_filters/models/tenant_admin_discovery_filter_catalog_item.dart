import 'package:belluga_now/presentation/tenant_admin/discovery_filters/models/tenant_admin_discovery_filter_query.dart';
import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_marker_override.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_dynamic_map_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

class TenantAdminDiscoveryFilterCatalogItem {
  TenantAdminDiscoveryFilterCatalogItem({
    required this.keyValue,
    required this.labelValue,
    this.imageUriValue,
    TenantAdminFlagValue? overrideMarkerValue,
    this.markerOverride,
    TenantAdminDiscoveryFilterQuery? query,
  })  : overrideMarkerValue =
            overrideMarkerValue ?? TenantAdminFlagValue(false),
        query = query ?? TenantAdminDiscoveryFilterQuery();

  final TenantAdminLowercaseTokenValue keyValue;
  final TenantAdminRequiredTextValue labelValue;
  final TenantAdminOptionalUrlValue? imageUriValue;
  final TenantAdminFlagValue overrideMarkerValue;
  final TenantAdminMapFilterMarkerOverride? markerOverride;
  final TenantAdminDiscoveryFilterQuery query;

  String get key => keyValue.value;
  String get label => labelValue.value;
  String? get imageUri => imageUriValue?.nullableValue;
  bool get overrideMarker => overrideMarkerValue.value;

  TenantAdminDiscoveryFilterCatalogItem copyWith({
    TenantAdminLowercaseTokenValue? keyValue,
    TenantAdminRequiredTextValue? labelValue,
    TenantAdminOptionalUrlValue? imageUriValue,
    TenantAdminFlagValue? clearImageUriValue,
    TenantAdminFlagValue? overrideMarkerValue,
    TenantAdminMapFilterMarkerOverride? markerOverride,
    TenantAdminFlagValue? clearMarkerOverrideValue,
    TenantAdminDiscoveryFilterQuery? query,
  }) {
    final clearImageUri = clearImageUriValue?.value ?? false;
    final clearMarkerOverride = clearMarkerOverrideValue?.value ?? false;
    return TenantAdminDiscoveryFilterCatalogItem(
      keyValue: keyValue ?? this.keyValue,
      labelValue: labelValue ?? this.labelValue,
      imageUriValue:
          clearImageUri ? null : (imageUriValue ?? this.imageUriValue),
      overrideMarkerValue: overrideMarkerValue ?? this.overrideMarkerValue,
      markerOverride:
          clearMarkerOverride ? null : (markerOverride ?? this.markerOverride),
      query: query ?? this.query,
    );
  }

  TenantAdminDynamicMapValue toJson({
    required String surface,
    required String target,
    required String primarySelectionMode,
  }) {
    return TenantAdminDynamicMapValue({
      'key': key,
      'surface': surface,
      'target': target,
      'label': label,
      'primary_selection_mode': primarySelectionMode,
      if (imageUri != null) 'image_uri': imageUri,
      'override_marker': overrideMarker,
      if (overrideMarker && markerOverride?.isValid == true)
        'marker_override': markerOverride!.toJson().value,
      'query': query.toJson().value,
    });
  }
}
