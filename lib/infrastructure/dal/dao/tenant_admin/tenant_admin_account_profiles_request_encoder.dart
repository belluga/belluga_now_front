import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_profile_group.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms.dart';

class TenantAdminAccountProfilesRequestEncoder {
  const TenantAdminAccountProfilesRequestEncoder();

  Map<String, dynamic> encodeFetchAccountProfilesQuery({
    String? accountId,
    bool queryableOnly = false,
    String? excludeAccountProfileId,
  }) {
    final payload = <String, dynamic>{};
    if (accountId != null && accountId.trim().isNotEmpty) {
      payload['account_id'] = accountId.trim();
    }
    if (queryableOnly) {
      payload['queryable_only'] = true;
    }
    if (excludeAccountProfileId != null &&
        excludeAccountProfileId.trim().isNotEmpty) {
      payload['exclude_account_profile_id'] = excludeAccountProfileId.trim();
    }

    return payload;
  }

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
    List<TenantAdminNestedProfileGroup> nestedProfileGroups =
        const <TenantAdminNestedProfileGroup>[],
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
      if (nestedProfileGroups.isNotEmpty)
        'nested_profile_groups': _encodeNestedProfileGroups(
          nestedProfileGroups,
        ),
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
    List<TenantAdminNestedProfileGroup>? nestedProfileGroups,
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
    if (nestedProfileGroups != null) {
      payload['nested_profile_groups'] = _encodeNestedProfileGroups(
        nestedProfileGroups,
      );
    }
    return payload;
  }

  List<Map<String, dynamic>> _encodeNestedProfileGroups(
    List<TenantAdminNestedProfileGroup> groups,
  ) {
    return groups
        .map(
          (group) => {
            'id': group.id,
            'label': group.label,
            'order': group.order,
            'account_profile_ids': group.accountProfileIdValues
                .map((entry) => entry.value)
                .toList(),
          },
        )
        .toList(growable: false);
  }

  Map<String, dynamic> encodeCreateProfileType({
    required String type,
    required String label,
    String? pluralLabel,
    required List<String> allowedTaxonomies,
    required TenantAdminProfileTypeCapabilities capabilities,
    TenantAdminPoiVisual? visual,
    bool includeVisual = false,
    bool? removeTypeAsset,
  }) {
    final normalizedPlural = (pluralLabel ?? label).trim();
    return {
      'type': type,
      'label': label,
      'labels': {
        'singular': label,
        'plural': normalizedPlural.isEmpty ? label : normalizedPlural,
      },
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
    String? pluralLabel,
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
      final normalizedPlural = (pluralLabel ?? label).trim();
      payload['labels'] = {
        'singular': label,
        'plural': normalizedPlural.isEmpty ? label : normalizedPlural,
      };
    } else if (pluralLabel != null) {
      final normalizedPlural = pluralLabel.trim();
      payload['labels'] = {'plural': normalizedPlural};
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
    return Map<String, dynamic>.from(capabilities.toCapabilityMap().toJson());
  }
}
