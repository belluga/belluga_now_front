import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_account_profile_aggregate_revision_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_count_value.dart';

class TenantAdminNestedGroupMemberMutationResult {
  const TenantAdminNestedGroupMemberMutationResult({
    required this.memberCountValue,
    required this.aggregateRevisionValue,
  });

  final TenantAdminCountValue memberCountValue;
  final TenantAdminAccountProfileAggregateRevisionValue aggregateRevisionValue;

  int get memberCount => memberCountValue.value;
  int get aggregateRevision => aggregateRevisionValue.value;
}
