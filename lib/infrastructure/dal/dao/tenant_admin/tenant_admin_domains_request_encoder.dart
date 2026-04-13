import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

class TenantAdminDomainsRequestEncoder {
  const TenantAdminDomainsRequestEncoder();

  Map<String, Object?> encodeCreate({
    required TenantAdminRequiredTextValue path,
  }) {
    return <String, Object?>{
      'path': path.value,
    };
  }
}
