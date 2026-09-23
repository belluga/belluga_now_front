import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_count_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

final class TenantAdminProfileTypeCapabilityValidation {
  const TenantAdminProfileTypeCapabilityValidation({
    required this.ruleValue,
    required this.limitValue,
  });

  final TenantAdminRequiredTextValue ruleValue;
  final TenantAdminCountValue limitValue;

  String get rule => ruleValue.value;
  int get value => limitValue.value;
}
