import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_account_profile_id_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';

class TenantAdminAccountProfileSelectionSummary {
  TenantAdminAccountProfileSelectionSummary({
    required this.idValue,
    TenantAdminOptionalTextValue? displayNameValue,
    TenantAdminFlagValue? isQueryableCandidateValue,
    TenantAdminFlagValue? isContactCapableCandidateValue,
  }) : displayNameValue = displayNameValue ?? TenantAdminOptionalTextValue(),
       isQueryableCandidateValue =
           isQueryableCandidateValue ?? TenantAdminFlagValue(false),
       isContactCapableCandidateValue =
           isContactCapableCandidateValue ?? TenantAdminFlagValue(false);

  final TenantAdminAccountProfileIdValue idValue;
  final TenantAdminOptionalTextValue displayNameValue;
  final TenantAdminFlagValue isQueryableCandidateValue;
  final TenantAdminFlagValue isContactCapableCandidateValue;

  String get id => idValue.value;
  String? get displayName => displayNameValue.nullableValue;
  bool get isQueryableCandidate => isQueryableCandidateValue.value;
  bool get isContactCapableCandidate => isContactCapableCandidateValue.value;
}
