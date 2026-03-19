export 'favorite_navigation_target.dart';

import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/favorite_repository_contract.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/favorite_section/controllers/favorite_navigation_target.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
import 'package:stream_value/core/stream_value.dart';

class FavoritesSectionController implements Disposable {
  FavoritesSectionController({
    FavoriteRepositoryContract? favoriteRepository,
    AppDataRepositoryContract? appDataRepository,
  })  : _favoriteRepository =
            favoriteRepository ?? GetIt.I.get<FavoriteRepositoryContract>(),
        _appDataRepository =
            appDataRepository ?? GetIt.I.get<AppDataRepositoryContract>();

  final FavoriteRepositoryContract _favoriteRepository;
  final AppDataRepositoryContract _appDataRepository;

  final StreamValue<List<FavoriteResume>?> favoritesStreamValue =
      StreamValue<List<FavoriteResume>?>();
  final StreamValue<FavoriteNavigationTarget?> navigationTargetStreamValue =
      StreamValue<FavoriteNavigationTarget?>(defaultValue: null);

  Future<void> init() async {
    await _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final previousValue = favoritesStreamValue.value;
    try {
      final favorites = await _favoriteRepository.fetchFavoriteResumes();

      final appData = _appDataRepository.appData;
      final mainIconUri = appData.mainIconLightUrl.value;
      final primaryColor = _parseHexColor(appData.mainColor.value);

      final updated = favorites.map((fav) {
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
      }).toList(growable: false);

      favoritesStreamValue.addValue(updated);
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

  Future<FavoriteNavigationTarget> resolveNavigationTarget(
    FavoriteResume favorite,
  ) async {
    if (favorite.isPrimary) {
      return const FavoriteNavigationPrimary();
    }

    final slug = favorite.slug;
    if (slug != null && slug.isNotEmpty) {
      return FavoriteNavigationPartner(slug: slug);
    }

    return FavoriteNavigationSearch(query: favorite.title.trim());
  }

  Future<void> requestNavigationTarget(FavoriteResume favorite) async {
    final target = await resolveNavigationTarget(favorite);
    navigationTargetStreamValue.addValue(target);
  }

  void clearNavigationTarget() {
    navigationTargetStreamValue.addValue(null);
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
    favoritesStreamValue.dispose();
    navigationTargetStreamValue.dispose();
  }
}
