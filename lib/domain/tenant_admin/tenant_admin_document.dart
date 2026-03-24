import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';

class TenantAdminDocument {
  TenantAdminDocument({
    required Object type,
    required Object number,
  })  : typeValue = tenantAdminRequiredText(type),
        numberValue = tenantAdminRequiredText(number);

  final TenantAdminRequiredTextValue typeValue;
  final TenantAdminRequiredTextValue numberValue;

  String get type => typeValue.value;
  String get number => numberValue.value;
}
