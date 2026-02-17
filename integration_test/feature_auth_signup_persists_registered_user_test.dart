import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/local/app_data_local_info_source/app_data_local_info_source_stub.dart';
import 'package:belluga_now/infrastructure/dal/dao/production_backend/production_backend.dart';
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

  Future<void> _clearAuthStorage() async {
    await AuthRepository.storage.delete(key: userTokenKey);
    await AuthRepository.storage.delete(key: userIdKey);
    await AuthRepository.storage.delete(key: deviceIdKey);
  }

  Future<void> _resetGetIt() async {
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
    'Signup persists registered identity across restart',
    (tester) async {
      await _clearAuthStorage();
      await _resetGetIt();

      final backend = ProductionBackend();
      GetIt.I.registerSingleton<BackendContract>(backend);

      final appDataRepository = AppDataRepository(
        backendContract: backend,
        localInfoSource: AppDataLocalInfoSource(),
      );
      await appDataRepository.init();
      GetIt.I.registerSingleton<AppDataRepositoryContract>(
        appDataRepository,
      );
      backend.setContext(
        BackendContext.fromAppData(appDataRepository.appData),
      );

      final authRepository = AuthRepository();
      await authRepository.init();
      GetIt.I.registerSingleton<AuthRepositoryContract>(authRepository);

      final preSignupUserId = await authRepository.getUserId();
      if (preSignupUserId != null) {
        expect(preSignupUserId, isNotEmpty);
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final email = 'signup-regression-$now@belluga.test';
      const password = 'SecurePass!123';

      await authRepository.signUpWithEmailPassword(
        'Regression Tester',
        email,
        password,
      );

      final registeredUser = authRepository.userStreamValue.value;
      expect(registeredUser, isNotNull);

      final storedUserId = await authRepository.getUserId();
      expect(storedUserId, isNotNull);
      expect(registeredUser!.uuidValue.value, storedUserId);

      final restartedAuthRepository = AuthRepository();
      await restartedAuthRepository.init();

      final restartedUser = restartedAuthRepository.userStreamValue.value;
      expect(restartedUser, isNotNull);
      expect(restartedUser!.uuidValue.value, storedUserId);
    },
  );
}
