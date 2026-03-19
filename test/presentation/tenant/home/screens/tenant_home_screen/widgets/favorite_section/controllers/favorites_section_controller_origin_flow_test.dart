import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/environment_name_value.dart';
import 'package:belluga_now/domain/favorite/favorite.dart';
import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/favorite_repository_contract.dart';
import 'package:belluga_now/domain/tenant/value_objects/icon_url_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/main_color_value.dart';
import 'package:belluga_now/domain/value_objects/asset_path_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/favorite_section/controllers/favorites_section_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  test('favorites section keeps backend ordering from /favorites payload',
      () async {
    final controller = FavoritesSectionController(
      favoriteRepository: _FakeFavoriteRepository(
        favoriteResumes: [
          _favoriteResume(title: 'Primeiro', slug: 'primeiro'),
          _favoriteResume(title: 'Segundo', slug: 'segundo'),
        ],
      ),
      appDataRepository: _FakeAppDataRepository(),
    );

    await controller.init();

    final items = controller.favoritesStreamValue.value;
    expect(items, isNotNull);
    expect(items!.map((item) => item.title).toList(), ['Primeiro', 'Segundo']);

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
    slug: slug,
    assetPathValue: AssetPathValue()
      ..parse('assets/images/placeholder_avatar.png'),
  );
}

class _FakeFavoriteRepository implements FavoriteRepositoryContract {
  _FakeFavoriteRepository({
    this.favoriteResumes = const <FavoriteResume>[],
  });

  final List<FavoriteResume> favoriteResumes;

  @override
  Future<List<Favorite>> fetchFavorites() async => <Favorite>[];

  @override
  Future<List<FavoriteResume>> fetchFavoriteResumes() async => favoriteResumes;
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
        maxRadiusMetersStreamValue = StreamValue<double>(defaultValue: 5000);

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
  Future<void> setThemeMode(ThemeMode mode) async {}

  @override
  final StreamValue<double> maxRadiusMetersStreamValue;

  @override
  double get maxRadiusMeters => 5000;

  @override
  Future<void> setMaxRadiusMeters(double meters) async {}
}
