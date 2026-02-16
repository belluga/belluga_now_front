import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';

class TenantAdminAccountProfile {
  const TenantAdminAccountProfile({
    required this.id,
    required this.accountId,
    required this.profileType,
    required this.displayName,
    this.slug,
    this.avatarUrl,
    this.coverUrl,
    this.bio,
    this.content,
    this.location,
    this.taxonomyTerms = const [],
    this.ownershipState,
  });

  final String id;
  final String accountId;
  final String profileType;
  final String displayName;
  final String? slug;
  final String? avatarUrl;
  final String? coverUrl;
  final String? bio;
  final String? content;
  final TenantAdminLocation? location;
  final List<TenantAdminTaxonomyTerm> taxonomyTerms;
  final TenantAdminOwnershipState? ownershipState;
}
