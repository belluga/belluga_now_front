import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_query.dart';
import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_marker_override.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

class TenantAdminMapFilterCatalogItem {
  TenantAdminMapFilterCatalogItem({
    required this.keyValue,
    required this.labelValue,
    this.imageUriValue,
    TenantAdminFlagValue? overrideMarkerValue,
    this.markerOverride,
    TenantAdminMapFilterQuery? query,
  })  : overrideMarkerValue =
            overrideMarkerValue ?? const TenantAdminFlagValue(false),
        query = query ?? TenantAdminMapFilterQuery();

  final TenantAdminLowercaseTokenValue keyValue;
  final TenantAdminRequiredTextValue labelValue;
  final TenantAdminOptionalUrlValue? imageUriValue;
  final TenantAdminFlagValue overrideMarkerValue;
  final TenantAdminMapFilterMarkerOverride? markerOverride;
  final TenantAdminMapFilterQuery query;

  String get key => keyValue.value;
  String get label => labelValue.value;
  String? get imageUri => imageUriValue?.nullableValue;
  bool get overrideMarker => overrideMarkerValue.value;

  TenantAdminMapFilterCatalogItem copyWith({
    TenantAdminLowercaseTokenValue? keyValue,
    TenantAdminRequiredTextValue? labelValue,
    TenantAdminOptionalUrlValue? imageUriValue,
    TenantAdminFlagValue? clearImageUriValue,
    TenantAdminFlagValue? overrideMarkerValue,
    TenantAdminMapFilterMarkerOverride? markerOverride,
    TenantAdminFlagValue? clearMarkerOverrideValue,
    TenantAdminMapFilterQuery? query,
  }) {
    final clearImageUri = clearImageUriValue?.value ?? false;
    final clearMarkerOverride = clearMarkerOverrideValue?.value ?? false;
    return TenantAdminMapFilterCatalogItem(
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

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'label': label,
      if (imageUri != null) 'image_uri': imageUri,
      'override_marker': overrideMarker,
      if (overrideMarker && markerOverride?.isValid == true)
        'marker_override': markerOverride!.toJson(),
      if (!query.isEmpty) 'query': query.toJson(),
    };
  }
}
