import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';

class TenantAdminStaticAsset {
  const TenantAdminStaticAsset({
    required this.id,
    required this.profileType,
    required this.displayName,
    required this.slug,
    required this.isActive,
    this.avatarUrl,
    this.coverUrl,
    this.bio,
    this.content,
    this.tags = const [],
    this.categories = const [],
    this.taxonomyTerms = const [],
    this.location,
  });

  final String id;
  final String profileType;
  final String displayName;
  final String slug;
  final bool isActive;
  final String? avatarUrl;
  final String? coverUrl;
  final String? bio;
  final String? content;
  final List<String> tags;
  final List<String> categories;
  final List<TenantAdminTaxonomyTerm> taxonomyTerms;
  final TenantAdminLocation? location;
}
