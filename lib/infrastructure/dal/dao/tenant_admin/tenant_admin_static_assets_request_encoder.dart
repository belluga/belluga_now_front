import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms.dart';

class TenantAdminStaticAssetsRequestEncoder {
  const TenantAdminStaticAssetsRequestEncoder();

  Map<String, dynamic> encodeStaticAssetPayload({
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
    if (slug != null) payload['slug'] = slug;
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

  Map<String, dynamic> encodeStaticProfileTypePayload({
    String? type,
    String? label,
    List<String>? allowedTaxonomies,
    TenantAdminStaticProfileTypeCapabilities? capabilities,
    TenantAdminPoiVisual? poiVisual,
    bool includePoiVisual = false,
  }) {
    final payload = <String, dynamic>{};
    if (type != null) payload['type'] = type;
    if (label != null) payload['label'] = label;
    if (allowedTaxonomies != null) {
      payload['allowed_taxonomies'] = allowedTaxonomies;
    }
    if (capabilities != null) {
      payload['capabilities'] = {
        'is_poi_enabled': capabilities.isPoiEnabled,
        'has_bio': capabilities.hasBio,
        'has_taxonomies': capabilities.hasTaxonomies,
        'has_avatar': capabilities.hasAvatar,
        'has_cover': capabilities.hasCover,
        'has_content': capabilities.hasContent,
      };
    }
    if (includePoiVisual) {
      payload['poi_visual'] = poiVisual?.toJson();
    }
    return payload;
  }
}
