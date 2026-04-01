export 'value_objects/tenant_admin_document_values.dart';

import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';

class TenantAdminDocument {
  TenantAdminDocument({
    required this.typeValue,
    required this.numberValue,
  });

  final TenantAdminOptionalTextValue typeValue;
  final TenantAdminOptionalTextValue numberValue;

  String get type => typeValue.value;
  String get number => numberValue.value;
}
