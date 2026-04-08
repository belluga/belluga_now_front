import 'package:belluga_now/domain/partners/engagement_data.dart';
import 'package:belluga_now/domain/partners/projections/partner_profile_module_data.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_fields.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
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
  final List<AccountProfileTagValue> tagValues;
  final List<PartnerEventView> agendaEventViews;
  final AccountProfileIsVerifiedValue isVerifiedValue;
  final EngagementData? engagementData;
  final AccountProfileAcceptedInvitesValue acceptedInvitesValue;
  final AccountProfileDistanceMetersValue distanceMetersValue;
  final AccountProfileLocationAddressValue? locationAddressValue;
  final LatitudeValue? locationLatitudeValue;
  final LongitudeValue? locationLongitudeValue;

  AccountProfileModel({
    required this.idValue,
    required this.nameValue,
    required this.slugValue,
    required this.profileTypeValue,
    this.avatarValue,
    this.coverValue,
    this.bioValue,
    this.contentValue,
    List<AccountProfileTagValue>? tagValues,
    List<PartnerEventView>? agendaEventViews,
    AccountProfileIsVerifiedValue? isVerifiedValue,
    this.engagementData,
    AccountProfileAcceptedInvitesValue? acceptedInvitesValue,
    AccountProfileDistanceMetersValue? distanceMetersValue,
    this.locationAddressValue,
    this.locationLatitudeValue,
    this.locationLongitudeValue,
  })  : tagValues = List<AccountProfileTagValue>.unmodifiable(
          tagValues ?? const <AccountProfileTagValue>[],
        ),
        agendaEventViews = List<PartnerEventView>.unmodifiable(
          agendaEventViews ?? const <PartnerEventView>[],
        ),
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

  AccountProfileModel copyWith({
    MongoIDValue? idValue,
    TitleValue? nameValue,
    SlugValue? slugValue,
    AccountProfileTypeValue? profileTypeValue,
    ThumbUriValue? avatarValue,
    ThumbUriValue? coverValue,
    DescriptionValue? bioValue,
    DescriptionValue? contentValue,
    List<AccountProfileTagValue>? tagValues,
    List<PartnerEventView>? agendaEventViews,
    AccountProfileIsVerifiedValue? isVerifiedValue,
    EngagementData? engagementData,
    AccountProfileAcceptedInvitesValue? acceptedInvitesValue,
    AccountProfileDistanceMetersValue? distanceMetersValue,
    AccountProfileLocationAddressValue? locationAddressValue,
    LatitudeValue? locationLatitudeValue,
    LongitudeValue? locationLongitudeValue,
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
    );
  }
}
