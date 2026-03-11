import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_query.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

class TenantAdminMapFilterCatalogItem {
  TenantAdminMapFilterCatalogItem({
    required String key,
    required String label,
    String? imageUri,
    TenantAdminMapFilterQuery? query,
  })  : keyValue = _buildKeyValue(key),
        labelValue = _buildLabelValue(label),
        imageUriValue = _buildImageUriValue(imageUri),
        query = query ?? TenantAdminMapFilterQuery();

  final TenantAdminLowercaseTokenValue keyValue;
  final TenantAdminRequiredTextValue labelValue;
  final TenantAdminOptionalUrlValue? imageUriValue;
  final TenantAdminMapFilterQuery query;

  String get key => keyValue.value;
  String get label => labelValue.value;
  String? get imageUri => imageUriValue?.nullableValue;

  TenantAdminMapFilterCatalogItem copyWith({
    String? key,
    String? label,
    String? imageUri,
    bool clearImageUri = false,
    TenantAdminMapFilterQuery? query,
  }) {
    return TenantAdminMapFilterCatalogItem(
      key: key ?? this.key,
      label: label ?? this.label,
      imageUri: clearImageUri ? null : (imageUri ?? this.imageUri),
      query: query ?? this.query,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'label': label,
      if (imageUri != null) 'image_uri': imageUri,
      if (!query.isEmpty) 'query': query.toJson(),
    };
  }

  static TenantAdminLowercaseTokenValue _buildKeyValue(String raw) {
    final value = TenantAdminLowercaseTokenValue()..parse(raw);
    return value;
  }

  static TenantAdminRequiredTextValue _buildLabelValue(String raw) {
    final value = TenantAdminRequiredTextValue()..parse(raw);
    return value;
  }

  static TenantAdminOptionalUrlValue? _buildImageUriValue(String? raw) {
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    final value = TenantAdminOptionalUrlValue()..parse(normalized);
    return value;
  }
}
