import 'dart:developer' as developer;

import 'package:belluga_now/domain/app_data/environment_type.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/app_data_backend/app_data_backend_stub.dart';
import 'package:belluga_now/infrastructure/dal/dao/local/app_data_local_info_source/app_data_local_info_source_stub.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'support/integration_test_bootstrap.dart';

void main() {
  developer.postEvent(
    'integration_test.VmServiceProxyGoldenFileComparator',
    const {},
  );
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  IntegrationTestBootstrap.ensureNonProductionLandlordDomain();

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
      final appDomains = appData.appDomains;
      if (appDomains != null && appDomains.isNotEmpty) {
        final packageInfo = await PackageInfo.fromPlatform();
        final appDomainValues = appDomains.map((value) => value.value);
        expect(appDomainValues, isNotEmpty);
        if (!appDomainValues.contains(packageInfo.packageName)) {
          developer.log(
            'Environment app_domains does not include current packageName '
            '(${packageInfo.packageName}); configured values: '
            '${appDomainValues.join(', ')}',
            name: 'integration_test',
          );
        }
      }
    },
  );
}
