import 'package:belluga_now/application/time/timezone_converter.dart';
import 'package:belluga_now/domain/favorite/favorite_badge.dart';
import 'package:belluga_now/domain/favorite/value_objects/favorite_event_occurrence_id_value.dart';
import 'package:belluga_now/domain/favorite/value_objects/favorite_event_target_path_value.dart';
import 'package:belluga_now/domain/favorite/value_objects/favorite_primary_flag_value.dart';
import 'package:belluga_now/domain/favorite/value_objects/favorite_target_type_value.dart';
import 'package:belluga_now/domain/partners/account_profile_summary.dart';
import 'package:belluga_now/domain/value_objects/asset_path_value.dart';
import 'package:belluga_now/domain/value_objects/domain_optional_date_time_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:flutter/material.dart';

enum FavoriteChipHaloState { none, upcoming, liveNow }

class FavoriteResume {
  FavoriteResume({
    required this.titleValue,
    this.slugValue,
    this.imageUriValue,
    this.assetPathValue,
    this.badge,
    FavoritePrimaryFlagValue? isPrimaryValue,
    this.iconImageUriValue,
    this.primaryColor,
    this.targetTypeValue,
    this.accountProfile,
    this.eventTargetPathValue,
    DomainOptionalDateTimeValue? nextEventOccurrenceAtValue,
    DomainOptionalDateTimeValue? lastEventOccurrenceAtValue,
    this.liveNowEventOccurrenceIdValue,
    DomainOptionalDateTimeValue? liveNowEventOccurrenceAtValue,
  }) : assert(
         imageUriValue != null || assetPathValue != null,
         'Provide either an image or an asset path.',
       ),
       assert(
         imageUriValue == null || assetPathValue == null,
         'Only one of image or asset path can be provided.',
       ),
       nextEventOccurrenceAtValue =
           nextEventOccurrenceAtValue ?? DomainOptionalDateTimeValue(),
       lastEventOccurrenceAtValue =
           lastEventOccurrenceAtValue ?? DomainOptionalDateTimeValue(),
       liveNowEventOccurrenceAtValue =
           liveNowEventOccurrenceAtValue ?? DomainOptionalDateTimeValue(),
       isPrimaryValue =
           isPrimaryValue ?? (FavoritePrimaryFlagValue()..parse('false'));

  final TitleValue titleValue;
  final SlugValue? slugValue;
  final ThumbUriValue? imageUriValue;
  final AssetPathValue? assetPathValue;
  final FavoriteBadge? badge;
  final FavoritePrimaryFlagValue isPrimaryValue;
  final ThumbUriValue? iconImageUriValue;
  final Color? primaryColor;
  final FavoriteTargetTypeValue? targetTypeValue;
  final AccountProfileSummary? accountProfile;
  final FavoriteEventTargetPathValue? eventTargetPathValue;
  final DomainOptionalDateTimeValue nextEventOccurrenceAtValue;
  final DomainOptionalDateTimeValue lastEventOccurrenceAtValue;
  final FavoriteEventOccurrenceIdValue? liveNowEventOccurrenceIdValue;
  final DomainOptionalDateTimeValue liveNowEventOccurrenceAtValue;

  String? get slug => slugValue?.value;
  bool get isPrimary => isPrimaryValue.value;
  String? get iconImageUrl => iconImageUriValue?.value.toString();
  String get title => titleValue.value;
  Uri? get imageUri => imageUriValue?.value;
  String? get assetPath => assetPathValue?.value;
  Uri? get coverImageUri => accountProfile?.coverUri;
  String? get coverImageUrl => coverImageUri?.toString();
  String? get targetType => targetTypeValue?.value;
  String? get profileType => accountProfile?.profileType;
  String? get publicDetailUrl => accountProfile?.publicDetailUrl;
  String? get targetId => accountProfile?.id;

  String? get eventTargetPath {
    final value = eventTargetPathValue?.value.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  DateTime? get nextEventOccurrenceAt => nextEventOccurrenceAtValue.value;
  DateTime? get lastEventOccurrenceAt => lastEventOccurrenceAtValue.value;
  String? get liveNowEventOccurrenceId => liveNowEventOccurrenceIdValue?.value;
  DateTime? get liveNowEventOccurrenceAt => liveNowEventOccurrenceAtValue.value;
  bool get isAccountProfileTarget => targetType == 'account_profile';
  bool get hasFutureEventOccurrence {
    final nextOccurrenceAt = nextEventOccurrenceAt;
    if (nextOccurrenceAt == null) {
      return false;
    }
    return nextOccurrenceAt.isAfter(
      TimezoneConverter.localToUtc(DateTime.now()),
    );
  }

  FavoriteChipHaloState get haloState {
    if ((liveNowEventOccurrenceId?.trim().isNotEmpty ?? false) ||
        liveNowEventOccurrenceAt != null) {
      return FavoriteChipHaloState.liveNow;
    }
    if (hasFutureEventOccurrence) {
      return FavoriteChipHaloState.upcoming;
    }
    return FavoriteChipHaloState.none;
  }
}
