import 'dart:developer' as developer;

import 'package:belluga_now/domain/app_data/environment_type.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/app_data_backend/app_data_backend_stub.dart';
import 'package:belluga_now/infrastructure/dal/dao/local/app_data_local_info_source/app_data_local_info_source_stub.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  developer.postEvent(
    'integration_test.VmServiceProxyGoldenFileComparator',
    const {},
  );
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Tenant bootstrap resolves tenant environment and domains',
    (tester) async {
      if (GetIt.I.isRegistered<AppDataRepository>()) {
        GetIt.I.unregister<AppDataRepository>();
      }
      final repository = AppDataRepository(
        backend: AppDataBackend(),
        localInfoSource: AppDataLocalInfoSource(),
      );
      GetIt.I.registerSingleton<AppDataRepository>(repository);

      await repository.init();

      final appData = repository.appData;
      expect(
        appData.typeValue.value,
        EnvironmentType.tenant,
        reason:
            'Tenant builds must not bootstrap as landlord environments.',
      );
      expect(
        appData.domains.isNotEmpty,
        true,
        reason:
            'Tenant builds must receive at least one tenant domain.',
      );

      final appDomains = appData.appDomains;
      if (appDomains != null && appDomains.isNotEmpty) {
        final packageInfo = await PackageInfo.fromPlatform();
        final appDomainValues = appDomains.map((value) => value.value);
        expect(
          appDomainValues.contains(packageInfo.packageName),
          true,
          reason:
              'Environment app_domains should include the current packageName.',
        );
      }
    },
  );
}
