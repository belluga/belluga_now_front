import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_candidate_selection_summary.dart';

final class TenantAdminGroupMembersPageState {
  const TenantAdminGroupMembersPageState({
    this.items = const <TenantAdminAccountProfileSelectionSummary>[],
    this.errorMessage,
    this.initialLoading = true,
    this.pageLoading = false,
    this.mutationLoading = false,
    this.searchAvailable = false,
    this.search = '',
    this.hasMore = false,
  });

  final List<TenantAdminAccountProfileSelectionSummary> items;
  final String? errorMessage;
  final bool initialLoading;
  final bool pageLoading;
  final bool mutationLoading;
  final bool searchAvailable;
  final String search;
  final bool hasMore;
}
