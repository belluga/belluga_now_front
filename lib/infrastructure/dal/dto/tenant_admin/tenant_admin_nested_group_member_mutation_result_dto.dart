import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_group_member_mutation_result.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_account_profile_aggregate_revision_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_count_value.dart';

class TenantAdminNestedGroupMemberMutationResultDTO {
  const TenantAdminNestedGroupMemberMutationResultDTO({
    required this.memberCount,
    required this.aggregateRevision,
  });

  final int memberCount;
  final int aggregateRevision;

  factory TenantAdminNestedGroupMemberMutationResultDTO.fromJson(
    Map<String, dynamic> json,
  ) {
    return TenantAdminNestedGroupMemberMutationResultDTO(
      memberCount: _toInt(json['member_count']),
      aggregateRevision: _toInt(json['aggregate_revision']),
    );
  }

  TenantAdminNestedGroupMemberMutationResult toDomain() {
    return TenantAdminNestedGroupMemberMutationResult(
      memberCountValue: TenantAdminCountValue(memberCount),
      aggregateRevisionValue: TenantAdminAccountProfileAggregateRevisionValue(
        aggregateRevision,
      ),
    );
  }

  static int _toInt(Object? raw) {
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }
}
