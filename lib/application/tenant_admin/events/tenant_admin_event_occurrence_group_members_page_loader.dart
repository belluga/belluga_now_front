import 'package:belluga_now/domain/repositories/tenant_admin_events_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_group_member_page.dart';

final class TenantAdminEventOccurrenceGroupMembersPageLoader {
  const TenantAdminEventOccurrenceGroupMembersPageLoader({
    required this._eventsRepository,
  });

  final TenantAdminEventsRepositoryContract _eventsRepository;

  Future<TenantAdminNestedGroupMemberPage> loadPage({
    required String eventId,
    required String occurrenceId,
    required String groupId,
    String? cursor,
  }) {
    return _eventsRepository.fetchOccurrenceProfileGroupMembersPage(
      eventId: TenantAdminEventsRepoString.fromRaw(
        eventId,
        defaultValue: '',
        isRequired: true,
      ),
      occurrenceId: TenantAdminEventsRepoString.fromRaw(
        occurrenceId,
        defaultValue: '',
        isRequired: true,
      ),
      groupId: TenantAdminEventsRepoString.fromRaw(
        groupId,
        defaultValue: '',
        isRequired: true,
      ),
      cursor: cursor == null
          ? null
          : TenantAdminEventsRepoString.fromRaw(
              cursor,
              defaultValue: '',
              isRequired: true,
            ),
    );
  }
}
