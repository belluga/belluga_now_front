import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_candidate_selection_summary.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';

class TenantAdminNestedGroupMemberPage {
  TenantAdminNestedGroupMemberPage({
    required List<TenantAdminAccountProfileSelectionSummary> items,
    required this.nextCursorValue,
  }) : items = List<TenantAdminAccountProfileSelectionSummary>.unmodifiable(
         items,
       );

  final List<TenantAdminAccountProfileSelectionSummary> items;
  final TenantAdminOptionalTextValue nextCursorValue;

  String? get nextCursor => nextCursorValue.nullableValue;
}
