import 'package:belluga_contact_channels/belluga_contact_channels.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_fields.dart';
import 'package:belluga_now/domain/shared/value_objects/account_profile_contact_source_account_profile_id_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_gallery_group.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_taxonomy_term_dto.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/shared/account_profile_contact_source_summary.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_profile_group.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';

class TenantAdminAccountProfileDTO {
  const TenantAdminAccountProfileDTO({
    required this.id,
    required this.accountId,
    required this.profileType,
    required this.displayName,
    this.slug,
    this.avatarUrl,
    this.coverUrl,
    this.bio,
    this.content,
    this.locationLat,
    this.locationLng,
    this.taxonomyTerms = const [],
    this.galleryGroups = const [],
    this.nestedProfileGroups = const [],
    this.ownershipState,
    this.contactMode,
    this.contactSourceAccountProfileId,
    this.contactChannels = const [],
    this.contactBubbleChannelId,
    this.effectiveContactChannels = const [],
    this.contactSourceProfile,
    this.effectiveContactSourceProfile,
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
  final double? locationLat;
  final double? locationLng;
  final List<TenantAdminTaxonomyTermDTO> taxonomyTerms;
  final List<TenantAdminAccountProfileGalleryGroup> galleryGroups;
  final List<TenantAdminNestedProfileGroup> nestedProfileGroups;
  final String? ownershipState;
  final String? contactMode;
  final String? contactSourceAccountProfileId;
  final List<BellugaContactChannel> contactChannels;
  final String? contactBubbleChannelId;
  final List<BellugaContactChannel> effectiveContactChannels;
  final AccountProfileContactSourceSummary? contactSourceProfile;
  final AccountProfileContactSourceSummary? effectiveContactSourceProfile;

  factory TenantAdminAccountProfileDTO.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    double? lat;
    double? lng;
    if (location is Map<String, dynamic>) {
      lat = _toDouble(location['lat']);
      lng = _toDouble(location['lng']);
    }
    final taxonomyRaw = json['taxonomy_terms'];
    final terms = <TenantAdminTaxonomyTermDTO>[];
    if (taxonomyRaw is List) {
      for (final entry in taxonomyRaw) {
        if (entry is Map<String, dynamic>) {
          terms.add(TenantAdminTaxonomyTermDTO.fromJson(entry));
        }
      }
    }
    final galleryGroups = <TenantAdminAccountProfileGalleryGroup>[];
    final galleryRaw = json['gallery_groups'];
    if (galleryRaw is List) {
      for (final entry in galleryRaw) {
        if (entry is! Map) continue;
        final group = _galleryGroupFromRaw(Map<String, dynamic>.from(entry));
        if (group != null) {
          galleryGroups.add(group);
        }
      }
    }
    final nestedGroups = <TenantAdminNestedProfileGroup>[];
    final nestedRaw = json['nested_profile_groups'];
    if (nestedRaw is List) {
      for (final entry in nestedRaw) {
        if (entry is! Map) continue;
        final groupJson = Map<String, dynamic>.from(entry);
        final rawIds =
            groupJson['account_profile_ids'] ?? groupJson['profile_ids'];
        nestedGroups.add(
          _nestedProfileGroupFromRaw(
            id: groupJson['id'] ?? groupJson['key'],
            label: groupJson['label'],
            order: groupJson['order'],
            accountProfileIds:
                rawIds is Iterable ? rawIds.cast<Object?>() : const <Object?>[],
          ),
        );
      }
    }
    return TenantAdminAccountProfileDTO(
      id: json['id']?.toString() ?? '',
      accountId: json['account_id']?.toString() ?? '',
      profileType: json['profile_type']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      slug: json['slug']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      coverUrl: json['cover_url']?.toString(),
      bio: json['bio']?.toString(),
      content: json['content']?.toString(),
      locationLat: lat,
      locationLng: lng,
      taxonomyTerms: terms,
      galleryGroups: galleryGroups,
      nestedProfileGroups: nestedGroups,
      ownershipState: json['ownership_state']?.toString(),
      contactMode: json['contact_mode']?.toString(),
      contactSourceAccountProfileId:
          json['contact_source_account_profile_id']?.toString(),
      contactChannels: BellugaContactChannelCodec.channelsFromJson(
        json['contact_channels'],
      ),
      contactBubbleChannelId: json['contact_bubble_channel_id']?.toString(),
      effectiveContactChannels: BellugaContactChannelCodec.channelsFromJson(
        json['effective_contact_channels'],
      ),
      contactSourceProfile: _contactSourceSummaryFromRaw(
        json['contact_source_account_profile'],
      ),
      effectiveContactSourceProfile: _contactSourceSummaryFromRaw(
        json['effective_contact_source'],
      ),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  TenantAdminAccountProfile toDomain() {
    final location = (locationLat != null && locationLng != null)
        ? tenantAdminLocationFromRaw(
            latitude: locationLat!,
            longitude: locationLng!,
          )
        : null;
    final taxonomy = TenantAdminTaxonomyTerms();
    for (final taxonomyTerm in taxonomyTerms) {
      taxonomy.add(taxonomyTerm.toDomain());
    }
    return tenantAdminAccountProfileFromRaw(
      id: id,
      accountId: accountId,
      profileType: profileType,
      displayName: displayName,
      slug: slug,
      avatarUrl: avatarUrl,
      coverUrl: coverUrl,
      bio: bio,
      content: content,
      location: location,
      taxonomyTerms: taxonomy,
      galleryGroups: galleryGroups,
      nestedProfileGroups: nestedProfileGroups,
      ownershipState: ownershipState == null
          ? null
          : tenantAdminOwnershipStateFromRaw(ownershipState),
      contactMode: BellugaContactSourceMode.fromRaw(contactMode),
      contactSourceAccountProfileId: contactSourceAccountProfileId,
      contactChannels: contactChannels,
      contactBubbleChannelId: contactBubbleChannelId,
      effectiveContactChannels: effectiveContactChannels,
      contactSourceProfile: contactSourceProfile,
      effectiveContactSourceProfile: effectiveContactSourceProfile,
    );
  }
}

AccountProfileContactSourceSummary? _contactSourceSummaryFromRaw(Object? raw) {
  if (raw is! Map) {
    return null;
  }
  final json = Map<String, dynamic>.from(raw);
  final id = json['id']?.toString().trim() ?? '';
  final displayName = json['display_name']?.toString().trim() ?? '';
  final profileType = json['profile_type']?.toString().trim() ?? '';
  if (id.isEmpty || displayName.isEmpty || profileType.isEmpty) {
    return null;
  }
  final slug = json['slug']?.toString().trim();
  return AccountProfileContactSourceSummary(
    idValue: AccountProfileContactSourceAccountProfileIdValue(id),
    displayNameValue: TitleValue()..parse(displayName),
    slugValue:
        slug == null || slug.isEmpty ? null : (SlugValue()..parse(slug)),
    profileTypeValue: AccountProfileTypeValue(profileType),
  );
}

TenantAdminAccountProfileGalleryGroup? _galleryGroupFromRaw(
  Map<String, dynamic> json,
) {
  final groupId = json['group_id']?.toString().trim() ?? '';
  final subtitle = json['subtitle']?.toString().trim() ?? '';
  if (groupId.isEmpty || subtitle.isEmpty) {
    return null;
  }

  final items = <TenantAdminAccountProfileGalleryItem>[];
  final rawItems = json['items'];
  if (rawItems is List) {
    for (final entry in rawItems) {
      if (entry is! Map) continue;
      final item = _galleryItemFromRaw(Map<String, dynamic>.from(entry));
      if (item != null) {
        items.add(item);
      }
    }
  }

  if (items.isEmpty) {
    return null;
  }

  items.sort((left, right) => left.order.compareTo(right.order));

  return TenantAdminAccountProfileGalleryGroup(
    groupIdValue: TenantAdminNestedProfileGroupTextValue(groupId),
    subtitleValue: TenantAdminNestedProfileGroupTextValue(subtitle),
    orderValue: TenantAdminNestedProfileGroupOrderValue(
      _toInt(json['order']) ?? 0,
    ),
    items: items,
  );
}

TenantAdminAccountProfileGalleryItem? _galleryItemFromRaw(
  Map<String, dynamic> json,
) {
  final itemId = json['item_id']?.toString().trim() ?? '';
  final imageUrl = json['image_url']?.toString().trim() ?? '';
  final thumbUrl = json['thumb_url']?.toString().trim() ?? '';
  final cardUrl = json['card_url']?.toString().trim() ?? '';
  final modalUrl = json['modal_url']?.toString().trim() ?? '';
  if (itemId.isEmpty ||
      imageUrl.isEmpty ||
      thumbUrl.isEmpty ||
      cardUrl.isEmpty ||
      modalUrl.isEmpty) {
    return null;
  }

  final description = json['description']?.toString().trim();
  return TenantAdminAccountProfileGalleryItem(
    itemIdValue: TenantAdminNestedProfileGroupTextValue(itemId),
    descriptionValue: TenantAdminOptionalTextValue()
      ..parse(description == null || description.isEmpty ? null : description),
    orderValue: TenantAdminNestedProfileGroupOrderValue(
      _toInt(json['order']) ?? 0,
    ),
    imageUrlValue: TenantAdminOptionalUrlValue()..parse(imageUrl),
    thumbUrlValue: TenantAdminOptionalUrlValue()..parse(thumbUrl),
    cardUrlValue: TenantAdminOptionalUrlValue()..parse(cardUrl),
    modalUrlValue: TenantAdminOptionalUrlValue()..parse(modalUrl),
  );
}

int? _toInt(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString());
}

TenantAdminNestedProfileGroup _nestedProfileGroupFromRaw({
  required Object? id,
  required Object? label,
  Object? order,
  Iterable<Object?> accountProfileIds = const <Object?>[],
}) {
  return TenantAdminNestedProfileGroup(
    idValue: TenantAdminNestedProfileGroupTextValue(
      id?.toString().trim() ?? '',
    ),
    labelValue: TenantAdminNestedProfileGroupTextValue(
      label?.toString().trim() ?? '',
    ),
    orderValue: TenantAdminNestedProfileGroupOrderValue(
      order is num ? order.toInt() : int.tryParse(order?.toString() ?? '') ?? 0,
    ),
    accountProfileIdValues: accountProfileIds
        .map((entry) => TenantAdminNestedProfileGroupTextValue(
              entry?.toString().trim() ?? '',
            ))
        .where((entry) => entry.value.isNotEmpty)
        .toList(growable: false),
  );
}
