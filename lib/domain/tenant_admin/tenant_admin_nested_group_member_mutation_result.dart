import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_count_value.dart';

class TenantAdminNestedGroupMemberMutationResult {
  const TenantAdminNestedGroupMemberMutationResult({
    required this.memberCountValue,
  });

  final TenantAdminCountValue memberCountValue;

  int get memberCount => memberCountValue.value;
}
