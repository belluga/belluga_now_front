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

  const seededEmail =
      String.fromEnvironment('FAVORITES_E2E_EMAIL', defaultValue: '');
  const seededPassword =
      String.fromEnvironment('FAVORITES_E2E_PASSWORD', defaultValue: '');
  const expectNonEmpty = bool.fromEnvironment(
    'FAVORITES_E2E_EXPECT_NON_EMPTY',
    defaultValue: false,
  );

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

  testWidgets('Favorites query contract works against real backend', (
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
    await authRepository.init();
    GetIt.I.registerSingleton<AuthRepositoryContract>(authRepository);

    if (seededEmail.trim().isNotEmpty && seededPassword.trim().isNotEmpty) {
      await authRepository.loginWithEmailPassword(
        seededEmail.trim(),
        seededPassword.trim(),
      );
    } else {
      final now = DateTime.now().millisecondsSinceEpoch;
      final email = 'favorites-e2e-$now@belluga.test';
      const password = 'SecurePass!123';
      await authRepository.signUpWithEmailPassword(
        'Favorites E2E Tester',
        email,
        password,
      );
    }

    final favorites = await backend.favorites.fetchFavorites();
    expect(favorites, isA<List<FavoritePreviewDTO>>());

    for (final item in favorites) {
      expect(item.id.trim(), isNotEmpty);
      expect(item.title.trim(), isNotEmpty);
      expect(item.registryKey?.trim(), isNotEmpty);
      expect(item.targetType?.trim(), isNotEmpty);
      expect(item.targetId?.trim(), isNotEmpty);
    }

    if (expectNonEmpty) {
      expect(
        favorites,
        isNotEmpty,
        reason:
            'Set FAVORITES_E2E_EMAIL/FAVORITES_E2E_PASSWORD for a seeded user.',
      );
      assertFavoritesOrdering(favorites);
    }
  });
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
