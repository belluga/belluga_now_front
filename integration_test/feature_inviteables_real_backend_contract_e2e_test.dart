import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/invites_backend/laravel_invites_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/production_backend/production_backend.dart';
import 'package:belluga_now/infrastructure/platform/app_data_local_info_source/app_data_local_info_source.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:belluga_now/infrastructure/repositories/auth_repository.dart';
import 'package:belluga_now/infrastructure/repositories/inviteables_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';

import 'support/integration_test_bootstrap.dart';
import 'support/tenant_scope_guard.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  IntegrationTestBootstrap.ensureNonProductionLandlordDomain();

  const expectedTenantMainDomain = String.fromEnvironment(
    'E2E_EXPECTED_TENANT_MAIN_DOMAIN',
    defaultValue: '',
  );

  testWidgets(
    'inviteables repository hits real tenant backend with bounded pagination',
    (_) async {
      await GetIt.I.reset();

      final backend = ProductionBackend();
      GetIt.I.registerSingleton<BackendContract>(backend);

      final appDataRepository = AppDataRepository(
        backendContract: backend,
        localInfoSource: AppDataLocalInfoSource(),
      );
      await appDataRepository.init();
      if (expectedTenantMainDomain.trim().isNotEmpty) {
        TenantScopeGuard.assertTenantScope(
          appDataRepository.appData,
          testName: 'inviteables-real-backend-contract',
        );
      }
      GetIt.I.registerSingleton<AppDataRepositoryContract>(appDataRepository);
      backend.setContext(
        BackendContext.fromAppData(appDataRepository.appData),
      );

      final authRepository = AuthRepository();
      await authRepository.init();
      GetIt.I.registerSingleton<AuthRepositoryContract>(authRepository);
      expect(
        authRepository.userToken.trim(),
        isNotEmpty,
        reason: 'Real inviteables backend evidence requires an auth token.',
      );

      final requestedUris = <Uri>[];
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requestedUris.add(options.uri);
              handler.next(options);
            },
          ),
        );
      final repository = InviteablesRepository(
        backend: LaravelInvitesBackend(dio: dio),
      );

      final recipients = await repository.fetchInviteableRecipients();

      final inviteablesUris = requestedUris
          .where((uri) => uri.path == '/api/v1/contacts/inviteables')
          .toList(growable: false);
      expect(inviteablesUris, hasLength(1));
      expect(inviteablesUris.single.queryParameters['page'], '1');
      expect(
        inviteablesUris.single.queryParameters['page_size'],
        InviteablesRepository.routeCriticalPageSize.toString(),
      );
      expect(
        repository.inviteableRecipientsStreamValue.value,
        same(recipients),
      );
      debugPrint(
        'INVITEABLES_REAL_BACKEND_E2E '
        'domain=${appDataRepository.appData.mainDomainValue.value.host} '
        'path=${inviteablesUris.single.path} '
        'query=${inviteablesUris.single.query} '
        'recipients=${recipients.length}',
      );
    },
  );
}
