import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_nested_profile_group_values.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';

class TenantAdminAccountProfileGalleryItem {
  TenantAdminAccountProfileGalleryItem({
    required this.itemIdValue,
    required this.descriptionValue,
    required this.orderValue,
    required this.imageUrlValue,
    required this.thumbUrlValue,
    required this.cardUrlValue,
    required this.modalUrlValue,
  });

  final TenantAdminNestedProfileGroupTextValue itemIdValue;
  final TenantAdminOptionalTextValue descriptionValue;
  final TenantAdminNestedProfileGroupOrderValue orderValue;
  final TenantAdminOptionalUrlValue imageUrlValue;
  final TenantAdminOptionalUrlValue thumbUrlValue;
  final TenantAdminOptionalUrlValue cardUrlValue;
  final TenantAdminOptionalUrlValue modalUrlValue;

  String get itemId => itemIdValue.value;
  String? get description => descriptionValue.nullableValue;
  int get order => orderValue.value;
  String get imageUrl => imageUrlValue.nullableValue ?? '';
  String get thumbUrl => thumbUrlValue.nullableValue ?? '';
  String get cardUrl => cardUrlValue.nullableValue ?? '';
  String get modalUrl => modalUrlValue.nullableValue ?? '';

  String get previewUrl {
    if (thumbUrl.trim().isNotEmpty) {
      return thumbUrl;
    }
    if (cardUrl.trim().isNotEmpty) {
      return cardUrl;
    }
    if (imageUrl.trim().isNotEmpty) {
      return imageUrl;
    }
    return modalUrl;
  }
}
