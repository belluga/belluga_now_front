import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_group_member_mutation_result.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_count_value.dart';

class TenantAdminNestedGroupMemberMutationResultDTO {
  const TenantAdminNestedGroupMemberMutationResultDTO({
    required this.memberCount,
  });

  final int memberCount;

  factory TenantAdminNestedGroupMemberMutationResultDTO.fromJson(
    Map<String, dynamic> json,
  ) {
    return TenantAdminNestedGroupMemberMutationResultDTO(
      memberCount: _toInt(json['member_count']),
    );
  }

  TenantAdminNestedGroupMemberMutationResult toDomain() {
    return TenantAdminNestedGroupMemberMutationResult(
      memberCountValue: TenantAdminCountValue(memberCount),
    );
  }

  static int _toInt(Object? raw) {
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }
}
