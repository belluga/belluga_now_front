import 'package:belluga_now/domain/partners/account_profile_gallery_group.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/account_profile_nested_group.dart';
import 'package:belluga_now/domain/partners/engagement_data.dart';
import 'package:belluga_now/domain/partners/projections/partner_profile_module_data.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_nested_group_member_text_value.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_fields.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_public_detail_path_value.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

AccountProfileModel buildAccountProfileModelFromPrimitives({
  required String id,
  required String name,
  required String slug,
  required String type,
  String? avatarUrl,
  String? coverUrl,
  String? bio,
  String? content,
  List<AccountProfileGalleryGroup>? galleryGroups,
  List<String>? tags,
  List<PartnerEventView>? agendaEvents,
  bool isVerified = false,
  EngagementData? engagementData,
  int acceptedInvites = 0,
  double? distanceMeters,
  String? locationAddress,
  double? locationLat,
  double? locationLng,
  List<AccountProfileNestedGroup>? nestedProfileGroups,
  bool canOpenPublicDetail = true,
  String? publicDetailPath,
}) {
  ThumbUriValue? avatarValue;
  if (avatarUrl != null && avatarUrl.isNotEmpty) {
    avatarValue = ThumbUriValue(defaultValue: Uri.parse(avatarUrl))
      ..parse(avatarUrl);
  }

  ThumbUriValue? coverValue;
  if (coverUrl != null && coverUrl.isNotEmpty) {
    coverValue = ThumbUriValue(defaultValue: Uri.parse(coverUrl))
      ..parse(coverUrl);
  }

  DescriptionValue? bioValue;
  if (bio != null && bio.isNotEmpty) {
    bioValue = DescriptionValue()..parse(bio);
  }
  DescriptionValue? contentValue;
  if (content != null && content.isNotEmpty) {
    contentValue = DescriptionValue()..parse(content);
  }

  AccountProfileLocationAddressValue? locationAddressValue;
  if (locationAddress != null && locationAddress.isNotEmpty) {
    locationAddressValue = AccountProfileLocationAddressValue()
      ..parse(locationAddress);
  }

  LatitudeValue? locationLatitudeValue;
  if (locationLat != null) {
    locationLatitudeValue = LatitudeValue()..parse(locationLat.toString());
  }

  LongitudeValue? locationLongitudeValue;
  if (locationLng != null) {
    locationLongitudeValue = LongitudeValue()..parse(locationLng.toString());
  }

  final canOpenPublicDetailValue =
      DomainBooleanValue(defaultValue: canOpenPublicDetail, isRequired: false)
        ..parse(canOpenPublicDetail.toString());
  final resolvedPublicDetailPath =
      canOpenPublicDetail ? (publicDetailPath ?? '/parceiro/$slug') : null;

  return AccountProfileModel(
    idValue: MongoIDValue()..parse(id),
    nameValue: TitleValue()..parse(name),
    slugValue: SlugValue()..parse(slug),
    profileTypeValue: AccountProfileTypeValue(type),
    avatarValue: avatarValue,
    coverValue: coverValue,
    bioValue: bioValue,
    contentValue: contentValue,
    galleryGroupValues: galleryGroups,
    tagValues: _buildTagValues(tags),
    agendaEventViews: List<PartnerEventView>.unmodifiable(
      agendaEvents ?? const <PartnerEventView>[],
    ),
    isVerifiedValue: AccountProfileIsVerifiedValue(isVerified),
    engagementData: engagementData,
    acceptedInvitesValue: AccountProfileAcceptedInvitesValue(acceptedInvites),
    distanceMetersValue: AccountProfileDistanceMetersValue(distanceMeters),
    locationAddressValue: locationAddressValue,
    locationLatitudeValue: locationLatitudeValue,
    locationLongitudeValue: locationLongitudeValue,
    nestedProfileGroupValues: nestedProfileGroups,
    canOpenPublicDetailValue: canOpenPublicDetailValue,
    publicDetailPathValue: resolvedPublicDetailPath == null
        ? null
        : AccountProfilePublicDetailPathValue(resolvedPublicDetailPath),
  );
}

List<AccountProfileTagValue> _buildTagValues(List<String>? tags) {
  return (tags ?? const <String>[])
      .map(AccountProfileTagValue.new)
      .toList(growable: false);
}

AccountProfileGalleryGroup buildAccountProfileGalleryGroupFromPrimitives({
  required String groupId,
  required String subtitle,
  int order = 0,
  List<AccountProfileGalleryItem>? items,
}) {
  return AccountProfileGalleryGroup(
    groupIdValue: AccountProfileNestedGroupIdValue(groupId),
    subtitleValue: AccountProfileNestedGroupLabelValue(subtitle),
    orderValue: AccountProfileNestedGroupOrderValue(order),
    items: items,
  );
}

AccountProfileGalleryItem buildAccountProfileGalleryItemFromPrimitives({
  required String itemId,
  required String imageUrl,
  required String thumbUrl,
  required String cardUrl,
  required String modalUrl,
  String? description,
  int order = 0,
}) {
  return AccountProfileGalleryItem(
    itemIdValue: AccountProfileNestedGroupIdValue(itemId),
    descriptionValue:
        AccountProfileNestedGroupMemberTextValue(description ?? ''),
    orderValue: AccountProfileNestedGroupOrderValue(order),
    imageUrlValue: ThumbUriValue(defaultValue: Uri.parse(imageUrl))
      ..parse(imageUrl),
    thumbUrlValue: ThumbUriValue(defaultValue: Uri.parse(thumbUrl))
      ..parse(thumbUrl),
    cardUrlValue: ThumbUriValue(defaultValue: Uri.parse(cardUrl))
      ..parse(cardUrl),
    modalUrlValue: ThumbUriValue(defaultValue: Uri.parse(modalUrl))
      ..parse(modalUrl),
  );
}
