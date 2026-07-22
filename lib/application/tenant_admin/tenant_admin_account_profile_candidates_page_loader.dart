import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';

final class TenantAdminAccountProfileCandidatesPageLoader {
  const TenantAdminAccountProfileCandidatesPageLoader({
    required TenantAdminAccountProfilesRepositoryContract profilesRepository,
  }) : _profilesRepository = profilesRepository;

  static const int _defaultPageSize = 20;

  final TenantAdminAccountProfilesRepositoryContract _profilesRepository;

  Future<TenantAdminPagedResult<TenantAdminAccountProfile>> loadPage({
    required int pageNumber,
    String? search,
    String? accountId,
    bool queryableOnly = false,
    String? excludeAccountProfileId,
  }) {
    return _profilesRepository.fetchAccountProfilesPage(
      page: tenantAdminAccountProfilesRepoInt(
        pageNumber,
        defaultValue: pageNumber,
      ),
      pageSize: tenantAdminAccountProfilesRepoInt(
        _defaultPageSize,
        defaultValue: _defaultPageSize,
      ),
      search: search == null || search.isEmpty
          ? null
          : tenantAdminAccountProfilesRepoString(search, defaultValue: ''),
      accountId: accountId == null || accountId.isEmpty
          ? null
          : tenantAdminAccountProfilesRepoString(
              accountId,
              defaultValue: '',
              isRequired: true,
            ),
      queryableOnly: tenantAdminAccountProfilesRepoBool(
        queryableOnly,
        defaultValue: queryableOnly,
      ),
      excludeAccountProfileId:
          excludeAccountProfileId == null || excludeAccountProfileId.isEmpty
          ? null
          : tenantAdminAccountProfilesRepoString(
              excludeAccountProfileId,
              defaultValue: '',
              isRequired: true,
            ),
    );
  }
}
