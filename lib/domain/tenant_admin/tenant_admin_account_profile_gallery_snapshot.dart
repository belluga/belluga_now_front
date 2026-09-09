import 'tenant_admin_account_profile_gallery_capabilities.dart';
import 'tenant_admin_account_profile_gallery_group.dart';

final class TenantAdminAccountProfileGallerySnapshot {
  TenantAdminAccountProfileGallerySnapshot({
    required List<TenantAdminAccountProfileGalleryGroup> groups,
    required this.capabilities,
  }) : groups = List<TenantAdminAccountProfileGalleryGroup>.unmodifiable(
         groups,
       );

  final List<TenantAdminAccountProfileGalleryGroup> groups;
  final TenantAdminAccountProfileGalleryCapabilities capabilities;
}
