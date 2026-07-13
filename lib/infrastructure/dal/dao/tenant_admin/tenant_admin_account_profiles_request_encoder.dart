import 'package:belluga_contact_channels/belluga_contact_channels.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_gallery_update.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_profile_group.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_admin/support/tenant_admin_nested_profile_group_payload_encoder.dart';

class TenantAdminAccountProfilesRequestEncoder {
  const TenantAdminAccountProfilesRequestEncoder();

  TenantAdminAccountProfileGalleryEncodedPayload
  encodeUpdateAccountProfileGallery(
    List<TenantAdminAccountProfileGalleryUpdateGroup> groups,
  ) {
    final uploads = <String, TenantAdminMediaUpload>{};

    final payload = groups
        .map((group) {
          final items = group.items
              .map((item) {
                final upload = item.upload;
                String? uploadKey;
                if (upload != null) {
                  uploadKey = 'upload_${group.groupId}_${item.itemId}'
                      .replaceAll(RegExp(r'[^a-zA-Z0-9_]+'), '_');
                  uploads[uploadKey] = upload;
                }

                return <String, dynamic>{
                  'item_id': item.itemId,
                  'description': item.description,
                  'order': item.order,
                  'upload': ?uploadKey,
                };
              })
              .toList(growable: false);

          return <String, dynamic>{
            'group_id': group.groupId,
            'subtitle': group.subtitle,
            'order': group.order,
            'items': items,
          };
        })
        .toList(growable: false);

    return (galleryGroups: payload, uploads: uploads);
  }

  Map<String, dynamic> encodeFetchAccountProfilesQuery({
    String? accountId,
    bool queryableOnly = false,
    String? excludeAccountProfileId,
    String? search,
    int? page,
    int? pageSize,
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
    if (search != null && search.trim().isNotEmpty) {
      payload['search'] = search.trim();
    }
    if (page != null && page > 0) {
      payload['page'] = page;
    }
    if (pageSize != null && pageSize > 0) {
      payload['page_size'] = pageSize;
    }

    return payload;
  }

  Map<String, dynamic> encodeFetchContactSourceCandidatesQuery({
    required int page,
    required int pageSize,
    String? excludeAccountProfileId,
  }) {
    final payload = <String, dynamic>{'page': page, 'per_page': pageSize};
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
    BellugaContactSourceMode contactMode = BellugaContactSourceMode.own,
    String? contactSourceAccountProfileId,
    List<BellugaContactChannelDraft> contactChannelDrafts =
        const <BellugaContactChannelDraft>[],
    BellugaContactBubbleSelectionMutation bubbleSelection =
        const BellugaContactBubbleSelectionMutation.omit(),
  }) {
    final payload = <String, dynamic>{
      'account_id': accountId,
      'profile_type': profileType,
      'display_name': displayName,
      if (location != null)
        'location': {'lat': location.latitude, 'lng': location.longitude},
      if (taxonomyTerms.isNotEmpty)
        'taxonomy_terms': taxonomyTerms
            .map((term) => {'type': term.type, 'value': term.value})
            .toList(),
      'bio': ?bio,
      'content': ?content,
      'avatar_url': ?avatarUrl,
      'cover_url': ?coverUrl,
      if (nestedProfileGroups.isNotEmpty)
        'nested_profile_groups': encodeTenantAdminNestedProfileGroups(
          nestedProfileGroups,
        ),
      'contact_mode': contactMode.rawValue,
      'contact_source_account_profile_id': ?contactSourceAccountProfileId,
      'contact_channels': BellugaContactChannelCodec.draftsToJson(
        contactChannelDrafts,
      ),
    };
    bubbleSelection.encodeInto(payload);
    return payload;
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
    BellugaContactSourceMode? contactMode,
    String? contactSourceAccountProfileId,
    List<BellugaContactChannelDraft>? contactChannelDrafts,
    BellugaContactBubbleSelectionMutation bubbleSelection =
        const BellugaContactBubbleSelectionMutation.omit(),
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
      payload['nested_profile_groups'] = encodeTenantAdminNestedProfileGroups(
        nestedProfileGroups,
      );
    }
    if (contactMode != null) {
      payload['contact_mode'] = contactMode.rawValue;
    }
    if (contactSourceAccountProfileId != null) {
      payload['contact_source_account_profile_id'] =
          contactSourceAccountProfileId;
    }
    if (contactChannelDrafts != null) {
      payload['contact_channels'] = BellugaContactChannelCodec.draftsToJson(
        contactChannelDrafts,
      );
    }
    bubbleSelection.encodeInto(payload);
    return payload;
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

typedef TenantAdminAccountProfileGalleryEncodedPayload = ({
  List<Map<String, dynamic>> galleryGroups,
  Map<String, TenantAdminMediaUpload> uploads,
});
