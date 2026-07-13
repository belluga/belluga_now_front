import 'package:belluga_contact_channels/belluga_contact_channels.dart';
import 'package:belluga_now/domain/shared/value_objects/account_profile_contact_channel_id_value.dart';
import 'package:belluga_now/domain/shared/value_objects/account_profile_contact_source_account_profile_id_value.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_gallery_group.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_profile_group.dart';
import 'package:belluga_now/domain/shared/account_profile_contact_source_summary.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
export 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_account_profile_values.dart';

class TenantAdminAccountProfile {
  TenantAdminAccountProfile({
    required this.idValue,
    required this.accountIdValue,
    required this.profileTypeValue,
    required this.displayNameValue,
    TenantAdminOptionalTextValue? slugValue,
    TenantAdminOptionalUrlValue? avatarUrlValue,
    TenantAdminOptionalUrlValue? coverUrlValue,
    TenantAdminOptionalTextValue? bioValue,
    TenantAdminOptionalTextValue? contentValue,
    this.location,
    TenantAdminTaxonomyTerms? taxonomyTerms,
    List<TenantAdminAccountProfileGalleryGroup>? galleryGroups,
    List<TenantAdminNestedProfileGroup>? nestedProfileGroups,
    this.ownershipState,
    BellugaContactSourceMode? contactMode,
    AccountProfileContactSourceAccountProfileIdValue?
    contactSourceAccountProfileId,
    List<BellugaContactChannel>? contactChannels,
    AccountProfileContactChannelIdValue? contactBubbleChannelId,
    List<BellugaContactChannel>? effectiveContactChannels,
    this.contactSourceProfile,
    this.effectiveContactSourceProfile,
  }) : slugValue = slugValue ?? TenantAdminOptionalTextValue(),
       avatarUrlValue = avatarUrlValue ?? TenantAdminOptionalUrlValue(),
       coverUrlValue = coverUrlValue ?? TenantAdminOptionalUrlValue(),
       bioValue = bioValue ?? TenantAdminOptionalTextValue(),
       contentValue = contentValue ?? TenantAdminOptionalTextValue(),
       taxonomyTerms = taxonomyTerms ?? const TenantAdminTaxonomyTerms.empty(),
       galleryGroups = List<TenantAdminAccountProfileGalleryGroup>.unmodifiable(
         galleryGroups ?? const <TenantAdminAccountProfileGalleryGroup>[],
       ),
       nestedProfileGroups = List<TenantAdminNestedProfileGroup>.unmodifiable(
         nestedProfileGroups ?? const <TenantAdminNestedProfileGroup>[],
       ),
       contactMode = contactMode ?? BellugaContactSourceMode.own,
       contactSourceAccountProfileIdValue = contactSourceAccountProfileId,
       contactChannels = List<BellugaContactChannel>.unmodifiable(
         contactChannels ?? const <BellugaContactChannel>[],
       ),
       contactBubbleChannelIdValue = contactBubbleChannelId,
       effectiveContactChannels = List<BellugaContactChannel>.unmodifiable(
         effectiveContactChannels ?? contactChannels ?? const [],
       );

  final TenantAdminRequiredTextValue idValue;
  final TenantAdminRequiredTextValue accountIdValue;
  final TenantAdminRequiredTextValue profileTypeValue;
  final TenantAdminRequiredTextValue displayNameValue;
  final TenantAdminOptionalTextValue slugValue;
  final TenantAdminOptionalUrlValue avatarUrlValue;
  final TenantAdminOptionalUrlValue coverUrlValue;
  final TenantAdminOptionalTextValue bioValue;
  final TenantAdminOptionalTextValue contentValue;
  final TenantAdminLocation? location;
  final TenantAdminTaxonomyTerms taxonomyTerms;
  final List<TenantAdminAccountProfileGalleryGroup> galleryGroups;
  final List<TenantAdminNestedProfileGroup> nestedProfileGroups;
  final TenantAdminOwnershipState? ownershipState;
  final BellugaContactSourceMode contactMode;
  final AccountProfileContactSourceAccountProfileIdValue?
  contactSourceAccountProfileIdValue;
  final List<BellugaContactChannel> contactChannels;
  final AccountProfileContactChannelIdValue? contactBubbleChannelIdValue;
  final List<BellugaContactChannel> effectiveContactChannels;
  final AccountProfileContactSourceSummary? contactSourceProfile;
  final AccountProfileContactSourceSummary? effectiveContactSourceProfile;

  String get id => idValue.value;
  String get accountId => accountIdValue.value;
  String get profileType => profileTypeValue.value;
  String get displayName => displayNameValue.value;
  String? get slug => slugValue.nullableValue;
  String? get avatarUrl => avatarUrlValue.nullableValue;
  String? get coverUrl => coverUrlValue.nullableValue;
  String? get bio => bioValue.nullableValue;
  String? get content => contentValue.nullableValue;
  String? get contactSourceAccountProfileId {
    final raw = contactSourceAccountProfileIdValue?.value.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return raw;
  }

  String? get contactBubbleChannelId {
    final raw = contactBubbleChannelIdValue?.value.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return raw;
  }

  BellugaContactChannel? get effectiveContactBubbleChannel {
    final selectedId = contactBubbleChannelId;
    if (selectedId == null || selectedId.isEmpty) {
      return null;
    }
    for (final channel in effectiveContactChannels) {
      if (channel.id == selectedId && channel.isBubbleEligible) {
        return channel;
      }
    }
    return null;
  }
}
