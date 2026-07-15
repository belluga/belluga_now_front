import 'package:belluga_contact_channels/belluga_contact_channels.dart';
import 'package:belluga_now/domain/shared/value_objects/account_profile_contact_channel_id_value.dart';
import 'package:belluga_now/domain/shared/value_objects/account_profile_contact_source_account_profile_id_value.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_gallery_group.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_profile_group.dart';
import 'package:belluga_now/domain/shared/account_profile_contact_source_summary.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms.dart';

TenantAdminAccountProfile tenantAdminAccountProfileFromRaw({
  required Object? id,
  required Object? accountId,
  required Object? profileType,
  required Object? displayName,
  Object? slug,
  Object? avatarUrl,
  Object? coverUrl,
  Object? bio,
  Object? content,
  TenantAdminLocation? location,
  TenantAdminTaxonomyTerms taxonomyTerms =
      const TenantAdminTaxonomyTerms.empty(),
  List<TenantAdminAccountProfileGalleryGroup> galleryGroups =
      const <TenantAdminAccountProfileGalleryGroup>[],
  List<TenantAdminNestedProfileGroup> nestedProfileGroups =
      const <TenantAdminNestedProfileGroup>[],
  TenantAdminOwnershipState? ownershipState,
  BellugaContactSourceMode contactMode = BellugaContactSourceMode.own,
  String? contactSourceAccountProfileId,
  List<BellugaContactChannel> contactChannels = const <BellugaContactChannel>[],
  String? contactBubbleChannelId,
  List<BellugaContactChannel> effectiveContactChannels =
      const <BellugaContactChannel>[],
  AccountProfileContactSourceSummary? contactSourceProfile,
  AccountProfileContactSourceSummary? effectiveContactSourceProfile,
}) {
  return TenantAdminAccountProfile(
    idValue: tenantAdminRequiredText(id),
    accountIdValue: tenantAdminRequiredText(accountId),
    profileTypeValue: tenantAdminRequiredText(profileType),
    displayNameValue: tenantAdminRequiredText(displayName),
    slugValue: tenantAdminOptionalText(slug),
    avatarUrlValue: tenantAdminOptionalUrl(avatarUrl),
    coverUrlValue: tenantAdminOptionalUrl(coverUrl),
    bioValue: tenantAdminOptionalText(bio),
    contentValue: tenantAdminOptionalText(content),
    location: location,
    taxonomyTerms: taxonomyTerms,
    galleryGroups: galleryGroups,
    nestedProfileGroups: nestedProfileGroups,
    ownershipState: ownershipState,
    contactModeValue: contactMode,
    contactSourceAccountProfileId:
        contactSourceAccountProfileId == null ||
            contactSourceAccountProfileId.trim().isEmpty
        ? null
        : AccountProfileContactSourceAccountProfileIdValue(
            contactSourceAccountProfileId,
          ),
    contactChannels: contactChannels,
    contactBubbleChannelId:
        contactBubbleChannelId == null || contactBubbleChannelId.trim().isEmpty
        ? null
        : AccountProfileContactChannelIdValue(contactBubbleChannelId),
    effectiveContactChannels: effectiveContactChannels,
    contactSourceProfile: contactSourceProfile,
    effectiveContactSourceProfile: effectiveContactSourceProfile,
  );
}
