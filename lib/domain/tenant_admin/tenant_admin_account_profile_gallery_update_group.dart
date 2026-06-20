import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_gallery_update_item.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_nested_profile_group_values.dart';

class TenantAdminAccountProfileGalleryUpdateGroup {
  TenantAdminAccountProfileGalleryUpdateGroup({
    required this.groupIdValue,
    required this.subtitleValue,
    required this.orderValue,
    List<TenantAdminAccountProfileGalleryUpdateItem>? items,
  }) : items = List<TenantAdminAccountProfileGalleryUpdateItem>.unmodifiable(
          items ?? const <TenantAdminAccountProfileGalleryUpdateItem>[],
        );

  final TenantAdminNestedProfileGroupTextValue groupIdValue;
  final TenantAdminNestedProfileGroupTextValue subtitleValue;
  final TenantAdminNestedProfileGroupOrderValue orderValue;
  final List<TenantAdminAccountProfileGalleryUpdateItem> items;

  String get groupId => groupIdValue.value;
  String get subtitle => subtitleValue.value;
  int get order => orderValue.value;
}
