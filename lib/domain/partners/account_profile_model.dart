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
  final List<AccountProfileTagValue> tagValues;
  final List<AccountProfileUpcomingEventIdValue> upcomingEventIdValues;
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
    List<AccountProfileTagValue>? tagValues,
    List<AccountProfileUpcomingEventIdValue>? upcomingEventIdValues,
    AccountProfileIsVerifiedValue? isVerifiedValue,
    this.engagementData,
    AccountProfileAcceptedInvitesValue? acceptedInvitesValue,
    AccountProfileDistanceMetersValue? distanceMetersValue,
  })  : tagValues = List<AccountProfileTagValue>.unmodifiable(
         tagValues ?? const <AccountProfileTagValue>[],
       ),
        upcomingEventIdValues =
            List<AccountProfileUpcomingEventIdValue>.unmodifiable(
              upcomingEventIdValues ??
                  const <AccountProfileUpcomingEventIdValue>[],
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
  List<AccountProfileTagValue> get tags =>
      List<AccountProfileTagValue>.unmodifiable(tagValues);
  List<AccountProfileUpcomingEventIdValue> get upcomingEventIds =>
      List<AccountProfileUpcomingEventIdValue>.unmodifiable(
        upcomingEventIdValues,
      );
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
    List<AccountProfileTagValue>? tagValues,
    List<AccountProfileUpcomingEventIdValue>? upcomingEventIdValues,
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
      tagValues: tagValues ?? this.tagValues,
      upcomingEventIdValues:
          upcomingEventIdValues ?? this.upcomingEventIdValues,
      isVerifiedValue: isVerifiedValue ?? this.isVerifiedValue,
      engagementData: engagementData ?? this.engagementData,
      acceptedInvitesValue: acceptedInvitesValue ?? this.acceptedInvitesValue,
      distanceMetersValue: distanceMetersValue ?? this.distanceMetersValue,
    );
  }
}
