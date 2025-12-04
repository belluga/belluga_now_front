import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/partners/engagement_data.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

enum PartnerType {
  artist,
  venue,
  experienceProvider,
  influencer,
  curator,
}

class PartnerModel {
  final MongoIDValue idValue;
  final TitleValue nameValue;
  final SlugValue slugValue;
  final PartnerType type;
  final ThumbUriValue? avatarValue;
  final ThumbUriValue? coverValue;
  final DescriptionValue? bioValue;
  final List<String> tags;
  final List<String> upcomingEventIds;
  final bool isVerified;
  final EngagementData? engagementData;
  final int acceptedInvites; // Universal metric for all partners
  final double? distanceMeters;

  PartnerModel({
    required this.idValue,
    required this.nameValue,
    required this.slugValue,
    required this.type,
    this.avatarValue,
    this.coverValue,
    this.bioValue,
    List<String>? tags,
    List<String>? upcomingEventIds,
    this.isVerified = false,
    this.engagementData,
    this.acceptedInvites = 0,
    this.distanceMeters,
  })  : tags = List.unmodifiable(tags ?? const []),
        upcomingEventIds = List.unmodifiable(upcomingEventIds ?? const []);

  String get id => idValue.value;
  String get name => nameValue.value;
  String get slug => slugValue.value;
  Uri? get avatarUri => avatarValue?.value;
  String? get avatarUrl => avatarUri?.toString();
  Uri? get coverUri => coverValue?.value;
  String? get coverUrl => coverUri?.toString();
  String? get bio => bioValue?.value;

  factory PartnerModel.fromPrimitives({
    required String id,
    required String name,
    required String slug,
    required PartnerType type,
    String? avatarUrl,
    String? coverUrl,
    String? bio,
    List<String>? tags,
    List<String>? upcomingEventIds,
    bool isVerified = false,
    EngagementData? engagementData,
    int acceptedInvites = 0,
    double? distanceMeters,
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

    return PartnerModel(
      idValue: MongoIDValue()..parse(id),
      nameValue: TitleValue()..parse(name),
      slugValue: SlugValue()..parse(slug),
      type: type,
      avatarValue: avatarValue,
      coverValue: coverValue,
      bioValue: bioValue,
      tags: tags,
      upcomingEventIds: upcomingEventIds,
      isVerified: isVerified,
      engagementData: engagementData,
      acceptedInvites: acceptedInvites,
      distanceMeters: distanceMeters,
    );
  }

  PartnerModel copyWith({
    MongoIDValue? idValue,
    TitleValue? nameValue,
    SlugValue? slugValue,
    PartnerType? type,
    ThumbUriValue? avatarValue,
    ThumbUriValue? coverValue,
    DescriptionValue? bioValue,
    List<String>? tags,
    List<String>? upcomingEventIds,
    bool? isVerified,
    EngagementData? engagementData,
    int? acceptedInvites,
    double? distanceMeters,
  }) {
    return PartnerModel(
      idValue: idValue ?? this.idValue,
      nameValue: nameValue ?? this.nameValue,
      slugValue: slugValue ?? this.slugValue,
      type: type ?? this.type,
      avatarValue: avatarValue ?? this.avatarValue,
      coverValue: coverValue ?? this.coverValue,
      bioValue: bioValue ?? this.bioValue,
      tags: tags ?? this.tags,
      upcomingEventIds: upcomingEventIds ?? this.upcomingEventIds,
      isVerified: isVerified ?? this.isVerified,
      engagementData: engagementData ?? this.engagementData,
      acceptedInvites: acceptedInvites ?? this.acceptedInvites,
      distanceMeters: distanceMeters ?? this.distanceMeters,
    );
  }
}
