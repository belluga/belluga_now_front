import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms.dart';

class TenantAdminAccountProfilesRequestEncoder {
  const TenantAdminAccountProfilesRequestEncoder();

  Map<String, dynamic> encodeCreateAccountProfile({
    required String accountId,
    required String profileType,
    required String displayName,
    TenantAdminLocation? location,
    TenantAdminTaxonomyTerms taxonomyTerms =
        const TenantAdminTaxonomyTerms.empty(),
    String? bio,
    String? content,
    String? avatarUrl,
    String? coverUrl,
  }) {
    return {
      'account_id': accountId,
      'profile_type': profileType,
      'display_name': displayName,
      if (location != null)
        'location': {'lat': location.latitude, 'lng': location.longitude},
      if (taxonomyTerms.isNotEmpty)
        'taxonomy_terms': taxonomyTerms
            .map((term) => {'type': term.type, 'value': term.value})
            .toList(),
      if (bio != null) 'bio': bio,
      if (content != null) 'content': content,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (coverUrl != null) 'cover_url': coverUrl,
    };
  }

  Map<String, dynamic> encodeUpdateAccountProfile({
    String? profileType,
    String? displayName,
    String? slug,
    TenantAdminLocation? location,
    TenantAdminTaxonomyTerms? taxonomyTerms,
    String? bio,
    String? content,
    String? avatarUrl,
    String? coverUrl,
    bool? removeAvatar,
    bool? removeCover,
  }) {
    final payload = <String, dynamic>{};
    if (profileType != null) payload['profile_type'] = profileType;
    if (displayName != null) payload['display_name'] = displayName;
    if (slug != null && slug.trim().isNotEmpty) payload['slug'] = slug.trim();
    if (location != null) {
      payload['location'] = {
        'lat': location.latitude,
        'lng': location.longitude,
      };
    }
    if (taxonomyTerms != null) {
      payload['taxonomy_terms'] = taxonomyTerms
          .map((term) => {'type': term.type, 'value': term.value})
          .toList();
    }
    if (bio != null) payload['bio'] = bio;
    if (content != null) payload['content'] = content;
    if (avatarUrl != null) payload['avatar_url'] = avatarUrl;
    if (coverUrl != null) payload['cover_url'] = coverUrl;
    if (removeAvatar == true) payload['remove_avatar'] = true;
    if (removeCover == true) payload['remove_cover'] = true;
    return payload;
  }

  Map<String, dynamic> encodeCreateProfileType({
    required String type,
    required String label,
    required List<String> allowedTaxonomies,
    required TenantAdminProfileTypeCapabilities capabilities,
    TenantAdminPoiVisual? visual,
    bool includeVisual = false,
    bool? removeTypeAsset,
  }) {
    return {
      'type': type,
      'label': label,
      'allowed_taxonomies': allowedTaxonomies,
      if (includeVisual) 'visual': visual?.toJson(),
      if (includeVisual) 'poi_visual': visual?.toJson(),
      if (removeTypeAsset == true) 'remove_type_asset': true,
      'capabilities': _encodeCapabilities(capabilities),
    };
  }

  Map<String, dynamic> encodeUpdateProfileType({
    String? newType,
    String? label,
    List<String>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
    TenantAdminPoiVisual? visual,
    bool includeVisual = false,
    bool? removeTypeAsset,
  }) {
    final payload = <String, dynamic>{};
    if (newType != null && newType.trim().isNotEmpty) {
      payload['type'] = newType.trim();
    }
    if (label != null) {
      payload['label'] = label;
    }
    if (allowedTaxonomies != null) {
      payload['allowed_taxonomies'] = allowedTaxonomies;
    }
    if (capabilities != null) {
      payload['capabilities'] = _encodeCapabilities(capabilities);
    }
    if (includeVisual) {
      payload['visual'] = visual?.toJson();
      payload['poi_visual'] = visual?.toJson();
    }
    if (removeTypeAsset == true) {
      payload['remove_type_asset'] = true;
    }
    return payload;
  }

  Map<String, dynamic> _encodeCapabilities(
    TenantAdminProfileTypeCapabilities capabilities,
  ) {
    return {
      'is_favoritable': capabilities.isFavoritable,
      'is_poi_enabled': capabilities.isPoiEnabled,
      'is_reference_location_enabled': capabilities.isReferenceLocationEnabled,
      'has_bio': capabilities.hasBio,
      'has_content': capabilities.hasContent,
      'has_taxonomies': capabilities.hasTaxonomies,
      'has_avatar': capabilities.hasAvatar,
      'has_cover': capabilities.hasCover,
      'has_events': capabilities.hasEvents,
    };
  }
}
