import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_gallery_item.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_nested_profile_group_values.dart';

export 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_gallery_item.dart';

class TenantAdminAccountProfileGalleryGroup {
  TenantAdminAccountProfileGalleryGroup({
    required this.groupIdValue,
    required this.subtitleValue,
    required this.orderValue,
    List<TenantAdminAccountProfileGalleryItem>? items,
  }) : items = List<TenantAdminAccountProfileGalleryItem>.unmodifiable(
          items ?? const <TenantAdminAccountProfileGalleryItem>[],
        );

  final TenantAdminNestedProfileGroupTextValue groupIdValue;
  final TenantAdminNestedProfileGroupTextValue subtitleValue;
  final TenantAdminNestedProfileGroupOrderValue orderValue;
  final List<TenantAdminAccountProfileGalleryItem> items;

  String get groupId => groupIdValue.value;
  String get subtitle => subtitleValue.value;
  int get order => orderValue.value;
}
