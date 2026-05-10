import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_dynamic_map_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:value_object_pattern/domain/value_objects/email_address_value.dart';

class TenantAdminPushCredentials {
  TenantAdminPushCredentials({
    this.idValue,
    required this.projectIdValue,
    required this.clientEmailValue,
    this.privateKeyValue,
  });

  final TenantAdminRequiredTextValue? idValue;
  final TenantAdminRequiredTextValue projectIdValue;
  final EmailAddressValue clientEmailValue;
  final TenantAdminRequiredTextValue? privateKeyValue;

  String? get id => idValue?.value;
  String get projectId => projectIdValue.value;
  String get clientEmail => clientEmailValue.value;
  String? get privateKey => privateKeyValue?.value;

  TenantAdminDynamicMapValue toUpsertPayload() {
    return TenantAdminDynamicMapValue({
      'project_id': projectId,
      'client_email': clientEmail,
      'private_key': privateKey,
    });
  }
}
