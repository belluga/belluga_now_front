import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

export 'value_objects/tenant_admin_account_publication_values.dart';

class TenantAdminAccountPublication {
  TenantAdminAccountPublication({required this.statusValue});

  final TenantAdminRequiredTextValue statusValue;

  TenantAdminRequiredTextValue get status => statusValue;
}
