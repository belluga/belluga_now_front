import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_profile_group.dart';

List<Map<String, dynamic>> encodeTenantAdminNestedProfileGroups(
  List<TenantAdminNestedProfileGroup> groups,
) {
  return groups
      .map(
        (group) => {'id': group.id, 'label': group.label, 'order': group.order},
      )
      .toList(growable: false);
}

List<Map<String, dynamic>> encodeTenantAdminNestedProfileGroupMetadata(
  List<TenantAdminNestedProfileGroup> groups,
) {
  return encodeTenantAdminNestedProfileGroups(groups);
}
