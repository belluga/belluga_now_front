import 'package:belluga_now/domain/repositories/value_objects/tenant_admin_account_profiles_repository_contract_values.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_candidate.dart';

abstract interface class TenantAdminAccountProfileCandidatesRepositoryContract {
  Future<TenantAdminAccountProfileCandidatePage>
  fetchAccountProfileCandidatesPage({
    required TenantAdminAccountProfileCandidateScope scope,
    required TenantAdminAccountProfilesRepositoryContractTextValue search,
    required TenantAdminAccountProfilesRepositoryContractIntValue page,
    required TenantAdminAccountProfilesRepositoryContractIntValue pageSize,
    TenantAdminAccountProfilesRepositoryContractTextValue?
    excludeAccountProfileId,
  });
}
