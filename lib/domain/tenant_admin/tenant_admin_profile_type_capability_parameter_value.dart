import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_count_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

final class TenantAdminProfileTypeCapabilityParameterValue {
  const TenantAdminProfileTypeCapabilityParameterValue({
    required this.keyValue,
    required this.valueObject,
  });

  final TenantAdminRequiredTextValue keyValue;
  final TenantAdminCountValue valueObject;

  String get key => keyValue.value;
  int get value => valueObject.value;
}
