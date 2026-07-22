import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_candidate_selection_summary.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_account_profile_aggregate_revision_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';

class TenantAdminNestedGroupMemberPage {
  TenantAdminNestedGroupMemberPage({
    required List<TenantAdminAccountProfileSelectionSummary> items,
    required this.aggregateRevisionValue,
    required this.nextCursorValue,
  }) : items = List<TenantAdminAccountProfileSelectionSummary>.unmodifiable(
         items,
       );

  final List<TenantAdminAccountProfileSelectionSummary> items;
  final TenantAdminAccountProfileAggregateRevisionValue aggregateRevisionValue;
  final TenantAdminOptionalTextValue nextCursorValue;

  int get aggregateRevision => aggregateRevisionValue.value;
  String? get nextCursor => nextCursorValue.nullableValue;
}
