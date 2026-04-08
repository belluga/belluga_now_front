import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/engagement_data.dart';
import 'package:belluga_now/domain/partners/projections/partner_profile_module_data.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_fields.dart';
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
  List<String>? tags,
  List<PartnerEventView>? agendaEvents,
  bool isVerified = false,
  EngagementData? engagementData,
  int acceptedInvites = 0,
  double? distanceMeters,
  String? locationAddress,
  double? locationLat,
  double? locationLng,
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

  return AccountProfileModel(
    idValue: MongoIDValue()..parse(id),
    nameValue: TitleValue()..parse(name),
    slugValue: SlugValue()..parse(slug),
    profileTypeValue: AccountProfileTypeValue(type),
    avatarValue: avatarValue,
    coverValue: coverValue,
    bioValue: bioValue,
    contentValue: contentValue,
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
  );
}

List<AccountProfileTagValue> _buildTagValues(List<String>? tags) {
  return (tags ?? const <String>[])
      .map(AccountProfileTagValue.new)
      .toList(growable: false);
}
