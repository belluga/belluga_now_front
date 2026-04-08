import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/environment_name_value.dart';
import 'package:belluga_now/domain/favorite/favorite.dart';
import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:belluga_now/domain/favorite/value_objects/favorite_resume_values.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/partners/profile_type_capabilities.dart';
import 'package:belluga_now/domain/partners/profile_type_definition.dart';
import 'package:belluga_now/domain/partners/profile_type_definitions.dart';
import 'package:belluga_now/domain/partners/profile_type_registry.dart';
import 'package:belluga_now/domain/partners/profile_type_visual.dart';
import 'package:belluga_now/domain/partners/value_objects/profile_type_key_value.dart';
import 'package:belluga_now/domain/partners/value_objects/profile_type_label_value.dart';
import 'package:belluga_now/domain/partners/value_objects/profile_type_flag_value.dart';
import 'package:belluga_now/domain/partners/value_objects/profile_type_visual_hex_color_value.dart';
import 'package:belluga_now/domain/partners/value_objects/profile_type_visual_icon_value.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/favorite_repository_contract.dart';
import 'package:belluga_now/domain/tenant/value_objects/icon_url_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/main_color_value.dart';
import 'package:belluga_now/domain/value_objects/asset_path_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
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

  test('favorites section resolves compact preview using cover then type visual',
      () async {
    final controller = FavoritesSectionController(
      favoriteRepository: _FakeFavoriteRepository(),
      appDataRepository: _FakeAppDataRepository(),
    );

    final coverResolved = controller.resolvedVisualFor(
      _favoriteResume(
        title: 'Com Cover',
        slug: 'com-cover',
        targetType: 'account_profile',
        profileType: 'artist',
        coverUrl: 'https://cdn.test/profile-cover.png',
      ),
    );

    expect(coverResolved, isNotNull);
    expect(coverResolved!.compactImageUrl, 'https://cdn.test/profile-cover.png');

    final typeVisualResolved = controller.resolvedVisualFor(
      _favoriteResume(
        title: 'Sem Imagem',
        slug: 'sem-imagem',
        targetType: 'account_profile',
        profileType: 'artist',
      ),
    );

    expect(typeVisualResolved, isNotNull);
    expect(typeVisualResolved!.compactImageUrl, isNull);
    expect(typeVisualResolved.typeVisual?.isIcon, isTrue);
  });

  test('favorites section derives halo state from snapshot-backed event state',
      () async {
    final controller = FavoritesSectionController(
      favoriteRepository: _FakeFavoriteRepository(),
      appDataRepository: _FakeAppDataRepository(),
    );

    expect(
      controller.haloStateFor(
        _favoriteResume(
          title: 'Ao Vivo',
          slug: 'ao-vivo',
          liveNowEventOccurrenceId: 'occ-live',
        ),
      ),
      FavoriteChipHaloState.liveNow,
    );

    expect(
      controller.haloStateFor(
        _favoriteResume(
          title: 'Próximo',
          slug: 'proximo',
          nextEventOccurrenceAt: DateTime(2026, 4, 4, 20),
        ),
      ),
      FavoriteChipHaloState.upcoming,
    );

    expect(
      controller.haloStateFor(
        _favoriteResume(
          title: 'Sem Evento',
          slug: 'sem-evento',
        ),
      ),
      FavoriteChipHaloState.none,
    );
  });
}

FavoriteResume _favoriteResume({
  required String title,
  required String? slug,
  String? targetType,
  String? profileType,
  String? coverUrl,
  DateTime? nextEventOccurrenceAt,
  String? liveNowEventOccurrenceId,
}) {
  ThumbUriValue? coverImageUriValue;
  if (coverUrl != null) {
    coverImageUriValue =
        ThumbUriValue(defaultValue: Uri.parse(coverUrl), isRequired: true)
          ..parse(coverUrl);
  }
  return favoriteResumeFromRaw(
    titleValue: TitleValue()..parse(title),
    slugValue: slug != null ? (SlugValue()..parse(slug)) : null,
    assetPathValue: AssetPathValue()
      ..parse('assets/images/placeholder_avatar.png'),
    targetType: targetType,
    profileType: profileType,
    coverImageUriValue: coverImageUriValue,
    nextEventOccurrenceAt: nextEventOccurrenceAt,
    liveNowEventOccurrenceId: liveNowEventOccurrenceId,
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

  @override
  ProfileTypeRegistry get profileTypeRegistry {
    final definitions = ProfileTypeDefinitions()
      ..add(
        ProfileTypeDefinition(
          typeValue: ProfileTypeKeyValue('artist'),
          labelValue: ProfileTypeLabelValue()..parse('Artist'),
          capabilities: ProfileTypeCapabilities(
            isFavoritableValue: _flag(true),
            isPoiEnabledValue: _flag(false),
            hasBioValue: _flag(true),
            hasContentValue: _flag(false),
            hasTaxonomiesValue: _flag(true),
            hasAvatarValue: _flag(true),
            hasCoverValue: _flag(true),
            hasEventsValue: _flag(true),
          ),
          visual: ProfileTypeVisual.icon(
            iconValue: ProfileTypeVisualIconValue()..parse('music_note'),
            colorValue: ProfileTypeVisualHexColorValue()..parse('#F44336'),
          ),
        ),
      );
    return ProfileTypeRegistry(types: definitions);
  }
}

class _FakeAppDataRepository extends AppDataRepositoryContract {
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

ProfileTypeFlagValue _flag(bool value) =>
    ProfileTypeFlagValue()..parse(value.toString());
