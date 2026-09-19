import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

final class TenantAdminProfileTypeCapabilityOperation {
  const TenantAdminProfileTypeCapabilityOperation({
    required this.keyValue,
    required this.abilityValue,
  });

  final TenantAdminRequiredTextValue keyValue;
  final TenantAdminRequiredTextValue abilityValue;

  String get key => keyValue.value;
  String get ability => abilityValue.value;
}
