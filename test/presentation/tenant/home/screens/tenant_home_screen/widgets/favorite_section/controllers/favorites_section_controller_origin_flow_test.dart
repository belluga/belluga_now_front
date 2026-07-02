import 'dart:async';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/environment_name_value.dart';
import 'package:belluga_now/domain/favorite/favorite.dart';
import 'package:belluga_now/domain/favorite/paged_favorite_resumes_result.dart';
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
import 'package:belluga_now/infrastructure/repositories/favorite_repository_paging_mixin.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/favorite_section/controllers/favorites_section_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  test(
    'favorites section keeps backend ordering from /favorites payload',
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
      expect(items!.map((item) => item.title).toList(), [
        'Primeiro',
        'Segundo',
      ]);
      expect(favoriteRepository.fetchFavoriteResumesCallCount, 1);

      controller.onDispose();
    },
  );

  test('favorites section retries transient initial-load failures', () async {
    final favoriteRepository = _FakeFavoriteRepository(
      favoriteResumes: [_favoriteResume(title: 'Primeiro', slug: 'primeiro')],
      failuresBeforeSuccess: 1,
    );
    final controller = FavoritesSectionController(
      favoriteRepository: favoriteRepository,
      appDataRepository: _FakeAppDataRepository(),
    );

    await controller.init();

    expect(favoriteRepository.fetchFavoriteResumesCallCount, 2);
    expect(
      controller.favoritesStreamValue.value?.map((item) => item.title).toList(),
      ['Primeiro'],
    );

    controller.onDispose();
  });

  test(
    'favorites section publishes empty state after bounded initial retries',
    () async {
      final favoriteRepository = _FakeFavoriteRepository(
        failuresBeforeSuccess: 3,
      );
      final controller = FavoritesSectionController(
        favoriteRepository: favoriteRepository,
        appDataRepository: _FakeAppDataRepository(),
      );

      await controller.init();

      expect(favoriteRepository.fetchFavoriteResumesCallCount, 3);
      expect(controller.favoritesStreamValue.value, isEmpty);

      controller.onDispose();
    },
  );

  test(
    'favorites section keeps cache and refreshes ordering on re-entry',
    () async {
      final favoriteRepository = _FakeFavoriteRepository(
        favoriteResumes: [_favoriteResume(title: 'Primeiro', slug: 'primeiro')],
      );

      final controller = FavoritesSectionController(
        favoriteRepository: favoriteRepository,
        appDataRepository: _FakeAppDataRepository(),
      );

      await controller.init();
      expect(
        controller.favoritesStreamValue.value
            ?.map((item) => item.title)
            .toList(),
        ['Primeiro'],
      );

      favoriteRepository.favoriteResumes = [
        _favoriteResume(title: 'Segundo', slug: 'segundo'),
        _favoriteResume(title: 'Primeiro', slug: 'primeiro'),
      ];

      final refreshFuture = controller.init();
      expect(
        controller.favoritesStreamValue.value
            ?.map((item) => item.title)
            .toList(),
        ['Primeiro'],
      );
      await refreshFuture;

      expect(favoriteRepository.fetchFavoriteResumesCallCount, 2);
      expect(controller.favoritesStreamValue.value, isNotNull);
      expect(
        controller.favoritesStreamValue.value
            ?.map((item) => item.title)
            .toList(),
        ['Segundo', 'Primeiro'],
      );

      controller.onDispose();
    },
  );

  test(
    'favorites section loads only the first page on init and exposes has-more state',
    () async {
      final favoriteRepository = _FakeFavoriteRepository(
        pagedResultsByPage: {
          1: PagedFavoriteResumesResult(
            items: [
              _favoriteResume(title: 'Primeiro', slug: 'primeiro'),
              _favoriteResume(title: 'Segundo', slug: 'segundo'),
            ],
            hasMore: true,
          ),
          2: PagedFavoriteResumesResult(
            items: [_favoriteResume(title: 'Terceiro', slug: 'terceiro')],
            hasMore: false,
          ),
        },
      );

      final controller = FavoritesSectionController(
        favoriteRepository: favoriteRepository,
        appDataRepository: _FakeAppDataRepository(),
      );

      await controller.init();

      expect(
        controller.favoritesStreamValue.value
            ?.map((item) => item.title)
            .toList(),
        ['Primeiro', 'Segundo'],
      );
      expect(controller.hasMoreFavoritesStreamValue.value, isTrue);
      expect(controller.isPageLoadingStreamValue.value, isFalse);
      expect(favoriteRepository.requestedPageNumbers, [1]);

      controller.onDispose();
    },
  );

  test('favorites section appends the next page when requested', () async {
    final favoriteRepository = _FakeFavoriteRepository(
      pagedResultsByPage: {
        1: PagedFavoriteResumesResult(
          items: [
            _favoriteResume(title: 'Primeiro', slug: 'primeiro'),
            _favoriteResume(title: 'Segundo', slug: 'segundo'),
          ],
          hasMore: true,
        ),
        2: PagedFavoriteResumesResult(
          items: [_favoriteResume(title: 'Terceiro', slug: 'terceiro')],
          hasMore: false,
        ),
      },
    );

    final controller = FavoritesSectionController(
      favoriteRepository: favoriteRepository,
      appDataRepository: _FakeAppDataRepository(),
    );

    await controller.init();
    await controller.loadNextPage();

    expect(
      controller.favoritesStreamValue.value?.map((item) => item.title).toList(),
      ['Primeiro', 'Segundo', 'Terceiro'],
    );
    expect(controller.hasMoreFavoritesStreamValue.value, isFalse);
    expect(favoriteRepository.requestedPageNumbers, [1, 2]);

    controller.onDispose();
  });

  test(
    'favorites section preserves loaded pages when home re-enters and refreshes cached data',
    () async {
      final pagedResultsByPage = <int, PagedFavoriteResumesResult>{
        1: PagedFavoriteResumesResult(
          items: [
            _favoriteResume(title: 'Primeiro', slug: 'primeiro'),
            _favoriteResume(title: 'Segundo', slug: 'segundo'),
          ],
          hasMore: true,
        ),
        2: PagedFavoriteResumesResult(
          items: [_favoriteResume(title: 'Terceiro', slug: 'terceiro')],
          hasMore: false,
        ),
      };
      final favoriteRepository = _FakeFavoriteRepository(
        pagedResultsByPage: pagedResultsByPage,
      );
      final firstController = FavoritesSectionController(
        favoriteRepository: favoriteRepository,
        appDataRepository: _FakeAppDataRepository(),
      );

      await firstController.init();
      await firstController.loadNextPage();
      expect(
        firstController.favoritesStreamValue.value
            ?.map((item) => item.title)
            .toList(),
        ['Primeiro', 'Segundo', 'Terceiro'],
      );

      pagedResultsByPage[1] = PagedFavoriteResumesResult(
        items: [
          _favoriteResume(title: 'Primeiro Atualizado', slug: 'primeiro'),
          _favoriteResume(title: 'Segundo Atualizado', slug: 'segundo'),
        ],
        hasMore: true,
      );
      pagedResultsByPage[2] = PagedFavoriteResumesResult(
        items: [
          _favoriteResume(title: 'Terceiro Atualizado', slug: 'terceiro'),
        ],
        hasMore: false,
      );

      final secondController = FavoritesSectionController(
        favoriteRepository: favoriteRepository,
        appDataRepository: _FakeAppDataRepository(),
      );
      await secondController.init();

      expect(
        secondController.favoritesStreamValue.value
            ?.map((item) => item.title)
            .toList(),
        ['Primeiro Atualizado', 'Segundo Atualizado', 'Terceiro Atualizado'],
      );
      expect(secondController.hasMoreFavoritesStreamValue.value, isFalse);
      expect(favoriteRepository.requestedPageNumbers, [1, 2, 1, 2]);

      firstController.onDispose();
      secondController.onDispose();
    },
  );

  test(
    'favorites section does not request another page when has_more is false',
    () async {
      final favoriteRepository = _FakeFavoriteRepository(
        pagedResultsByPage: {
          1: PagedFavoriteResumesResult(
            items: [_favoriteResume(title: 'Primeiro', slug: 'primeiro')],
            hasMore: false,
          ),
        },
      );

      final controller = FavoritesSectionController(
        favoriteRepository: favoriteRepository,
        appDataRepository: _FakeAppDataRepository(),
      );

      await controller.init();
      await controller.loadNextPage();

      expect(favoriteRepository.requestedPageNumbers, [1]);

      controller.onDispose();
    },
  );

  test('favorites section deduplicates in-flight next page requests', () async {
    final pageTwoCompleter = Completer<PagedFavoriteResumesResult>();
    final favoriteRepository = _FakeFavoriteRepository(
      pagedResultsByPage: {
        1: PagedFavoriteResumesResult(
          items: [_favoriteResume(title: 'Primeiro', slug: 'primeiro')],
          hasMore: true,
        ),
      },
      pagedResultCompletersByPage: {2: pageTwoCompleter},
    );

    final controller = FavoritesSectionController(
      favoriteRepository: favoriteRepository,
      appDataRepository: _FakeAppDataRepository(),
    );

    await controller.init();

    final firstLoad = controller.loadNextPage();
    final secondLoad = controller.loadNextPage();

    expect(controller.isPageLoadingStreamValue.value, isTrue);
    expect(favoriteRepository.requestedPageNumbers, [1, 2]);
    expect(favoriteRepository.fetchFavoriteResumesPageCallCount, 2);

    pageTwoCompleter.complete(
      PagedFavoriteResumesResult(
        items: [_favoriteResume(title: 'Segundo', slug: 'segundo')],
        hasMore: false,
      ),
    );
    await Future.wait([firstLoad, secondLoad]);

    expect(controller.isPageLoadingStreamValue.value, isFalse);
    expect(
      controller.favoritesStreamValue.value?.map((item) => item.title).toList(),
      ['Primeiro', 'Segundo'],
    );

    controller.onDispose();
  });

  test(
    'favorites section keeps continuation state when a refresh fails after extra pages were loaded',
    () async {
      final favoriteRepository = _FakeFavoriteRepository(
        pagedResultsByPage: {
          1: PagedFavoriteResumesResult(
            items: [_favoriteResume(title: 'Primeiro', slug: 'primeiro')],
            hasMore: true,
          ),
          2: PagedFavoriteResumesResult(
            items: [_favoriteResume(title: 'Segundo', slug: 'segundo')],
            hasMore: true,
          ),
          3: PagedFavoriteResumesResult(
            items: [_favoriteResume(title: 'Terceiro', slug: 'terceiro')],
            hasMore: false,
          ),
        },
      );
      final controller = FavoritesSectionController(
        favoriteRepository: favoriteRepository,
        appDataRepository: _FakeAppDataRepository(),
      );

      await controller.init();
      await controller.loadNextPage();
      favoriteRepository.failuresBeforeSuccess = 3;

      await controller.init();

      expect(
        controller.favoritesStreamValue.value
            ?.map((item) => item.title)
            .toList(),
        ['Primeiro', 'Segundo'],
      );
      expect(controller.hasMoreFavoritesStreamValue.value, isTrue);

      await controller.loadNextPage();

      expect(
        controller.favoritesStreamValue.value
            ?.map((item) => item.title)
            .toList(),
        ['Primeiro', 'Segundo', 'Terceiro'],
      );
      expect(favoriteRepository.requestedPageNumbers, [1, 2, 1, 1, 1, 3]);

      controller.onDispose();
    },
  );

  test(
    'favorites section ignores stale next-page completions after a refresh starts',
    () async {
      final pageTwoCompleter = Completer<PagedFavoriteResumesResult>();
      final pagedResultsByPage = <int, PagedFavoriteResumesResult>{
        1: PagedFavoriteResumesResult(
          items: [_favoriteResume(title: 'Primeiro', slug: 'primeiro')],
          hasMore: true,
        ),
      };
      final favoriteRepository = _FakeFavoriteRepository(
        pagedResultsByPage: pagedResultsByPage,
        pagedResultCompletersByPage: {2: pageTwoCompleter},
      );
      final controller = FavoritesSectionController(
        favoriteRepository: favoriteRepository,
        appDataRepository: _FakeAppDataRepository(),
      );

      await controller.init();
      final staleNextPageLoad = controller.loadNextPage();

      pagedResultsByPage[1] = PagedFavoriteResumesResult(
        items: [_favoriteResume(title: 'Atualizado', slug: 'atualizado')],
        hasMore: false,
      );

      await controller.init();
      pageTwoCompleter.complete(
        PagedFavoriteResumesResult(
          items: [_favoriteResume(title: 'Stale', slug: 'stale')],
          hasMore: false,
        ),
      );
      await staleNextPageLoad;

      expect(
        controller.favoritesStreamValue.value
            ?.map((item) => item.title)
            .toList(),
        ['Atualizado'],
      );
      expect(controller.hasMoreFavoritesStreamValue.value, isFalse);
      expect(favoriteRepository.requestedPageNumbers, [1, 2, 1]);

      controller.onDispose();
    },
  );

  test(
    'favorites section resolves canonical event target when the backend exposes an active event path',
    () async {
      final controller = FavoritesSectionController(
        favoriteRepository: _FakeFavoriteRepository(),
        appDataRepository: _FakeAppDataRepository(),
      );

      final eventTarget = await controller.resolveNavigationTarget(
        _favoriteResume(
          title: 'Com Evento',
          slug: 'com-evento',
          targetType: 'account_profile',
          canOpenPublicDetail: true,
          publicDetailPath: '/parceiro/com-evento',
          eventTargetPath: '/agenda/evento/com-evento?occurrence=occ-live',
          liveNowEventOccurrenceId: 'occ-live',
        ),
      );

      expect(eventTarget, isA<FavoriteNavigationPath>());
      expect(
        (eventTarget as FavoriteNavigationPath).path,
        '/agenda/evento/com-evento?occurrence=occ-live',
      );
    },
  );

  test(
    'favorites section resolves canonical profile navigation when no active event target exists',
    () async {
      final controller = FavoritesSectionController(
        favoriteRepository: _FakeFavoriteRepository(),
        appDataRepository: _FakeAppDataRepository(),
      );

      final pathTarget = await controller.resolveNavigationTarget(
        _favoriteResume(
          title: 'Path Only',
          slug: null,
          targetType: 'account_profile',
          canOpenPublicDetail: true,
          publicDetailPath: '/parceiro/path-only',
        ),
      );

      expect(pathTarget, isA<FavoriteNavigationPath>());
      expect(
        (pathTarget as FavoriteNavigationPath).path,
        '/parceiro/path-only',
      );
    },
  );

  test(
    'favorites section falls back to canonical profile navigation when the occurrence state only carries a past upcoming timestamp',
    () async {
      final controller = FavoritesSectionController(
        favoriteRepository: _FakeFavoriteRepository(),
        appDataRepository: _FakeAppDataRepository(),
      );

      final pathTarget = await controller.resolveNavigationTarget(
        _favoriteResume(
          title: 'Yuri Dias',
          slug: 'yuri-dias',
          targetType: 'account_profile',
          canOpenPublicDetail: true,
          publicDetailPath: '/parceiro/yuri-dias',
          nextEventOccurrenceAt: DateTime.utc(2026, 6, 21, 16),
        ),
      );

      expect(pathTarget, isA<FavoriteNavigationPath>());
      expect(
        (pathTarget as FavoriteNavigationPath).path,
        '/parceiro/yuri-dias',
      );
    },
  );

  test(
    'favorites section fails closed when an event-eligible favorite is missing the canonical event target path',
    () async {
      final controller = FavoritesSectionController(
        favoriteRepository: _FakeFavoriteRepository(),
        appDataRepository: _FakeAppDataRepository(),
      );

      final unavailableTarget = await controller.resolveNavigationTarget(
        _favoriteResume(
          title: 'Evento Sem Rota Canonica',
          slug: 'evento-sem-rota-canonica',
          targetType: 'account_profile',
          canOpenPublicDetail: true,
          publicDetailPath: '/parceiro/evento-sem-rota-canonica',
          liveNowEventOccurrenceId: 'occ-live',
        ),
      );

      expect(unavailableTarget, isA<FavoriteNavigationUnavailable>());
    },
  );

  test(
    'favorites section publishes resolved navigation targets to the stream',
    () async {
      final controller = FavoritesSectionController(
        favoriteRepository: _FakeFavoriteRepository(),
        appDataRepository: _FakeAppDataRepository(),
      );

      await controller.requestNavigationTarget(
        _favoriteResume(
          title: 'Com Evento',
          slug: 'com-evento',
          targetType: 'account_profile',
          canOpenPublicDetail: true,
          publicDetailPath: '/parceiro/com-evento',
          eventTargetPath: '/agenda/evento/com-evento?occurrence=occ-live',
          liveNowEventOccurrenceId: 'occ-live',
        ),
      );

      final streamTarget = controller.navigationTargetStreamValue.value;
      expect(streamTarget, isA<FavoriteNavigationPath>());
      expect(
        (streamTarget as FavoriteNavigationPath).path,
        '/agenda/evento/com-evento?occurrence=occ-live',
      );

      controller.onDispose();
    },
  );

  test(
    'favorites section clears and overwrites navigation stream state',
    () async {
      final controller = FavoritesSectionController(
        favoriteRepository: _FakeFavoriteRepository(),
        appDataRepository: _FakeAppDataRepository(),
      );

      await controller.requestNavigationTarget(
        _favoriteResume(
          title: 'Primeiro',
          slug: 'primeiro',
          targetType: 'account_profile',
          canOpenPublicDetail: true,
          publicDetailPath: '/parceiro/primeiro',
        ),
      );
      expect(controller.navigationTargetStreamValue.value, isNotNull);

      controller.clearNavigationTarget();
      expect(controller.navigationTargetStreamValue.value, isNull);

      await controller.requestNavigationTarget(
        _favoriteResume(
          title: 'Segundo',
          slug: 'segundo',
          targetType: 'account_profile',
          canOpenPublicDetail: true,
          publicDetailPath: '/parceiro/segundo',
        ),
      );
      final secondTarget = controller.navigationTargetStreamValue.value;
      expect(secondTarget, isA<FavoriteNavigationPath>());
      expect(
        (secondTarget as FavoriteNavigationPath).path,
        '/parceiro/segundo',
      );

      await controller.requestNavigationTarget(
        _favoriteResume(
          title: 'Evento',
          slug: 'evento',
          targetType: 'account_profile',
          canOpenPublicDetail: true,
          publicDetailPath: '/parceiro/evento',
          eventTargetPath: '/agenda/evento/evento?occurrence=occ-2',
          liveNowEventOccurrenceId: 'occ-2',
        ),
      );
      final overwrittenTarget = controller.navigationTargetStreamValue.value;
      expect(overwrittenTarget, isA<FavoriteNavigationPath>());
      expect(
        (overwrittenTarget as FavoriteNavigationPath).path,
        '/agenda/evento/evento?occurrence=occ-2',
      );

      controller.onDispose();
    },
  );

  test(
    'favorites section blocks unavailable favorites instead of falling back to guessed search navigation',
    () async {
      final controller = FavoritesSectionController(
        favoriteRepository: _FakeFavoriteRepository(),
        appDataRepository: _FakeAppDataRepository(),
      );

      final unavailableTarget = await controller.resolveNavigationTarget(
        _favoriteResume(
          title: 'Sem rota',
          slug: 'sem-rota',
          targetType: 'account_profile',
          canOpenPublicDetail: false,
        ),
      );

      expect(unavailableTarget, isA<FavoriteNavigationUnavailable>());

      controller.onDispose();
    },
  );

  test(
    'favorites section resolves compact preview using cover then type visual',
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
      expect(
        coverResolved!.compactImageUrl,
        'https://cdn.test/profile-cover.png',
      );

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
    },
  );

  test(
    'favorites section derives halo state from occurrence-state event data',
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
          _favoriteResume(title: 'Sem Evento', slug: 'sem-evento'),
        ),
        FavoriteChipHaloState.none,
      );
    },
  );
}

FavoriteResume _favoriteResume({
  required String title,
  required String? slug,
  String? targetType,
  String? profileType,
  String? coverUrl,
  bool canOpenPublicDetail = false,
  String? publicDetailPath,
  String? eventTargetPath,
  DateTime? nextEventOccurrenceAt,
  String? liveNowEventOccurrenceId,
}) {
  ThumbUriValue? coverImageUriValue;
  if (coverUrl != null) {
    coverImageUriValue = ThumbUriValue(
      defaultValue: Uri.parse(coverUrl),
      isRequired: true,
    )..parse(coverUrl);
  }
  return favoriteResumeFromRaw(
    titleValue: TitleValue()..parse(title),
    slugValue: slug != null ? (SlugValue()..parse(slug)) : null,
    assetPathValue: AssetPathValue()
      ..parse('assets/images/placeholder_avatar.png'),
    targetType: targetType,
    profileType: profileType,
    coverImageUriValue: coverImageUriValue,
    canOpenPublicDetail: canOpenPublicDetail,
    publicDetailPath: publicDetailPath,
    eventTargetPath: eventTargetPath,
    nextEventOccurrenceAt: nextEventOccurrenceAt,
    liveNowEventOccurrenceId: liveNowEventOccurrenceId,
  );
}

class _FakeFavoriteRepository extends FavoriteRepositoryContract
    with FavoriteRepositoryPagingMixin {
  _FakeFavoriteRepository({
    this.favoriteResumes = const <FavoriteResume>[],
    this.pagedResultsByPage = const <int, PagedFavoriteResumesResult>{},
    this.pagedResultCompletersByPage =
        const <int, Completer<PagedFavoriteResumesResult>>{},
    this.failuresBeforeSuccess = 0,
  });

  List<FavoriteResume> favoriteResumes;
  final Map<int, PagedFavoriteResumesResult> pagedResultsByPage;
  final Map<int, Completer<PagedFavoriteResumesResult>>
  pagedResultCompletersByPage;
  int fetchFavoriteResumesCallCount = 0;
  int fetchFavoriteResumesPageCallCount = 0;
  int failuresBeforeSuccess;
  final List<int> requestedPageNumbers = <int>[];

  @override
  Future<List<Favorite>> fetchFavorites() async => <Favorite>[];

  @override
  Future<List<FavoriteResume>> fetchFavoriteResumes() async {
    fetchFavoriteResumesCallCount += 1;
    if (failuresBeforeSuccess > 0) {
      failuresBeforeSuccess -= 1;
      throw StateError('favorite resumes unavailable');
    }
    return favoriteResumes;
  }

  @override
  Future<PagedFavoriteResumesResult> fetchFavoriteResumesPage({
    required int page,
    required int pageSize,
  }) async {
    if (pagedResultsByPage.isEmpty && pagedResultCompletersByPage.isEmpty) {
      return super.fetchFavoriteResumesPage(page: page, pageSize: pageSize);
    }

    fetchFavoriteResumesPageCallCount += 1;
    requestedPageNumbers.add(page);

    if (failuresBeforeSuccess > 0) {
      failuresBeforeSuccess -= 1;
      throw StateError('favorite resumes unavailable');
    }

    final completer = pagedResultCompletersByPage[page];
    if (completer != null) {
      return completer.future;
    }

    return pagedResultsByPage[page] ??
        const PagedFavoriteResumesResult(
          items: <FavoriteResume>[],
          hasMore: false,
        );
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
            isPubliclyDiscoverableValue: _flag(true),
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
      themeModeStreamValue = StreamValue<ThemeMode?>(
        defaultValue: ThemeMode.light,
      ),
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
