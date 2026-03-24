import 'package:belluga_now/domain/partners/engagement_data.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_fields.dart';
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
  final AccountProfileTagsValue tagsValue;
  final AccountProfileUpcomingEventIdsValue upcomingEventIdsValue;
  final AccountProfileIsVerifiedValue isVerifiedValue;
  final EngagementData? engagementData;
  final AccountProfileAcceptedInvitesValue acceptedInvitesValue;
  final AccountProfileDistanceMetersValue distanceMetersValue;

  AccountProfileModel({
    required this.idValue,
    required this.nameValue,
    required this.slugValue,
    required this.profileTypeValue,
    this.avatarValue,
    this.coverValue,
    this.bioValue,
    AccountProfileTagsValue? tagsValue,
    AccountProfileUpcomingEventIdsValue? upcomingEventIdsValue,
    AccountProfileIsVerifiedValue? isVerifiedValue,
    this.engagementData,
    AccountProfileAcceptedInvitesValue? acceptedInvitesValue,
    AccountProfileDistanceMetersValue? distanceMetersValue,
  })  : tagsValue = tagsValue ?? AccountProfileTagsValue(),
        upcomingEventIdsValue =
            upcomingEventIdsValue ?? AccountProfileUpcomingEventIdsValue(),
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
  List<String> get tags => tagsValue.value;
  List<String> get upcomingEventIds => upcomingEventIdsValue.value;
  bool get isVerified => isVerifiedValue.value;
  int get acceptedInvites => acceptedInvitesValue.value;
  double? get distanceMeters => distanceMetersValue.value;

  AccountProfileModel copyWith({
    MongoIDValue? idValue,
    TitleValue? nameValue,
    SlugValue? slugValue,
    AccountProfileTypeValue? profileTypeValue,
    ThumbUriValue? avatarValue,
    ThumbUriValue? coverValue,
    DescriptionValue? bioValue,
    AccountProfileTagsValue? tagsValue,
    AccountProfileUpcomingEventIdsValue? upcomingEventIdsValue,
    AccountProfileIsVerifiedValue? isVerifiedValue,
    EngagementData? engagementData,
    AccountProfileAcceptedInvitesValue? acceptedInvitesValue,
    AccountProfileDistanceMetersValue? distanceMetersValue,
  }) {
    return AccountProfileModel(
      idValue: idValue ?? this.idValue,
      nameValue: nameValue ?? this.nameValue,
      slugValue: slugValue ?? this.slugValue,
      profileTypeValue: profileTypeValue ?? this.profileTypeValue,
      avatarValue: avatarValue ?? this.avatarValue,
      coverValue: coverValue ?? this.coverValue,
      bioValue: bioValue ?? this.bioValue,
      tagsValue: tagsValue ?? this.tagsValue,
      upcomingEventIdsValue:
          upcomingEventIdsValue ?? this.upcomingEventIdsValue,
      isVerifiedValue: isVerifiedValue ?? this.isVerifiedValue,
      engagementData: engagementData ?? this.engagementData,
      acceptedInvitesValue: acceptedInvitesValue ?? this.acceptedInvitesValue,
      distanceMetersValue: distanceMetersValue ?? this.distanceMetersValue,
    );
  }
}
