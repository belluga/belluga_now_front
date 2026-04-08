import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_tenants_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_selected_tenant_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/landlord_auth_repository_contract_values.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/infrastructure/repositories/landlord_auth_repository.dart';
import 'package:belluga_now/infrastructure/repositories/landlord_tenants_repository.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_events_repository.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_selected_tenant_repository.dart';
import 'package:belluga_now/presentation/tenant_admin/events/controllers/tenant_admin_events_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/events/screens/tenant_admin_events_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';

import 'support/integration_test_bootstrap.dart';

const adminEmailDefine = String.fromEnvironment(
  'LANDLORD_ADMIN_EMAIL',
  defaultValue: 'admin@bellugasolutions.com.br',
);
const adminPasswordDefine = String.fromEnvironment(
  'LANDLORD_ADMIN_PASSWORD',
  defaultValue: '765432e1',
);
const tenantDomainDefine = String.fromEnvironment(
  'TENANT_ADMIN_TEST_DOMAIN',
  defaultValue: 'guarappari.belluga.space',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  IntegrationTestBootstrap.ensureNonProductionLandlordDomain();

  testWidgets(
    'tenant admin archived events repository query contract works against real backend',
    (_) async {
      final harness = await _createHarness();

      try {
        final page = await harness.eventsRepository.fetchEventsPage(
          page: TenantAdminEventsRepoInt.fromRaw(1, defaultValue: 1),
          pageSize: TenantAdminEventsRepoInt.fromRaw(50, defaultValue: 50),
          archived: TenantAdminEventsRepoBool.fromRaw(true, defaultValue: true),
        );

        expect(page, isA<TenantAdminPagedResult>());
        expect(page.items, isNotEmpty);
        expect(
          page.items.any((event) => event.deletedAt != null),
          isTrue,
        );
      } finally {
        await harness.dispose();
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );

  testWidgets(
    'tenant admin archived events filter opens without error banner',
    (tester) async {
      final harness = await _createHarness();

      try {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: TenantAdminEventsScreen(),
            ),
          ),
        );

        await _pumpFor(tester, const Duration(seconds: 2));
        await _waitForFinder(tester, find.text('Ativos'));

        await tester.tap(find.text('Ativos').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Arquivados').last);
        await tester.pumpAndSettle();

        await _waitUntil(
          tester,
          () =>
              harness.controller.isEventsPageLoadingStreamValue.value ==
                  false &&
              harness.controller.eventsStreamValue.value != null,
        );

        final frameworkException = tester.takeException();
        if (frameworkException != null) {
          throw TestFailure(
              'Unexpected framework exception: $frameworkException');
        }

        final eventsError = harness.controller.eventsErrorStreamValue.value;
        if (eventsError != null && eventsError.trim().isNotEmpty) {
          throw TestFailure('Archived events error: $eventsError');
        }

        expect(find.text('Unable to load events.'), findsNothing);
        expect(
          harness.controller.eventsStreamValue.value,
          isNotNull,
        );
        expect(
          harness.controller.eventsStreamValue.value!,
          isNotEmpty,
        );
      } finally {
        await harness.dispose();
      }
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );
}

class _RealAdminEventsHarness {
  _RealAdminEventsHarness({
    required this.authRepository,
    required this.tenantsRepository,
    required this.tenantScopeRepository,
    required this.eventsRepository,
    required this.controller,
  });

  final LandlordAuthRepository authRepository;
  final LandlordTenantsRepository tenantsRepository;
  final TenantAdminSelectedTenantRepository tenantScopeRepository;
  final TenantAdminEventsRepository eventsRepository;
  final TenantAdminEventsController controller;

  Future<void> dispose() async {
    await GetIt.I.reset(dispose: true);
  }
}

Future<_RealAdminEventsHarness> _createHarness() async {
  await GetIt.I.reset(dispose: true);

  final adminEmail = _requireDefine('LANDLORD_ADMIN_EMAIL', adminEmailDefine);
  final adminPassword =
      _requireDefine('LANDLORD_ADMIN_PASSWORD', adminPasswordDefine);
  final expectedTenantHost = _normalizeHost(tenantDomainDefine);
  final landlordOrigin =
      _deriveLandlordOriginFromTenantHost(expectedTenantHost);

  final authRepository = LandlordAuthRepository(
    dio: Dio(
      BaseOptions(
        baseUrl: '$landlordOrigin/admin/api',
      ),
    ),
  );
  final tenantScopeRepository = TenantAdminSelectedTenantRepository();
  final tenantsRepository = LandlordTenantsRepository(
    landlordAuthRepository: authRepository,
    landlordOriginOverride: landlordOrigin,
  );
  final eventsRepository = TenantAdminEventsRepository(
    tenantScope: tenantScopeRepository,
  );
  final taxonomiesRepository = _NoopTaxonomiesRepository();
  final controller = TenantAdminEventsController(
    eventsRepository: eventsRepository,
    taxonomiesRepository: taxonomiesRepository,
    tenantScope: tenantScopeRepository,
    landlordAuthRepository: authRepository,
  );

  GetIt.I.registerSingleton<LandlordAuthRepositoryContract>(authRepository);
  GetIt.I.registerSingleton<LandlordTenantsRepositoryContract>(
    tenantsRepository,
  );
  GetIt.I.registerSingleton<TenantAdminSelectedTenantRepositoryContract>(
    tenantScopeRepository,
  );
  GetIt.I.registerSingleton<TenantAdminTenantScopeContract>(
    tenantScopeRepository,
  );
  GetIt.I.registerSingleton<TenantAdminEventsRepositoryContract>(
    eventsRepository,
  );
  GetIt.I.registerSingleton<TenantAdminTaxonomiesRepositoryContract>(
    taxonomiesRepository,
  );
  GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

  await authRepository.init();
  await authRepository.loginWithEmailPassword(
    landlordAuthRepoString(adminEmail),
    landlordAuthRepoString(adminPassword),
  );
  expect(authRepository.hasValidSession, isTrue);

  final tenants = await tenantsRepository.fetchTenants();
  expect(tenants, isNotEmpty);

  final tenantOption = _resolveTenantByDomain(tenants, expectedTenantHost);
  tenantScopeRepository.setAvailableTenants(tenants);
  tenantScopeRepository.selectTenant(tenantOption);

  return _RealAdminEventsHarness(
    authRepository: authRepository,
    tenantsRepository: tenantsRepository,
    tenantScopeRepository: tenantScopeRepository,
    eventsRepository: eventsRepository,
    controller: controller,
  );
}

Future<void> _pumpFor(
  WidgetTester tester,
  Duration duration,
) async {
  final end = DateTime.now().add(duration);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _waitForFinder(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
  Duration step = const Duration(milliseconds: 200),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  throw TestFailure(
    'Timed out waiting for ${finder.describeMatch(Plurality.one)}.',
  );
}

Future<void> _waitUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 30),
  Duration step = const Duration(milliseconds: 200),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(step);
    if (condition()) {
      return;
    }
  }

  throw TestFailure('Timed out waiting for asynchronous condition.');
}

String _requireDefine(String key, String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    fail('Missing --dart-define=$key for integration test execution.');
  }
  return normalized;
}

String _normalizeHost(String raw) {
  final trimmed = raw.trim();
  final uri = Uri.tryParse(
    trimmed.contains('://') ? trimmed : 'https://$trimmed',
  );
  if (uri == null || uri.host.trim().isEmpty) {
    fail('Invalid tenant host value: "$raw"');
  }
  return uri.host.trim().toLowerCase();
}

String _deriveLandlordOriginFromTenantHost(String tenantHost) {
  final labels = tenantHost.trim().toLowerCase().split('.');
  if (labels.length < 2) {
    fail('Invalid tenant host for landlord derivation: "$tenantHost"');
  }
  final landlordHost =
      labels.length >= 3 ? labels.sublist(1).join('.') : labels.join('.');
  return 'https://$landlordHost';
}

LandlordTenantOption _resolveTenantByDomain(
  List<LandlordTenantOption> tenants,
  String expectedHost,
) {
  for (final tenant in tenants) {
    if (_normalizeHost(tenant.mainDomain) == expectedHost) {
      return tenant;
    }
  }
  fail(
    'Tenant "$expectedHost" not found in landlord listing. '
    'Available: ${tenants.map((tenant) => tenant.mainDomain).join(', ')}',
  );
}

class _NoopTaxonomiesRepository
    with TenantAdminTaxonomiesPaginationMixin
    implements TenantAdminTaxonomiesRepositoryContract {
  @override
  Future<TenantAdminTaxonomyDefinition> createTaxonomy({
    required TenantAdminTaxRepoString slug,
    required TenantAdminTaxRepoString name,
    required List<TenantAdminTaxRepoString> appliesTo,
    TenantAdminTaxRepoString? icon,
    TenantAdminTaxRepoString? color,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> createTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString slug,
    required TenantAdminTaxRepoString name,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTaxonomy(TenantAdminTaxRepoString taxonomyId) async {}

  @override
  Future<void> deleteTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString termId,
  }) async {}

  @override
  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomies() async {
    return <TenantAdminTaxonomyDefinition>[];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyDefinition>>
      fetchTaxonomiesPage({
    required TenantAdminTaxRepoInt page,
    required TenantAdminTaxRepoInt pageSize,
  }) async {
    return tenantAdminPagedResultFromRaw(
      items: <TenantAdminTaxonomyDefinition>[],
      hasMore: false,
    );
  }

  @override
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required TenantAdminTaxRepoString taxonomyId,
  }) async {
    return <TenantAdminTaxonomyTermDefinition>[];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyTermDefinition>>
      fetchTermsPage({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoInt page,
    required TenantAdminTaxRepoInt pageSize,
  }) async {
    return tenantAdminPagedResultFromRaw(
      items: <TenantAdminTaxonomyTermDefinition>[],
      hasMore: false,
    );
  }

  @override
  Future<TenantAdminTaxonomyDefinition> updateTaxonomy({
    required TenantAdminTaxRepoString taxonomyId,
    TenantAdminTaxRepoString? slug,
    TenantAdminTaxRepoString? name,
    List<TenantAdminTaxRepoString>? appliesTo,
    TenantAdminTaxRepoString? icon,
    TenantAdminTaxRepoString? color,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> updateTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString termId,
    TenantAdminTaxRepoString? slug,
    TenantAdminTaxRepoString? name,
  }) async {
    throw UnimplementedError();
  }
}
