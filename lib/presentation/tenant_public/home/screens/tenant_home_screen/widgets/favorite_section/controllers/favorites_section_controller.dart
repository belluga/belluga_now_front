export 'favorite_navigation_target.dart';

import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:belluga_now/domain/favorite/value_objects/favorite_primary_flag_value.dart';
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

  StreamValue<List<FavoriteResume>?> get favoritesStreamValue =>
      _favoriteRepository.favoriteResumesStreamValue;
  final StreamValue<FavoriteNavigationTarget?> navigationTargetStreamValue =
      StreamValue<FavoriteNavigationTarget?>(defaultValue: null);

  Future<void> init() async {
    if (favoritesStreamValue.value == null) {
      await _favoriteRepository.initializeFavoriteResumes();
      return;
    }

    await _favoriteRepository.refreshFavoriteResumes();
  }

  FavoriteResume buildPinnedFavorite() {
    final appData = _appDataRepository.appData;
    final mainIconUri = appData.mainIconLightUrl.value;
    final primaryColor = _parseHexColor(appData.mainColor.value);
    final isPrimaryValue = FavoritePrimaryFlagValue()..parse('true');
    final iconImageUriValue = mainIconUri != null
        ? (ThumbUriValue(
            defaultValue: mainIconUri,
            isRequired: true,
          )..parse(mainIconUri.toString()))
        : null;

    return FavoriteResume(
      titleValue: TitleValue()..parse(appData.nameValue.value),
      imageUriValue: iconImageUriValue,
      iconImageUriValue: iconImageUriValue,
      primaryColor: primaryColor,
      isPrimaryValue: isPrimaryValue,
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
