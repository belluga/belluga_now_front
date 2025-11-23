import 'dart:async';

import 'package:belluga_now/domain/favorite/favorite_badge.dart';
import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:belluga_now/domain/favorite/value_objects/favorite_badge_font_family_value.dart';
import 'package:belluga_now/domain/favorite/value_objects/favorite_badge_font_package_value.dart';
import 'package:belluga_now/domain/favorite/value_objects/favorite_badge_icon_value.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/partners/partner_model.dart';
import 'package:belluga_now/domain/repositories/favorite_repository_contract.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/partners_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';

import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/value_objects/asset_path_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class TenantHomeController implements Disposable {
  TenantHomeController({
    required FavoriteRepositoryContract favoriteRepository,
    ScheduleRepositoryContract? scheduleRepository,
    UserEventsRepositoryContract? userEventsRepository,
    required PartnersRepositoryContract partnersRepository,
    InvitesRepositoryContract? invitesRepository,
  })  : _favoriteRepository = favoriteRepository,
        _scheduleRepository =
            scheduleRepository ?? GetIt.I.get<ScheduleRepositoryContract>(),
        _userEventsRepository =
            userEventsRepository ?? GetIt.I.get<UserEventsRepositoryContract>(),
        _partnersRepository = partnersRepository,
        _invitesRepository =
            invitesRepository ?? GetIt.I.get<InvitesRepositoryContract>();

  final FavoriteRepositoryContract _favoriteRepository;
  final ScheduleRepositoryContract _scheduleRepository;
  final UserEventsRepositoryContract _userEventsRepository;
  final PartnersRepositoryContract _partnersRepository;
  final InvitesRepositoryContract _invitesRepository;

  final StreamValue<List<FavoriteResume>?> favoritesStreamValue =
      StreamValue<List<FavoriteResume>?>();
  final StreamValue<List<VenueEventResume>> myEventsStreamValue =
      StreamValue<List<VenueEventResume>>(defaultValue: []);
  final StreamValue<List<VenueEventResume>> upcomingEventsStreamValue =
      StreamValue<List<VenueEventResume>>(defaultValue: []);

  StreamValue<Set<String>> get confirmedIdsStream =>
      _userEventsRepository.confirmedEventIdsStream;

  StreamValue<List<InviteModel>> get pendingInvitesStreamValue =>
      _invitesRepository.pendingInvitesStreamValue;

  StreamSubscription? _myEventsSubscription;
  StreamSubscription? _partnersSubscription;

  Future<void> init() async {
    await loadFavorites();
    await loadMyEvents();
    await loadUpcomingEvents();

    // Listen for changes in favorite partners
    _partnersSubscription =
        _partnersRepository.favoritePartnerIdsStreamValue.stream.listen((_) {
      loadFavorites();
    });

    // Listen for changes in confirmed events
    _myEventsSubscription =
        _userEventsRepository.confirmedEventIdsStream.stream.listen((_) {
      loadMyEvents();
    });
  }

  Future<void> loadFavorites() async {
    final previousValue = favoritesStreamValue.value;
    // Don't set to null here to avoid flashing loading state on updates
    // favoritesStreamValue.addValue(null);
    try {
      // 1. Legacy favorites (App Manager)
      final legacyFavorites = await _favoriteRepository.fetchFavoriteResumes();

      // Get app data for app owner
      final appData = GetIt.I.get<AppDataRepository>().appData;
      final iconUrl = appData.iconUrl?.value?.toString();
      final colorHex = appData.mainColor?.value;

      Color? primaryColor;
      if (colorHex != null && colorHex.isNotEmpty) {
        // Parse hex color (e.g., "#4FA0E3")
        final hexColor = colorHex.replaceAll('#', '');
        primaryColor = Color(int.parse('FF$hexColor', radix: 16));
      }

      // Update legacy favorites (app owner) with app data
      final updatedLegacyFavorites = legacyFavorites.map((fav) {
        if (fav.isPrimary) {
          return FavoriteResume(
            titleValue: fav.titleValue,
            slug: fav.slug,
            imageUriValue: fav.imageUriValue,
            assetPathValue: fav.assetPathValue,
            badge: fav.badge,
            isPrimary: fav.isPrimary,
            iconImageUrl: iconUrl,
            primaryColor: primaryColor,
          );
        }
        return fav;
      }).toList();

      // 2. Partner favorites
      final partnerFavorites = _partnersRepository.getFavoritePartners();
      final partnerResumes = partnerFavorites.map((p) {
        // Use placeholder if no avatar
        final hasAvatar = p.avatarUrl != null && p.avatarUrl!.isNotEmpty;

        // Create category badge based on partner type
        final badgeIcon = _getPartnerTypeIcon(p.type);
        final badge = FavoriteBadge(
          iconValue: FavoriteBadgeIconValue()
            ..parse(badgeIcon.codePoint.toString()),
          fontFamilyValue: badgeIcon.fontFamily != null
              ? (FavoriteBadgeFontFamilyValue()..parse(badgeIcon.fontFamily!))
              : null,
          fontPackageValue: badgeIcon.fontPackage != null
              ? (FavoriteBadgeFontPackageValue()..parse(badgeIcon.fontPackage!))
              : null,
        );

        return FavoriteResume(
          titleValue: TitleValue()..parse(p.name),
          slug: p.slug,
          imageUriValue: hasAvatar
              ? (ThumbUriValue(defaultValue: Uri.parse(p.avatarUrl!)))
              : null,
          assetPathValue: !hasAvatar
              ? (AssetPathValue()
                ..parse('assets/images/placeholder_avatar.png'))
              : null,
          badge: badge,
          isPrimary: false,
        );
      }).toList();

      // 3. Merge
      final allFavorites = [...updatedLegacyFavorites, ...partnerResumes];
      favoritesStreamValue.addValue(allFavorites);
    } catch (_) {
      favoritesStreamValue.addValue(previousValue);
    }
  }

  Future<void> loadMyEvents() async {
    final previousValue = myEventsStreamValue.value;
    // Don't set to null here to avoid flashing loading state on updates
    // myEventsStreamValue.addValue(null);
    try {
      final events = await _userEventsRepository.fetchMyEvents();
      myEventsStreamValue.addValue(events);
    } catch (_) {
      myEventsStreamValue.addValue(previousValue);
    }
  }

  Future<void> loadUpcomingEvents() async {
    try {
      final events = await _scheduleRepository.fetchUpcomingEvents();
      upcomingEventsStreamValue.addValue(events);
    } catch (_) {
      // keep last value; StreamValue already holds previous state
    }
  }

  /// Get icon for partner type badge
  IconData _getPartnerTypeIcon(PartnerType type) {
    switch (type) {
      case PartnerType.artist:
        return Icons.person;
      case PartnerType.venue:
        return Icons.place;
      case PartnerType.experienceProvider:
        return Icons.local_activity;
    }
  }

  @override
  void onDispose() {
    _myEventsSubscription?.cancel();
    _partnersSubscription?.cancel();
    favoritesStreamValue.dispose();
    myEventsStreamValue.dispose();
    upcomingEventsStreamValue.dispose();
  }
}
