import 'package:belluga_now/domain/tenant_admin/tenant_admin_group_order_entry.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_nested_profile_group_values.dart';

export 'package:belluga_now/domain/tenant_admin/tenant_admin_group_move_direction.dart';
export 'package:belluga_now/domain/tenant_admin/tenant_admin_group_order_entry.dart';
export 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_nested_profile_group_values.dart';

class TenantAdminGroupOrderMutationResult {
  TenantAdminGroupOrderMutationResult({
    this.accountProfileIdValue,
    this.eventIdValue,
    this.occurrenceIdValue,
    required List<TenantAdminGroupOrderEntry> groups,
  }) : groups = List<TenantAdminGroupOrderEntry>.unmodifiable(groups);

  final TenantAdminNestedProfileGroupTextValue? accountProfileIdValue;
  final TenantAdminNestedProfileGroupTextValue? eventIdValue;
  final TenantAdminNestedProfileGroupTextValue? occurrenceIdValue;
  final List<TenantAdminGroupOrderEntry> groups;

  String? get accountProfileId => accountProfileIdValue?.value;
  String? get eventId => eventIdValue?.value;
  String? get occurrenceId => occurrenceIdValue?.value;
}
