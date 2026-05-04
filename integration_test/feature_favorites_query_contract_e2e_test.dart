import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/platform/app_data_local_info_source/app_data_local_info_source.dart';
import 'package:belluga_now/infrastructure/dal/dao/production_backend/production_backend.dart';
import 'package:belluga_now/infrastructure/dal/dto/favorite/favorite_preview_dto.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:belluga_now/infrastructure/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';

import 'support/integration_test_bootstrap.dart';
import 'support/tenant_scope_guard.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  IntegrationTestBootstrap.ensureNonProductionLandlordDomain();

  const userTokenKey = 'user_token';
  const userIdKey = 'user_id';
  const deviceIdKey = 'device_id';

  Future<void> clearAuthStorage() async {
    await AuthRepository.storage.delete(key: userTokenKey);
    await AuthRepository.storage.delete(key: userIdKey);
    await AuthRepository.storage.delete(key: deviceIdKey);
  }

  Future<void> resetGetIt() async {
    final getIt = GetIt.I;
    if (getIt.isRegistered<AuthRepositoryContract>()) {
      getIt.unregister<AuthRepositoryContract>();
    }
    if (getIt.isRegistered<AppDataRepositoryContract>()) {
      getIt.unregister<AppDataRepositoryContract>();
    }
    if (getIt.isRegistered<BackendContract>()) {
      getIt.unregister<BackendContract>();
    }
  }

  testWidgets(
      'Anonymous favorites toggle and readback work against real backend', (
    _,
  ) async {
    await clearAuthStorage();
    await resetGetIt();

    final backend = ProductionBackend();
    GetIt.I.registerSingleton<BackendContract>(backend);

    final appDataRepository = AppDataRepository(
      backendContract: backend,
      localInfoSource: AppDataLocalInfoSource(),
    );
    await appDataRepository.init();
    TenantScopeGuard.assertTenantScope(
      appDataRepository.appData,
      testName: 'favorites-query-contract',
    );
    GetIt.I.registerSingleton<AppDataRepositoryContract>(appDataRepository);
    backend.setContext(
      BackendContext.fromAppData(appDataRepository.appData),
    );

    final authRepository = AuthRepository();
    GetIt.I.registerSingleton<AuthRepositoryContract>(authRepository);
    await authRepository.init();
    expect(
      authRepository.userToken.trim(),
      isNotEmpty,
      reason: 'Anonymous identity bootstrap must issue a bearer token.',
    );
    expect(
      (await authRepository.getUserId())?.trim(),
      isNotEmpty,
      reason: 'Anonymous identity bootstrap must persist a user id.',
    );

    final accountProfiles =
        await backend.accountProfiles.fetchAccountProfilesPage(
      page: 1,
      pageSize: 10,
    );
    final targetProfiles = accountProfiles.profiles
        .where((profile) => profile.id.trim().isNotEmpty)
        .toList(growable: false);
    expect(
      targetProfiles,
      isNotEmpty,
      reason:
          'Favorites e2e requires at least one public account profile to toggle.',
    );

    final target = targetProfiles.first;
    final targetId = target.id.trim();

    await backend.favorites.favoriteAccountProfile(targetId);
    List<FavoritePreviewDTO> favorites;
    try {
      favorites = await waitForFavoriteState(
        backend,
        targetId,
        shouldExist: true,
      );
    } finally {
      await backend.favorites.unfavoriteAccountProfile(targetId);
    }

    expect(favorites, isA<List<FavoritePreviewDTO>>());
    expect(
      favorites.any((item) => isFavoriteTarget(item, targetId)),
      isTrue,
      reason: 'Favorited account profile must appear in GET /favorites.',
    );

    for (final item in favorites) {
      expect(item.id.trim(), isNotEmpty);
      expect(item.title.trim(), isNotEmpty);
      expect(item.registryKey?.trim(), isNotEmpty);
      expect(item.targetType?.trim(), isNotEmpty);
      expect(item.targetId?.trim(), isNotEmpty);
    }

    assertFavoritesOrdering(favorites);

    final afterUnfavorite = await waitForFavoriteState(
      backend,
      targetId,
      shouldExist: false,
    );
    expect(
      afterUnfavorite.any((item) => isFavoriteTarget(item, targetId)),
      isFalse,
      reason: 'Unfavorited account profile must disappear from GET /favorites.',
    );
  });
}

Future<List<FavoritePreviewDTO>> waitForFavoriteState(
  BackendContract backend,
  String targetId, {
  required bool shouldExist,
  Duration timeout = const Duration(seconds: 20),
  Duration step = const Duration(seconds: 1),
}) async {
  final deadline = DateTime.now().add(timeout);
  var latest = <FavoritePreviewDTO>[];

  while (DateTime.now().isBefore(deadline)) {
    latest = await backend.favorites.fetchFavorites();
    final containsTarget =
        latest.any((item) => isFavoriteTarget(item, targetId));
    if (containsTarget == shouldExist) {
      return latest;
    }
    await Future<void>.delayed(step);
  }

  throw TestFailure(
    'Timed out waiting for favorite target $targetId to '
    '${shouldExist ? 'appear' : 'disappear'}. Latest ids: '
    '${latest.map((item) => item.targetId ?? item.id).join(', ')}',
  );
}

bool isFavoriteTarget(FavoritePreviewDTO item, String targetId) {
  final normalized = targetId.trim();
  return item.targetId?.trim() == normalized || item.id.trim() == normalized;
}

void assertFavoritesOrdering(List<FavoritePreviewDTO> items) {
  if (items.length < 2) {
    return;
  }

  for (var index = 1; index < items.length; index++) {
    final previous = items[index - 1];
    final current = items[index];

    final previousBucket = sortBucket(previous);
    final currentBucket = sortBucket(current);

    expect(
      previousBucket <= currentBucket,
      isTrue,
      reason: 'Invalid bucket ordering at index $index '
          '(previous=$previousBucket current=$currentBucket).',
    );

    if (previousBucket != currentBucket) {
      continue;
    }

    if (previousBucket == 0) {
      final previousAt = previous.nextEventOccurrenceAt!;
      final currentAt = current.nextEventOccurrenceAt!;
      expect(
        !previousAt.isAfter(currentAt),
        isTrue,
        reason: 'next_event_occurrence_at must be ascending inside bucket 0 at '
            'index $index.',
      );
      continue;
    }

    if (previousBucket == 1) {
      final previousAt = previous.lastEventOccurrenceAt!;
      final currentAt = current.lastEventOccurrenceAt!;
      expect(
        !previousAt.isBefore(currentAt),
        isTrue,
        reason:
            'last_event_occurrence_at must be descending inside bucket 1 at '
            'index $index.',
      );
      continue;
    }

    final previousAt = previous.favoritedAt;
    final currentAt = current.favoritedAt;
    if (previousAt != null && currentAt != null) {
      expect(
        !previousAt.isBefore(currentAt),
        isTrue,
        reason:
            'favorited_at must be descending inside bucket 2 at index $index.',
      );
    }
  }
}

int sortBucket(FavoritePreviewDTO item) {
  if (item.nextEventOccurrenceAt != null) {
    return 0;
  }
  if (item.lastEventOccurrenceAt != null) {
    return 1;
  }
  return 2;
}
