import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_nested_profile_group_values.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';

class TenantAdminAccountProfileGalleryUpdateItem {
  TenantAdminAccountProfileGalleryUpdateItem({
    required this.itemIdValue,
    required this.descriptionValue,
    required this.orderValue,
    this.upload,
  });

  final TenantAdminNestedProfileGroupTextValue itemIdValue;
  final TenantAdminOptionalTextValue descriptionValue;
  final TenantAdminNestedProfileGroupOrderValue orderValue;
  final TenantAdminMediaUpload? upload;

  String get itemId => itemIdValue.value;
  String? get description => descriptionValue.nullableValue;
  int get order => orderValue.value;
}
