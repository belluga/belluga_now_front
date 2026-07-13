import 'package:belluga_contact_channels/belluga_contact_channels.dart';
import 'package:belluga_now/domain/partners/account_profile_gallery_group.dart';
import 'package:belluga_now/domain/partners/engagement_data.dart';
import 'package:belluga_now/domain/partners/account_profile_nested_group.dart';
import 'package:belluga_now/domain/partners/projections/partner_profile_module_data.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_fields.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_public_detail_path_value.dart';
import 'package:belluga_now/domain/shared/account_profile_contact_source_summary.dart';
import 'package:belluga_now/domain/shared/value_objects/account_profile_contact_channel_id_value.dart';
import 'package:belluga_now/domain/shared/value_objects/account_profile_contact_source_account_profile_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

class AccountProfileModel {
  final MongoIDValue idValue;
  final TitleValue nameValue;
  final SlugValue slugValue;
  final AccountProfileTypeValue profileTypeValue;
  final ThumbUriValue? avatarValue;
  final ThumbUriValue? coverValue;
  final DescriptionValue? bioValue;
  final DescriptionValue? contentValue;
  final List<AccountProfileGalleryGroup> galleryGroupValues;
  final List<AccountProfileTagValue> tagValues;
  final List<PartnerEventView> agendaEventViews;
  final AccountProfileIsVerifiedValue isVerifiedValue;
  final EngagementData? engagementData;
  final AccountProfileAcceptedInvitesValue acceptedInvitesValue;
  final AccountProfileDistanceMetersValue distanceMetersValue;
  final AccountProfileLocationAddressValue? locationAddressValue;
  final LatitudeValue? locationLatitudeValue;
  final LongitudeValue? locationLongitudeValue;
  final List<AccountProfileNestedGroup> nestedProfileGroupValues;
  final DomainBooleanValue canOpenPublicDetailValue;
  final AccountProfilePublicDetailPathValue? publicDetailPathValue;
  final BellugaContactSourceMode contactMode;
  final AccountProfileContactSourceAccountProfileIdValue?
  contactSourceAccountProfileIdValue;
  final List<BellugaContactChannel> contactChannelValues;
  final AccountProfileContactChannelIdValue? contactBubbleChannelIdValue;
  final List<BellugaContactChannel> effectiveContactChannelValues;
  final BellugaContactChannel? effectiveContactBubbleChannelValue;
  final AccountProfileContactSourceSummary? contactSourceProfile;
  final AccountProfileContactSourceSummary? effectiveContactSourceProfile;

  AccountProfileModel({
    required this.idValue,
    required this.nameValue,
    required this.slugValue,
    required this.profileTypeValue,
    this.avatarValue,
    this.coverValue,
    this.bioValue,
    this.contentValue,
    List<AccountProfileGalleryGroup>? galleryGroupValues,
    List<AccountProfileTagValue>? tagValues,
    List<PartnerEventView>? agendaEventViews,
    AccountProfileIsVerifiedValue? isVerifiedValue,
    this.engagementData,
    AccountProfileAcceptedInvitesValue? acceptedInvitesValue,
    AccountProfileDistanceMetersValue? distanceMetersValue,
    this.locationAddressValue,
    this.locationLatitudeValue,
    this.locationLongitudeValue,
    List<AccountProfileNestedGroup>? nestedProfileGroupValues,
    DomainBooleanValue? canOpenPublicDetailValue,
    this.publicDetailPathValue,
    BellugaContactSourceMode? contactMode,
    AccountProfileContactSourceAccountProfileIdValue?
    contactSourceAccountProfileId,
    List<BellugaContactChannel>? contactChannelValues,
    AccountProfileContactChannelIdValue? contactBubbleChannelId,
    List<BellugaContactChannel>? effectiveContactChannelValues,
    this.effectiveContactBubbleChannelValue,
    this.contactSourceProfile,
    this.effectiveContactSourceProfile,
  }) : tagValues = List<AccountProfileTagValue>.unmodifiable(
         tagValues ?? const <AccountProfileTagValue>[],
       ),
       galleryGroupValues = List<AccountProfileGalleryGroup>.unmodifiable(
         galleryGroupValues ?? const <AccountProfileGalleryGroup>[],
       ),
       agendaEventViews = List<PartnerEventView>.unmodifiable(
         agendaEventViews ?? const <PartnerEventView>[],
       ),
       nestedProfileGroupValues = List<AccountProfileNestedGroup>.unmodifiable(
         nestedProfileGroupValues ?? const <AccountProfileNestedGroup>[],
       ),
       contactMode = contactMode ?? BellugaContactSourceMode.own,
       contactSourceAccountProfileIdValue = contactSourceAccountProfileId,
       contactChannelValues = List<BellugaContactChannel>.unmodifiable(
         contactChannelValues ?? const <BellugaContactChannel>[],
       ),
       contactBubbleChannelIdValue = contactBubbleChannelId,
       effectiveContactChannelValues = List<BellugaContactChannel>.unmodifiable(
         effectiveContactChannelValues ?? contactChannelValues ?? const [],
       ),
       canOpenPublicDetailValue =
           canOpenPublicDetailValue ??
           (DomainBooleanValue(defaultValue: false, isRequired: false)
             ..parse('false')),
       isVerifiedValue = isVerifiedValue ?? AccountProfileIsVerifiedValue(),
       acceptedInvitesValue =
           acceptedInvitesValue ?? AccountProfileAcceptedInvitesValue(),
       distanceMetersValue =
           distanceMetersValue ?? AccountProfileDistanceMetersValue();

  String get id => idValue.value;
  String get name => nameValue.value;
  String get slug => slugValue.value;
  String get type => profileTypeValue.value;
  String get profileType => type;
  Uri? get avatarUri => avatarValue?.value;
  String? get avatarUrl => avatarUri?.toString();
  Uri? get coverUri => coverValue?.value;
  String? get coverUrl => coverUri?.toString();
  String? get bio => bioValue?.value;
  String? get content => contentValue?.value;
  List<AccountProfileGalleryGroup> get galleryGroups =>
      List<AccountProfileGalleryGroup>.unmodifiable(galleryGroupValues);
  List<AccountProfileTagValue> get tags =>
      List<AccountProfileTagValue>.unmodifiable(tagValues);
  List<PartnerEventView> get agendaEvents =>
      List<PartnerEventView>.unmodifiable(agendaEventViews);
  bool get isVerified => isVerifiedValue.value;
  int get acceptedInvites => acceptedInvitesValue.value;
  double? get distanceMeters => distanceMetersValue.value;
  String? get locationAddress {
    final value = locationAddressValue?.value.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  double? get locationLat => locationLatitudeValue?.value;
  double? get locationLng => locationLongitudeValue?.value;
  List<AccountProfileNestedGroup> get nestedProfileGroups =>
      List<AccountProfileNestedGroup>.unmodifiable(nestedProfileGroupValues);
  bool get canOpenPublicDetail => canOpenPublicDetailValue.value;
  String? get contactSourceAccountProfileId {
    final raw = contactSourceAccountProfileIdValue?.value.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return raw;
  }

  List<BellugaContactChannel> get contactChannels =>
      List<BellugaContactChannel>.unmodifiable(contactChannelValues);
  List<BellugaContactChannel> get effectiveContactChannels =>
      List<BellugaContactChannel>.unmodifiable(effectiveContactChannelValues);
  String? get contactBubbleChannelId {
    final raw = contactBubbleChannelIdValue?.value.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return raw;
  }

  BellugaContactChannel? get effectiveContactBubbleChannel {
    final channel = effectiveContactBubbleChannelValue;
    return channel?.isBubbleEligible == true ? channel : null;
  }

  String? get publicDetailPath {
    final raw = publicDetailPathValue?.value.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return raw;
  }

  AccountProfileModel copyWith({
    MongoIDValue? idValue,
    TitleValue? nameValue,
    SlugValue? slugValue,
    AccountProfileTypeValue? profileTypeValue,
    ThumbUriValue? avatarValue,
    ThumbUriValue? coverValue,
    DescriptionValue? bioValue,
    DescriptionValue? contentValue,
    List<AccountProfileGalleryGroup>? galleryGroupValues,
    List<AccountProfileTagValue>? tagValues,
    List<PartnerEventView>? agendaEventViews,
    AccountProfileIsVerifiedValue? isVerifiedValue,
    EngagementData? engagementData,
    AccountProfileAcceptedInvitesValue? acceptedInvitesValue,
    AccountProfileDistanceMetersValue? distanceMetersValue,
    AccountProfileLocationAddressValue? locationAddressValue,
    LatitudeValue? locationLatitudeValue,
    LongitudeValue? locationLongitudeValue,
    List<AccountProfileNestedGroup>? nestedProfileGroupValues,
    DomainBooleanValue? canOpenPublicDetailValue,
    AccountProfilePublicDetailPathValue? publicDetailPathValue,
    BellugaContactSourceMode? contactMode,
    AccountProfileContactSourceAccountProfileIdValue?
    contactSourceAccountProfileId,
    List<BellugaContactChannel>? contactChannelValues,
    AccountProfileContactChannelIdValue? contactBubbleChannelId,
    List<BellugaContactChannel>? effectiveContactChannelValues,
    BellugaContactChannel? effectiveContactBubbleChannelValue,
    AccountProfileContactSourceSummary? contactSourceProfile,
    AccountProfileContactSourceSummary? effectiveContactSourceProfile,
  }) {
    return AccountProfileModel(
      idValue: idValue ?? this.idValue,
      nameValue: nameValue ?? this.nameValue,
      slugValue: slugValue ?? this.slugValue,
      profileTypeValue: profileTypeValue ?? this.profileTypeValue,
      avatarValue: avatarValue ?? this.avatarValue,
      coverValue: coverValue ?? this.coverValue,
      bioValue: bioValue ?? this.bioValue,
      contentValue: contentValue ?? this.contentValue,
      galleryGroupValues: galleryGroupValues ?? this.galleryGroupValues,
      tagValues: tagValues ?? this.tagValues,
      agendaEventViews: agendaEventViews ?? this.agendaEventViews,
      isVerifiedValue: isVerifiedValue ?? this.isVerifiedValue,
      engagementData: engagementData ?? this.engagementData,
      acceptedInvitesValue: acceptedInvitesValue ?? this.acceptedInvitesValue,
      distanceMetersValue: distanceMetersValue ?? this.distanceMetersValue,
      locationAddressValue: locationAddressValue ?? this.locationAddressValue,
      locationLatitudeValue:
          locationLatitudeValue ?? this.locationLatitudeValue,
      locationLongitudeValue:
          locationLongitudeValue ?? this.locationLongitudeValue,
      nestedProfileGroupValues:
          nestedProfileGroupValues ?? this.nestedProfileGroupValues,
      canOpenPublicDetailValue:
          canOpenPublicDetailValue ?? this.canOpenPublicDetailValue,
      publicDetailPathValue:
          publicDetailPathValue ?? this.publicDetailPathValue,
      contactMode: contactMode ?? this.contactMode,
      contactSourceAccountProfileId:
          contactSourceAccountProfileId ?? contactSourceAccountProfileIdValue,
      contactChannelValues: contactChannelValues ?? this.contactChannelValues,
      contactBubbleChannelId:
          contactBubbleChannelId ?? contactBubbleChannelIdValue,
      effectiveContactChannelValues:
          effectiveContactChannelValues ?? this.effectiveContactChannelValues,
      effectiveContactBubbleChannelValue:
          effectiveContactBubbleChannelValue ??
          this.effectiveContactBubbleChannelValue,
      contactSourceProfile: contactSourceProfile ?? this.contactSourceProfile,
      effectiveContactSourceProfile:
          effectiveContactSourceProfile ?? this.effectiveContactSourceProfile,
    );
  }
}
