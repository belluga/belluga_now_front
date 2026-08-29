import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_nested_profile_group_values.dart';

class TenantAdminNestedGroupLabelMutationResult {
  TenantAdminNestedGroupLabelMutationResult({
    required this.idValue,
    required this.labelValue,
  });

  final TenantAdminNestedProfileGroupTextValue idValue;
  final TenantAdminNestedProfileGroupTextValue labelValue;

  String get id => idValue.value;
  String get label => labelValue.value;
}
