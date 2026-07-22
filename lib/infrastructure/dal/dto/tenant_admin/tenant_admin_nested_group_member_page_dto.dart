import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_candidate_selection_summary.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_group_member_page.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_account_profile_aggregate_revision_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_account_profile_id_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';

class TenantAdminNestedGroupMemberPageDTO {
  const TenantAdminNestedGroupMemberPageDTO({
    required this.items,
    required this.aggregateRevision,
    required this.nextCursor,
  });

  final List<TenantAdminAccountProfileSelectionSummary> items;
  final int aggregateRevision;
  final String? nextCursor;

  factory TenantAdminNestedGroupMemberPageDTO.fromJson(
    Map<String, dynamic> json,
  ) {
    final items = <TenantAdminAccountProfileSelectionSummary>[];
    final rawItems = json['data'];
    if (rawItems is List) {
      for (final rawItem in rawItems) {
        if (rawItem is! Map) continue;
        final itemJson = Map<String, dynamic>.from(rawItem);
        final id = itemJson['id']?.toString().trim() ?? '';
        if (id.isEmpty) {
          continue;
        }
        items.add(
          TenantAdminAccountProfileSelectionSummary(
            idValue: TenantAdminAccountProfileIdValue(id),
            displayNameValue: TenantAdminOptionalTextValue()
              ..parse(itemJson['display_name']?.toString().trim()),
            isQueryableCandidateValue: TenantAdminFlagValue(
              itemJson['is_queryable_candidate'] == true,
            ),
            isContactCapableCandidateValue: TenantAdminFlagValue(false),
          ),
        );
      }
    }

    final rawCursor = json['next_cursor']?.toString().trim();

    return TenantAdminNestedGroupMemberPageDTO(
      items: items,
      aggregateRevision: _toInt(json['aggregate_revision']),
      nextCursor: rawCursor == null || rawCursor.isEmpty ? null : rawCursor,
    );
  }

  TenantAdminNestedGroupMemberPage toDomain() {
    return TenantAdminNestedGroupMemberPage(
      items: items,
      aggregateRevisionValue: TenantAdminAccountProfileAggregateRevisionValue(
        aggregateRevision,
      ),
      nextCursorValue: TenantAdminOptionalTextValue()..parse(nextCursor),
    );
  }

  static int _toInt(Object? raw) {
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }
}
