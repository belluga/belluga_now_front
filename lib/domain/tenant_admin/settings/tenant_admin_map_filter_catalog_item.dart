import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_query.dart';
import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_marker_override.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

typedef TenantAdminMapFilterCatalogItemPrimString = String;
typedef TenantAdminMapFilterCatalogItemPrimInt = int;
typedef TenantAdminMapFilterCatalogItemPrimBool = bool;
typedef TenantAdminMapFilterCatalogItemPrimDouble = double;
typedef TenantAdminMapFilterCatalogItemPrimDateTime = DateTime;
typedef TenantAdminMapFilterCatalogItemPrimDynamic = dynamic;

class TenantAdminMapFilterCatalogItem {
  TenantAdminMapFilterCatalogItem({
    required TenantAdminMapFilterCatalogItemPrimString key,
    required TenantAdminMapFilterCatalogItemPrimString label,
    TenantAdminMapFilterCatalogItemPrimString? imageUri,
    this.overrideMarker = false,
    this.markerOverride,
    TenantAdminMapFilterQuery? query,
  })  : keyValue = _buildKeyValue(key),
        labelValue = _buildLabelValue(label),
        imageUriValue = _buildImageUriValue(imageUri),
        query = query ?? TenantAdminMapFilterQuery();

  final TenantAdminLowercaseTokenValue keyValue;
  final TenantAdminRequiredTextValue labelValue;
  final TenantAdminOptionalUrlValue? imageUriValue;
  final TenantAdminMapFilterCatalogItemPrimBool overrideMarker;
  final TenantAdminMapFilterMarkerOverride? markerOverride;
  final TenantAdminMapFilterQuery query;

  TenantAdminMapFilterCatalogItemPrimString get key => keyValue.value;
  TenantAdminMapFilterCatalogItemPrimString get label => labelValue.value;
  TenantAdminMapFilterCatalogItemPrimString? get imageUri =>
      imageUriValue?.nullableValue;

  TenantAdminMapFilterCatalogItem copyWith({
    TenantAdminMapFilterCatalogItemPrimString? key,
    TenantAdminMapFilterCatalogItemPrimString? label,
    TenantAdminMapFilterCatalogItemPrimString? imageUri,
    TenantAdminMapFilterCatalogItemPrimBool clearImageUri = false,
    TenantAdminMapFilterCatalogItemPrimBool? overrideMarker,
    TenantAdminMapFilterMarkerOverride? markerOverride,
    TenantAdminMapFilterCatalogItemPrimBool clearMarkerOverride = false,
    TenantAdminMapFilterQuery? query,
  }) {
    return TenantAdminMapFilterCatalogItem(
      key: key ?? this.key,
      label: label ?? this.label,
      imageUri: clearImageUri ? null : (imageUri ?? this.imageUri),
      overrideMarker: overrideMarker ?? this.overrideMarker,
      markerOverride:
          clearMarkerOverride ? null : (markerOverride ?? this.markerOverride),
      query: query ?? this.query,
    );
  }

  Map<TenantAdminMapFilterCatalogItemPrimString,
      TenantAdminMapFilterCatalogItemPrimDynamic> toJson() {
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

  static TenantAdminLowercaseTokenValue _buildKeyValue(
      TenantAdminMapFilterCatalogItemPrimString raw) {
    final value = TenantAdminLowercaseTokenValue()..parse(raw);
    return value;
  }

  static TenantAdminRequiredTextValue _buildLabelValue(
      TenantAdminMapFilterCatalogItemPrimString raw) {
    final value = TenantAdminRequiredTextValue()..parse(raw);
    return value;
  }

  static TenantAdminOptionalUrlValue? _buildImageUriValue(
      TenantAdminMapFilterCatalogItemPrimString? raw) {
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    final value = TenantAdminOptionalUrlValue()..parse(normalized);
    return value;
  }
}
