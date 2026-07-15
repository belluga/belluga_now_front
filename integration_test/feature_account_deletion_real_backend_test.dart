import 'package:belluga_now/domain/auth/account_deletion_journey_state.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/auth_repository_contract_values.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/production_backend/production_backend.dart';
import 'package:belluga_now/infrastructure/platform/app_data_local_info_source/app_data_local_info_source.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:belluga_now/infrastructure/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';

import 'support/integration_test_bootstrap.dart';

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
    'real backend endpoint proof: registered current user deletion returns a confirmed terminal client outcome',
    (_) async {
      await clearAuthStorage();
      await resetGetIt();
      addTearDown(clearAuthStorage);
      addTearDown(resetGetIt);

      final backend = ProductionBackend();
      GetIt.I.registerSingleton<BackendContract>(backend);
      final appDataRepository = AppDataRepository(
        backendContract: backend,
        localInfoSource: AppDataLocalInfoSource(),
      );
      await appDataRepository.init();
      GetIt.I.registerSingleton<AppDataRepositoryContract>(appDataRepository);
      backend.setContext(BackendContext.fromAppData(appDataRepository.appData));

      final authRepository = AuthRepository();
      GetIt.I.registerSingleton<AuthRepositoryContract>(authRepository);
      await authRepository.init();

      final suffix = DateTime.now().microsecondsSinceEpoch;
      await authRepository.signUpWithEmailPassword(
        authRepoString('Deletion Regression $suffix'),
        authRepoString('delete-regression-$suffix@belluga.test'),
        authRepoString('SecurePass!123'),
      );
      expect(authRepository.userStreamValue.value, isNotNull);
      expect(authRepository.userToken.trim(), isNotEmpty);

      final outcome = await authRepository.deleteCurrentAccount();
      await authRepository.ensureTenantPublicIdentityReady();

      expect(outcome, AccountDeletionDispatchOutcome.confirmed);
      expect(
        authRepository.accountDeletionJourneyState.phase,
        AccountDeletionJourneyPhase.confirmed,
      );
      expect(authRepository.userStreamValue.value, isNull);
      expect(authRepository.userToken, isEmpty);
      expect(await AuthRepository.storage.read(key: userTokenKey), isNull);
    },
  );
}
