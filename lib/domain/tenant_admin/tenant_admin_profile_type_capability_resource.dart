import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type_capability_operation.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

final class TenantAdminProfileTypeCapabilityResource {
  const TenantAdminProfileTypeCapabilityResource({
    required this.keyValue,
    required this.operations,
  });

  final TenantAdminRequiredTextValue keyValue;
  final List<TenantAdminProfileTypeCapabilityOperation> operations;

  String get key => keyValue.value;
}
