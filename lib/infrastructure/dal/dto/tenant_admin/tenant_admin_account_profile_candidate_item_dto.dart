import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_candidate.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_account_profile_id_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

class TenantAdminAccountProfileCandidateDTO {
  const TenantAdminAccountProfileCandidateDTO({
    required this.id,
    required this.displayName,
  });

  final String id;
  final String displayName;

  factory TenantAdminAccountProfileCandidateDTO.fromJson(
    Map<String, dynamic> json,
  ) {
    return TenantAdminAccountProfileCandidateDTO(
      id: json['id']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
    );
  }

  TenantAdminAccountProfileCandidate toDomain() {
    return TenantAdminAccountProfileCandidate(
      idValue: TenantAdminAccountProfileIdValue(id),
      displayNameValue: TenantAdminRequiredTextValue()..parse(displayName),
    );
  }
}
