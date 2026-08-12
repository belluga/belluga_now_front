import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_profile_group.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';

class TenantAdminNestedGroupHeadMutationResult {
  TenantAdminNestedGroupHeadMutationResult({
    required List<TenantAdminNestedProfileGroup> groups,
    TenantAdminOptionalTextValue? occurrenceIdValue,
    TenantAdminOptionalTextValue? deletedGroupIdValue,
  }) : groups = List<TenantAdminNestedProfileGroup>.unmodifiable(groups),
       occurrenceIdValue = occurrenceIdValue ?? TenantAdminOptionalTextValue(),
       deletedGroupIdValue =
           deletedGroupIdValue ?? TenantAdminOptionalTextValue();

  final List<TenantAdminNestedProfileGroup> groups;
  final TenantAdminOptionalTextValue occurrenceIdValue;
  final TenantAdminOptionalTextValue deletedGroupIdValue;

  String? get occurrenceId => occurrenceIdValue.nullableValue;
  String? get deletedGroupId => deletedGroupIdValue.nullableValue;
}
