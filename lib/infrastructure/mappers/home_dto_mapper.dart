import 'package:belluga_now/domain/home/home_event.dart';
import 'package:belluga_now/domain/home/home_favorite.dart';
import 'package:belluga_now/domain/home/home_overview.dart';
import 'package:belluga_now/domain/value_objects/asset_path_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/home/home_event_dto.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/home/home_favorite_dto.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/home/home_overview_dto.dart';
import 'package:flutter/material.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';

/// Mixin used by infrastructure repositories to translate Home DTOs
/// into their domain counterparts while keeping DTO awareness out of
/// the domain layer.
mixin HomeDtoMapper {
  HomeOverview mapHomeOverview(HomeOverviewDTO dto) {
    return HomeOverview(
      favorites: dto.favorites.map(mapHomeFavorite).toList(),
      featuredEvents: dto.featuredEvents.map(mapHomeEvent).toList(),
      upcomingEvents: dto.upcomingEvents.map(mapHomeEvent).toList(),
    );
  }

  HomeFavorite mapHomeFavorite(HomeFavoriteDTO dto) {
    final title = TitleValue()..parse(dto.title);

    ThumbUriValue? imageUri;
    if (dto.imageUrl != null) {
      imageUri = ThumbUriValue(
        defaultValue: Uri.parse(dto.imageUrl!),
        isRequired: true,
      )..parse(dto.imageUrl);
    }

    AssetPathValue? assetPath;
    if (dto.assetPath != null) {
      assetPath = AssetPathValue(
        defaultValue: dto.assetPath!,
        isRequired: true,
      )..parse(dto.assetPath);
    }

    return HomeFavorite(
      titleValue: title,
      imageUriValue: imageUri,
      assetPathValue: assetPath,
      badgeIcon: dto.badgeIconCodePoint != null
          ? IconData(
              dto.badgeIconCodePoint!,
              fontFamily: dto.badgeFontFamily,
              fontPackage: dto.badgeFontPackage,
            )
          : null,
      isPrimary: dto.isPrimary,
    );
  }

  HomeEvent mapHomeEvent(HomeEventDTO dto) {
    final title = TitleValue()..parse(dto.title);
    final imageUri = ThumbUriValue(
      defaultValue: Uri.parse(dto.imageUrl),
      isRequired: true,
    )..parse(dto.imageUrl);

    final startDate = DateTimeValue(isRequired: true)
      ..parse(dto.startDateTime.toIso8601String());

    final location = DescriptionValue()..parse(dto.location);
    final artist = TitleValue()..parse(dto.artist);

    return HomeEvent(
      slug: dto.id ?? HomeEvent.slugify(dto.title),
      titleValue: title,
      imageUriValue: imageUri,
      startDateTimeValue: startDate,
      locationValue: location,
      artistValue: artist,
    );
  }
}
