import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_group_member_page.dart';

final class TenantAdminNestedGroupMembersPageLoader {
  const TenantAdminNestedGroupMembersPageLoader({
    required this.profilesRepository,
  });

  static const int _defaultPageSize = 20;

  final TenantAdminAccountProfilesRepositoryContract profilesRepository;

  Future<TenantAdminNestedGroupMemberPage> loadPage({
    required String accountProfileId,
    required String groupId,
    String? cursor,
  }) {
    return profilesRepository.fetchNestedGroupMembersPage(
      accountProfileId: tenantAdminAccountProfilesRepoString(
        accountProfileId,
        defaultValue: '',
        isRequired: true,
      ),
      groupId: tenantAdminAccountProfilesRepoString(
        groupId,
        defaultValue: '',
        isRequired: true,
      ),
      perPage: cursor == null
          ? tenantAdminAccountProfilesRepoInt(
              _defaultPageSize,
              defaultValue: _defaultPageSize,
            )
          : null,
      cursor: cursor == null
          ? null
          : tenantAdminAccountProfilesRepoString(
              cursor,
              defaultValue: '',
              isRequired: true,
            ),
    );
  }
}
