import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms.dart';

class TenantAdminAccountsRequestEncoder {
  const TenantAdminAccountsRequestEncoder();

  Map<String, dynamic> encodeCreateAccount({
    required String name,
    required TenantAdminOwnershipState ownershipState,
    String? organizationId,
    TenantAdminDocument? document,
  }) {
    final payload = <String, dynamic>{
      'name': name,
      'ownership_state': ownershipState.apiValue,
      if (organizationId != null && organizationId.trim().isNotEmpty)
        'organization_id': organizationId.trim(),
    };
    if (document != null) {
      payload['document'] = {
        'type': document.type,
        'number': document.number,
      };
    }
    return payload;
  }

  Map<String, dynamic> encodeCreateOnboarding({
    required String name,
    required TenantAdminOwnershipState ownershipState,
    required String profileType,
    TenantAdminLocation? location,
    TenantAdminTaxonomyTerms taxonomyTerms =
        const TenantAdminTaxonomyTerms.empty(),
    String? bio,
    String? content,
  }) {
    return {
      'name': name,
      'ownership_state': ownershipState.apiValue,
      'profile_type': profileType,
      if (location != null)
        'location': {
          'lat': location.latitude,
          'lng': location.longitude,
        },
      if (taxonomyTerms.isNotEmpty)
        'taxonomy_terms': taxonomyTerms
            .map((term) => {'type': term.type, 'value': term.value})
            .toList(),
      if (bio != null) 'bio': bio,
      if (content != null) 'content': content,
    };
  }

  Map<String, dynamic> encodeUpdateAccount({
    String? name,
    String? slug,
    TenantAdminDocument? document,
    TenantAdminOwnershipState? ownershipState,
  }) {
    final payload = <String, dynamic>{};
    if (name != null && name.trim().isNotEmpty) {
      payload['name'] = name.trim();
    }
    if (slug != null && slug.trim().isNotEmpty) {
      payload['slug'] = slug.trim();
    }
    if (document != null) {
      payload['document'] = {
        'type': document.type,
        'number': document.number,
      };
    }
    if (ownershipState != null) {
      payload['ownership_state'] = ownershipState.apiValue;
    }
    return payload;
  }
}
