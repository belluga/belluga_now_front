import 'dart:async';

import 'package:belluga_now/domain/favorite/favorite_badge.dart';
import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:belluga_now/domain/favorite/value_objects/favorite_badge_font_family_value.dart';
import 'package:belluga_now/domain/favorite/value_objects/favorite_badge_font_package_value.dart';
import 'package:belluga_now/domain/favorite/value_objects/favorite_badge_icon_value.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/repositories/favorite_repository_contract.dart';
import 'package:belluga_now/domain/repositories/account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/value_objects/asset_path_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
import 'package:stream_value/core/stream_value.dart';

class FavoritesSectionController implements Disposable {
  FavoritesSectionController({
    FavoriteRepositoryContract? favoriteRepository,
    AccountProfilesRepositoryContract? partnersRepository,
    ScheduleRepositoryContract? scheduleRepository,
    AppDataRepository? appDataRepository,
  })  : _favoriteRepository =
            favoriteRepository ?? GetIt.I.get<FavoriteRepositoryContract>(),
        _partnersRepository =
            partnersRepository ?? GetIt.I.get<AccountProfilesRepositoryContract>(),
        _scheduleRepository =
            scheduleRepository ?? GetIt.I.get<ScheduleRepositoryContract>(),
        _appDataRepository =
            appDataRepository ?? GetIt.I.get<AppDataRepository>();

  final FavoriteRepositoryContract _favoriteRepository;
  final AccountProfilesRepositoryContract _partnersRepository;
  final ScheduleRepositoryContract _scheduleRepository;
  final AppDataRepository _appDataRepository;

  final StreamValue<List<FavoriteResume>?> favoritesStreamValue =
      StreamValue<List<FavoriteResume>?>();

  StreamSubscription? _partnersSubscription;
  List<AccountProfileModel> _favoritePartnersCache = const [];
  List<VenueEventResume> _upcomingEventsCache = const [];

  Future<void> init() async {
    await _loadFavorites();
    await _loadUpcomingEvents();

    _partnersSubscription?.cancel();
    _partnersSubscription =
        _partnersRepository.favoriteAccountProfileIdsStreamValue.stream.listen((_) {
      _loadFavorites();
    });
  }

  Future<void> _loadUpcomingEvents() async {
    try {
      final events = await _scheduleRepository.fetchUpcomingEvents();
      _upcomingEventsCache = events;
      _resortFavoritesByUpcomingEvents();
    } catch (_) {
      // Keep last value.
    }
  }

  Future<void> _loadFavorites() async {
    final previousValue = favoritesStreamValue.value;
    try {
      final legacyFavorites = await _favoriteRepository.fetchFavoriteResumes();

      final appData = _appDataRepository.appData;
      final mainIconUri = appData.mainIconLightUrl.value;
      final primaryColor = _parseHexColor(appData.mainColor.value);

      final updatedLegacyFavorites = legacyFavorites.map((fav) {
        if (fav.isPrimary) {
          return FavoriteResume(
            titleValue: fav.titleValue,
            slug: fav.slug,
            imageUriValue: fav.imageUriValue,
            assetPathValue: fav.assetPathValue,
            badge: fav.badge,
            isPrimary: fav.isPrimary,
            iconImageUrl: mainIconUri?.toString(),
            primaryColor: primaryColor,
          );
        }
        return fav;
      }).toList();

      final partnerFavorites = _partnersRepository.getFavoriteAccountProfiles();
      _favoritePartnersCache = partnerFavorites;
      final partnerResumes = partnerFavorites.map((partner) {
        final hasAvatar =
            partner.avatarUrl != null && partner.avatarUrl!.isNotEmpty;
        final badgeIcon = _getAccountProfileTypeIcon(partner.type);
        final badge = FavoriteBadge(
          iconValue: FavoriteBadgeIconValue()
            ..parse(badgeIcon.codePoint.toString()),
          fontFamilyValue: badgeIcon.fontFamily != null
              ? (FavoriteBadgeFontFamilyValue()
                ..parse(badgeIcon.fontFamily!))
              : null,
          fontPackageValue: badgeIcon.fontPackage != null
              ? (FavoriteBadgeFontPackageValue()
                ..parse(badgeIcon.fontPackage!))
              : null,
        );

        return FavoriteResume(
          titleValue: TitleValue()..parse(partner.name),
          slug: partner.slug,
          imageUriValue: hasAvatar
              ? (ThumbUriValue(defaultValue: Uri.parse(partner.avatarUrl!)))
              : null,
          assetPathValue: !hasAvatar
              ? (AssetPathValue()
                ..parse('assets/images/placeholder_avatar.png'))
              : null,
          badge: badge,
          isPrimary: false,
        );
      }).toList();

      final allFavorites = [...updatedLegacyFavorites, ...partnerResumes];
      favoritesStreamValue.addValue(_sortFavorites(allFavorites));
    } catch (_) {
      favoritesStreamValue.addValue(previousValue);
    }
  }

  FavoriteResume buildPinnedFavorite() {
    final appData = _appDataRepository.appData;
    final mainIconUri = appData.mainIconLightUrl.value;
    final primaryColor = _parseHexColor(appData.mainColor.value);
    return FavoriteResume(
      titleValue: TitleValue()..parse(appData.nameValue.value),
      imageUriValue:
          mainIconUri != null ? ThumbUriValue(defaultValue: mainIconUri) : null,
      iconImageUrl: mainIconUri?.toString(),
      primaryColor: primaryColor,
      isPrimary: true,
    );
  }

  void _resortFavoritesByUpcomingEvents() {
    final current = favoritesStreamValue.value;
    if (current == null || current.isEmpty) return;
    favoritesStreamValue.addValue(_sortFavorites(List<FavoriteResume>.from(current)));
  }

  List<FavoriteResume> _sortFavorites(List<FavoriteResume> favorites) {
    final events = _upcomingEventsCache;
    final eventStartById = {
      for (final event in events) event.id: event.startDateTime,
    };
    final partnerBySlug = {
      for (final partner in _favoritePartnersCache) partner.slug: partner,
    };
    final normalizedEventMatches = {
      for (final event in events) event: _buildEventMatchKeys(event),
    };

    DateTime? nextDateFor(FavoriteResume favorite) {
      final slug = favorite.slug;
      final normalizedTitle = _normalizeMatchKey(favorite.title);
      DateTime? earliest;

      if (slug != null && slug.isNotEmpty) {
        final partner = partnerBySlug[slug];
        if (partner != null) {
          final dates = partner.upcomingEventIds
              .map((id) => eventStartById[id])
              .whereType<DateTime>()
              .toList()
            ..sort();
          if (dates.isNotEmpty) {
            return dates.first;
          }
        }
      }

      for (final entry in normalizedEventMatches.entries) {
        final matches = entry.value;
        if (!matches.contains(normalizedTitle)) continue;
        final start = entry.key.startDateTime;
        if (earliest == null || start.isBefore(earliest)) {
          earliest = start;
        }
      }

      return earliest;
    }

    favorites.sort((a, b) {
      if (a.isPrimary != b.isPrimary) {
        return a.isPrimary ? -1 : 1;
      }

      final aDate = nextDateFor(a);
      final bDate = nextDateFor(b);
      if (aDate == null && bDate == null) {
        return a.title.compareTo(b.title);
      }
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      final dateCompare = aDate.compareTo(bDate);
      if (dateCompare != 0) return dateCompare;
      return a.title.compareTo(b.title);
    });

    return favorites;
  }

  String _normalizeMatchKey(String input) {
    final lower = input.trim().toLowerCase();
    return lower.replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(
          RegExp(r'^-+|-+$'),
          '',
        );
  }

  Set<String> _buildEventMatchKeys(VenueEventResume event) {
    final keys = <String>{
      _normalizeMatchKey(event.title),
      _normalizeMatchKey(event.location),
    };
    if (event.hasArtists) {
      for (final artist in event.artists) {
        keys.add(_normalizeMatchKey(artist.displayName));
      }
    }
    return keys.where((key) => key.isNotEmpty).toSet();
  }

  IconData _getAccountProfileTypeIcon(String type) {
    switch (type) {
      case 'artist':
        return Icons.person;
      case 'venue':
        return Icons.place;
      case 'experience_provider':
        return Icons.local_activity;
      case 'influencer':
        return Icons.camera_alt;
      case 'curator':
        return Icons.verified_user;
      default:
        return Icons.account_circle;
    }
  }

  Color? _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final normalized = hex.replaceAll('#', '');
    if (normalized.length != 6 && normalized.length != 8) return null;
    final value = int.tryParse(
      normalized.length == 6 ? 'FF$normalized' : normalized,
      radix: 16,
    );
    if (value == null) return null;
    return Color(value);
  }

  @override
  void onDispose() {
    _partnersSubscription?.cancel();
    favoritesStreamValue.dispose();
  }
}
