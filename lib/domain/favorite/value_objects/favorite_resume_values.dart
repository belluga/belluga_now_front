import 'package:belluga_now/domain/favorite/favorite_badge.dart';
import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:belluga_now/domain/favorite/value_objects/favorite_event_occurrence_id_value.dart';
import 'package:belluga_now/domain/favorite/value_objects/favorite_event_target_path_value.dart';
import 'package:belluga_now/domain/favorite/value_objects/favorite_primary_flag_value.dart';
import 'package:belluga_now/domain/favorite/value_objects/favorite_public_detail_path_value.dart';
import 'package:belluga_now/domain/favorite/value_objects/favorite_target_type_value.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_type_value.dart';
import 'package:belluga_now/domain/value_objects/asset_path_value.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';
import 'package:belluga_now/domain/value_objects/domain_optional_date_time_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:flutter/material.dart';

FavoriteResume favoriteResumeFromRaw({
  required TitleValue titleValue,
  SlugValue? slugValue,
  ThumbUriValue? imageUriValue,
  AssetPathValue? assetPathValue,
  FavoriteBadge? badge,
  FavoritePrimaryFlagValue? isPrimaryValue,
  ThumbUriValue? iconImageUriValue,
  Color? primaryColor,
  String? targetType,
  String? profileType,
  ThumbUriValue? coverImageUriValue,
  bool canOpenPublicDetail = false,
  String? publicDetailPath,
  String? eventTargetPath,
  DateTime? nextEventOccurrenceAt,
  DateTime? lastEventOccurrenceAt,
  String? liveNowEventOccurrenceId,
  DateTime? liveNowEventOccurrenceAt,
}) {
  return FavoriteResume(
    titleValue: titleValue,
    slugValue: slugValue,
    imageUriValue: imageUriValue,
    assetPathValue: assetPathValue,
    badge: badge,
    isPrimaryValue: isPrimaryValue,
    iconImageUriValue: iconImageUriValue,
    primaryColor: primaryColor,
    targetTypeValue: _targetTypeValueOrNull(targetType),
    profileTypeValue: _profileTypeValueOrNull(profileType),
    coverImageUriValue: coverImageUriValue,
    canOpenPublicDetailValue: DomainBooleanValue(
      defaultValue: canOpenPublicDetail,
      isRequired: false,
    )..parse(canOpenPublicDetail.toString()),
    publicDetailPathValue: _publicDetailPathValueOrNull(publicDetailPath),
    eventTargetPathValue: _eventTargetPathValueOrNull(eventTargetPath),
    nextEventOccurrenceAtValue: _optionalDateTimeValue(nextEventOccurrenceAt),
    lastEventOccurrenceAtValue: _optionalDateTimeValue(lastEventOccurrenceAt),
    liveNowEventOccurrenceIdValue:
        _occurrenceIdValueOrNull(liveNowEventOccurrenceId),
    liveNowEventOccurrenceAtValue:
        _optionalDateTimeValue(liveNowEventOccurrenceAt),
  );
}

FavoriteTargetTypeValue? _targetTypeValueOrNull(String? raw) {
  final normalized = raw?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return FavoriteTargetTypeValue(normalized);
}

AccountProfileTypeValue? _profileTypeValueOrNull(String? raw) {
  final normalized = raw?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return AccountProfileTypeValue(normalized);
}

FavoriteEventOccurrenceIdValue? _occurrenceIdValueOrNull(String? raw) {
  final normalized = raw?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return FavoriteEventOccurrenceIdValue(normalized);
}

FavoritePublicDetailPathValue? _publicDetailPathValueOrNull(String? raw) {
  final normalized = raw?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return FavoritePublicDetailPathValue(normalized);
}

FavoriteEventTargetPathValue? _eventTargetPathValueOrNull(String? raw) {
  final normalized = raw?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return FavoriteEventTargetPathValue(normalized);
}

DomainOptionalDateTimeValue _optionalDateTimeValue(DateTime? raw) {
  return DomainOptionalDateTimeValue(defaultValue: raw)
    ..parse(raw?.toIso8601String());
}
