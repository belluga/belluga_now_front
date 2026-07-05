import 'package:belluga_now/domain/repositories/tenant_admin_events_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event_account_profile_candidate_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';

final class TenantAdminEventAccountProfileCandidatesPageLoader {
  const TenantAdminEventAccountProfileCandidatesPageLoader({
    required this._eventsRepository,
  });

  final TenantAdminEventsRepositoryContract _eventsRepository;

  Future<TenantAdminPagedResult<TenantAdminAccountProfile>> loadPage({
    required TenantAdminEventAccountProfileCandidateType candidateType,
    required int pageNumber,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? accountSlug,
  }) {
    final pageSize = switch (candidateType) {
      TenantAdminEventAccountProfileCandidateType.relatedAccountProfile => 20,
      TenantAdminEventAccountProfileCandidateType.physicalHost => 50,
    };

    return _eventsRepository.fetchEventAccountProfileCandidatesPage(
      candidateType: candidateType,
      page: TenantAdminEventsRepoInt.fromRaw(
        pageNumber,
        defaultValue: pageNumber,
      ),
      pageSize: TenantAdminEventsRepoInt.fromRaw(
        pageSize,
        defaultValue: pageSize,
      ),
      search: search,
      accountSlug: accountSlug,
    );
  }
}
