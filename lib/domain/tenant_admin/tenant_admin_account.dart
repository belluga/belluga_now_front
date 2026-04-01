import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
export 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_account_values.dart';

class TenantAdminAccount {
  TenantAdminAccount({
    required this.idValue,
    required this.nameValue,
    required this.slugValue,
    required this.document,
    required this.ownershipState,
    TenantAdminOptionalTextValue? organizationIdValue,
    TenantAdminOptionalUrlValue? avatarUrlValue,
  })  : organizationIdValue =
            organizationIdValue ?? TenantAdminOptionalTextValue(),
        avatarUrlValue = avatarUrlValue ?? TenantAdminOptionalUrlValue();

  final TenantAdminRequiredTextValue idValue;
  final TenantAdminRequiredTextValue nameValue;
  final TenantAdminRequiredTextValue slugValue;
  final TenantAdminDocument document;
  final TenantAdminOwnershipState ownershipState;
  final TenantAdminOptionalTextValue organizationIdValue;
  final TenantAdminOptionalUrlValue avatarUrlValue;

  String get id => idValue.value;
  String get name => nameValue.value;
  String get slug => slugValue.value;
  String? get organizationId => organizationIdValue.nullableValue;
  String? get avatarUrl => avatarUrlValue.nullableValue;
}
