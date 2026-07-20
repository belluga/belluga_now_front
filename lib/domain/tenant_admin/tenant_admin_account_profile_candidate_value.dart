import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_account_profile_id_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

class TenantAdminAccountProfileCandidate {
  TenantAdminAccountProfileCandidate({
    required this.idValue,
    required this.displayNameValue,
  });

  final TenantAdminAccountProfileIdValue idValue;
  final TenantAdminRequiredTextValue displayNameValue;

  String get id => idValue.value;
  String get displayName => displayNameValue.value;
}
