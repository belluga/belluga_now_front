import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';

class TenantAdminDocument {
  TenantAdminDocument({
    required Object type,
    required Object number,
  })  : typeValue = tenantAdminOptionalText(type),
        numberValue = tenantAdminOptionalText(number);

  final TenantAdminOptionalTextValue typeValue;
  final TenantAdminOptionalTextValue numberValue;

  String get type => typeValue.value;
  String get number => numberValue.value;
}
