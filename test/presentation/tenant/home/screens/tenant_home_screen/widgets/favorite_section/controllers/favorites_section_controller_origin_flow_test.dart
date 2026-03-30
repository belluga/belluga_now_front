import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/environment_name_value.dart';
import 'package:belluga_now/domain/favorite/favorite.dart';
import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/favorite_repository_contract.dart';
import 'package:belluga_now/domain/tenant/value_objects/icon_url_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/main_color_value.dart';
import 'package:belluga_now/domain/value_objects/asset_path_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/favorite_section/controllers/favorites_section_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  test('favorites section keeps backend ordering from /favorites payload',
      () async {
    final favoriteRepository = _FakeFavoriteRepository(
      favoriteResumes: [
        _favoriteResume(title: 'Primeiro', slug: 'primeiro'),
        _favoriteResume(title: 'Segundo', slug: 'segundo'),
      ],
    );
    final controller = FavoritesSectionController(
      favoriteRepository: favoriteRepository,
      appDataRepository: _FakeAppDataRepository(),
    );

    await controller.init();

    final items = controller.favoritesStreamValue.value;
    expect(items, isNotNull);
    expect(items!.map((item) => item.title).toList(), ['Primeiro', 'Segundo']);
    expect(favoriteRepository.fetchFavoriteResumesCallCount, 1);

    controller.onDispose();
  });

  test('favorites section keeps cache and refreshes ordering on re-entry',
      () async {
    final favoriteRepository = _FakeFavoriteRepository(
      favoriteResumes: [
        _favoriteResume(title: 'Primeiro', slug: 'primeiro'),
      ],
    );

    final controller = FavoritesSectionController(
      favoriteRepository: favoriteRepository,
      appDataRepository: _FakeAppDataRepository(),
    );

    await controller.init();
    expect(
      controller.favoritesStreamValue.value?.map((item) => item.title).toList(),
      ['Primeiro'],
    );

    favoriteRepository.favoriteResumes = [
      _favoriteResume(title: 'Segundo', slug: 'segundo'),
      _favoriteResume(title: 'Primeiro', slug: 'primeiro'),
    ];

    final refreshFuture = controller.init();
    expect(
      controller.favoritesStreamValue.value?.map((item) => item.title).toList(),
      ['Primeiro'],
    );
    await refreshFuture;

    expect(favoriteRepository.fetchFavoriteResumesCallCount, 2);
    expect(controller.favoritesStreamValue.value, isNotNull);
    expect(
      controller.favoritesStreamValue.value?.map((item) => item.title).toList(),
      ['Segundo', 'Primeiro'],
    );

    controller.onDispose();
  });

  test(
      'favorites section resolves profile navigation by slug, search otherwise',
      () async {
    final controller = FavoritesSectionController(
      favoriteRepository: _FakeFavoriteRepository(),
      appDataRepository: _FakeAppDataRepository(),
    );

    final profileTarget = await controller.resolveNavigationTarget(
      _favoriteResume(title: 'Com Slug', slug: 'com-slug'),
    );

    expect(profileTarget, isA<FavoriteNavigationPartner>());
    expect(
      (profileTarget as FavoriteNavigationPartner).slug,
      'com-slug',
    );

    final searchTarget = await controller.resolveNavigationTarget(
      _favoriteResume(title: 'Sem slug', slug: null),
    );

    expect(searchTarget, isA<FavoriteNavigationSearch>());
    expect(
      (searchTarget as FavoriteNavigationSearch).query,
      'Sem slug',
    );

    controller.onDispose();
  });
}

FavoriteResume _favoriteResume({
  required String title,
  required String? slug,
}) {
  return FavoriteResume(
    titleValue: TitleValue()..parse(title),
    slugValue: slug != null ? (SlugValue()..parse(slug)) : null,
    assetPathValue: AssetPathValue()
      ..parse('assets/images/placeholder_avatar.png'),
  );
}

class _FakeFavoriteRepository extends FavoriteRepositoryContract {
  _FakeFavoriteRepository({
    this.favoriteResumes = const <FavoriteResume>[],
  });

  List<FavoriteResume> favoriteResumes;
  int fetchFavoriteResumesCallCount = 0;

  @override
  Future<List<Favorite>> fetchFavorites() async => <Favorite>[];

  @override
  Future<List<FavoriteResume>> fetchFavoriteResumes() async {
    fetchFavoriteResumesCallCount += 1;
    return favoriteResumes;
  }
}

class _FakeAppData extends Fake implements AppData {
  @override
  EnvironmentNameValue get nameValue => EnvironmentNameValue()..parse('Bora');

  @override
  IconUrlValue get mainIconLightUrl =>
      IconUrlValue()..parse('http://example.com/icon.png');

  @override
  MainColorValue get mainColor => MainColorValue()..parse('#112233');
}

class _FakeAppDataRepository implements AppDataRepositoryContract {
  _FakeAppDataRepository()
      : _appData = _FakeAppData(),
        themeModeStreamValue =
            StreamValue<ThemeMode?>(defaultValue: ThemeMode.light),
        maxRadiusMetersStreamValue = StreamValue<DistanceInMetersValue>(
          defaultValue: DistanceInMetersValue.fromRaw(5000, defaultValue: 5000),
        );

  final AppData _appData;

  @override
  AppData get appData => _appData;

  @override
  Future<void> init() async {}

  @override
  final StreamValue<ThemeMode?> themeModeStreamValue;

  @override
  ThemeMode get themeMode => ThemeMode.light;

  @override
  Future<void> setThemeMode(AppThemeModeValue mode) async {}

  @override
  final StreamValue<DistanceInMetersValue> maxRadiusMetersStreamValue;

  @override
  DistanceInMetersValue get maxRadiusMeters =>
      DistanceInMetersValue.fromRaw(5000, defaultValue: 5000);

  @override
  bool get hasPersistedMaxRadiusPreference => false;

  @override
  Future<void> setMaxRadiusMeters(DistanceInMetersValue meters) async {}
}
