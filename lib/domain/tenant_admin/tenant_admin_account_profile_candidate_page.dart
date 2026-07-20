import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_candidate_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_count_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';

class TenantAdminAccountProfileCandidatePage {
  TenantAdminAccountProfileCandidatePage({
    required List<TenantAdminAccountProfileCandidate> items,
    required this.pageValue,
    required this.perPageValue,
    required this.hasMoreValue,
    required this.browseLimitReachedValue,
  }) : items = List<TenantAdminAccountProfileCandidate>.unmodifiable(items);

  final List<TenantAdminAccountProfileCandidate> items;
  final TenantAdminCountValue pageValue;
  final TenantAdminCountValue perPageValue;
  final TenantAdminFlagValue hasMoreValue;
  final TenantAdminFlagValue browseLimitReachedValue;

  int get page => pageValue.value;
  int get perPage => perPageValue.value;
  bool get hasMore => hasMoreValue.value;
  bool get browseLimitReached => browseLimitReachedValue.value;
}
