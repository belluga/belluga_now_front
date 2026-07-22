import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_candidate.dart';

final class TenantAdminAccountProfileCandidateDiscoveryPageLoader {
  const TenantAdminAccountProfileCandidateDiscoveryPageLoader({
    required this.repository,
  });

  final TenantAdminAccountProfilesRepositoryContract repository;

  Future<TenantAdminAccountProfileCandidatePage> loadPage({
    required TenantAdminAccountProfileCandidateScope scope,
    required String search,
    required int pageNumber,
    required int pageSize,
    String? excludeAccountProfileId,
  }) {
    return repository.fetchAccountProfileCandidatesPage(
      scope: scope,
      search: tenantAdminAccountProfilesRepoString(
        search,
        defaultValue: '',
        isRequired: true,
      ),
      page: tenantAdminAccountProfilesRepoInt(pageNumber, defaultValue: 1),
      pageSize: tenantAdminAccountProfilesRepoInt(
        pageSize,
        defaultValue: pageSize,
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
