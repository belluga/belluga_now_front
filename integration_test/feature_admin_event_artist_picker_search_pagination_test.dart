import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_meta.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_tenants_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/landlord_auth_repository_contract_values.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_onboarding_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/infrastructure/repositories/landlord_auth_repository.dart';
import 'package:belluga_now/infrastructure/repositories/landlord_tenants_repository.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_accounts_repository.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_events_repository.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_selected_tenant_repository.dart';
import 'package:belluga_now/presentation/tenant_admin/events/controllers/tenant_admin_events_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/events/screens/tenant_admin_event_form_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';

import 'support/integration_test_bootstrap.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  IntegrationTestBootstrap.ensureNonProductionLandlordDomain();

  const adminEmailDefine = String.fromEnvironment(
    'LANDLORD_ADMIN_EMAIL',
    defaultValue: '',
  );
  const adminPasswordDefine = String.fromEnvironment(
    'LANDLORD_ADMIN_PASSWORD',
    defaultValue: '',
  );
  const tenantDomainDefine = String.fromEnvironment(
    'TENANT_ADMIN_TEST_DOMAIN',
    defaultValue: 'guarappari.belluga.space',
  );

  testWidgets(
    'tenant admin event related-profile picker searches beyond legacy snapshot and appends next pages from backend',
    (tester) async {
      await GetIt.I.reset(dispose: true);

      final adminEmail =
          _requireDefine('LANDLORD_ADMIN_EMAIL', adminEmailDefine);
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
      final accountsRepository = TenantAdminAccountsRepository(
        tenantScope: tenantScopeRepository,
      );
      final eventsRepository = TenantAdminEventsRepository(
        tenantScope: tenantScopeRepository,
      );
      final controller = TenantAdminEventsController(
        eventsRepository: eventsRepository,
        taxonomiesRepository: _NoopTaxonomiesRepository(),
      );

      GetIt.I.registerSingleton<LandlordAuthRepositoryContract>(authRepository);
      GetIt.I.registerSingleton<TenantAdminEventsController>(controller);

      final createdAccountSlugs = <String>[];
      String? createdEventTypeId;

      try {
        await authRepository.init();
        await authRepository.loginWithEmailPassword(
          landlordAuthRepoString(adminEmail),
          landlordAuthRepoString(adminPassword),
        );
        expect(authRepository.hasValidSession, isTrue);

        final tenants = await tenantsRepository.fetchTenants();
        expect(tenants, isNotEmpty);

        final tenantOption =
            _resolveTenantByDomain(tenants, expectedTenantHost);
        tenantScopeRepository.setAvailableTenants(tenants);
        tenantScopeRepository.selectTenant(tenantOption);

        final seed = DateTime.now().microsecondsSinceEpoch.toString();
        final legacyPrefix = 'Legacy Artist $seed';
        final searchPrefix = 'Zulu Artist $seed';
        final createdEventType = await eventsRepository.createEventType(
          name: TenantAdminEventsRepoString.fromRaw(
            'Artist Picker IT $seed',
            isRequired: true,
          ),
          slug: TenantAdminEventsRepoString.fromRaw(
            'artist-picker-it-$seed',
            isRequired: true,
          ),
        );
        createdEventTypeId = createdEventType.id;

        createdAccountSlugs.addAll(
          await _seedArtists(
            accountsRepository: accountsRepository,
            displayNamePrefix: legacyPrefix,
            count: 100,
          ),
        );
        createdAccountSlugs.addAll(
          await _seedArtists(
            accountsRepository: accountsRepository,
            displayNamePrefix: searchPrefix,
            count: 25,
          ),
        );

        await _pumpWithAutoRoute(
          tester,
          const Scaffold(
            body: TenantAdminEventFormScreen(),
          ),
        );

        await _waitForFinder(
          tester,
          find.byType(Scrollable),
          timeout: const Duration(seconds: 60),
        );
        await tester.scrollUntilVisible(
          find.widgetWithText(OutlinedButton, 'Adicionar perfil'),
          280,
          scrollable: find.byType(Scrollable).first,
        );
        await _pumpFor(tester, const Duration(seconds: 1));

        await tester
            .tap(find.widgetWithText(OutlinedButton, 'Adicionar perfil'));
        await _pumpFor(tester, const Duration(seconds: 1));
        await _waitForFinder(
          tester,
          find.widgetWithText(TextField, 'Buscar perfil relacionado'),
        );

        final searchInput = '$searchPrefix ';
        final pageOneArtist = '$searchPrefix 001';
        final pageTwoArtist = '$searchPrefix 025';

        await tester.enterText(
          find.widgetWithText(TextField, 'Buscar perfil relacionado'),
          searchInput,
        );
        await tester.pump(const Duration(milliseconds: 400));
        await _waitForFinder(tester, find.text(pageOneArtist));

        expect(find.text(pageTwoArtist), findsNothing);

        await _scrollPickerResultsUntilVisible(
          tester,
          text: pageTwoArtist,
        );

        await tester.tap(find.text(pageTwoArtist).first);
        await _pumpFor(tester, const Duration(seconds: 1));

        await _waitForFinder(tester, find.text(pageTwoArtist));
        expect(find.byType(BottomSheet), findsNothing);
      } finally {
        await _cleanupAccounts(
          accountsRepository: accountsRepository,
          accountSlugs: createdAccountSlugs,
        );
        final eventTypeId = createdEventTypeId;
        if (eventTypeId != null && eventTypeId.trim().isNotEmpty) {
          try {
            await eventsRepository.deleteEventType(
              TenantAdminEventsRepoString.fromRaw(
                eventTypeId,
                isRequired: true,
              ),
            );
          } catch (_) {
            // Best-effort cleanup for local integration data.
          }
        }
        await GetIt.I.reset(dispose: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );
}

Future<void> _pumpWithAutoRoute(
  WidgetTester tester,
  Widget child,
) async {
  final router = RootStackRouter.build(
    routes: [
      NamedRouteDef(
        name: 'events-form-integration-test',
        path: '/',
        meta: canonicalRouteMeta(
          family: CanonicalRouteFamily.tenantAdminEventsInternal,
          chromeMode: RouteChromeMode.fullscreen,
        ),
        builder: (_, __) => child,
      ),
    ],
  )..ignorePopCompleters = true;

  await tester.pumpWidget(
    MaterialApp.router(
      routeInformationParser: router.defaultRouteParser(),
      routerDelegate: router.delegate(),
    ),
  );
  await tester.pumpAndSettle();
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

Future<void> _scrollPickerResultsUntilVisible(
  WidgetTester tester, {
  required String text,
  Duration timeout = const Duration(seconds: 20),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (find.text(text).evaluate().isNotEmpty) {
      return;
    }

    final pickerList = find.descendant(
      of: find.byType(BottomSheet).last,
      matching: find.byType(ListView),
    );
    if (pickerList.evaluate().isEmpty) {
      throw TestFailure('Related profile picker results list is not visible.');
    }

    await tester.drag(pickerList.last, const Offset(0, -600));
    await tester.pump(const Duration(milliseconds: 300));
    await _pumpFor(tester, const Duration(seconds: 1));
  }

  throw TestFailure('Timed out scrolling picker results until "$text".');
}

Future<List<String>> _seedArtists({
  required TenantAdminAccountsRepository accountsRepository,
  required String displayNamePrefix,
  required int count,
}) async {
  final createdAccountSlugs = <String>[];
  const batchSize = 10;

  for (var start = 1; start <= count; start += batchSize) {
    final end = (start + batchSize - 1) > count ? count : start + batchSize - 1;
    final batch = <Future<TenantAdminAccountOnboardingResult>>[];
    for (var index = start; index <= end; index += 1) {
      batch.add(
        accountsRepository.createAccountOnboarding(
          name: TenantAdminAccountsRepositoryContractPrimString.fromRaw(
            '$displayNamePrefix ${index.toString().padLeft(3, '0')}',
            isRequired: true,
          ),
          ownershipState: TenantAdminOwnershipState.tenantOwned,
          profileType: TenantAdminAccountsRepositoryContractPrimString.fromRaw(
            'artist',
            isRequired: true,
          ),
        ),
      );
    }

    final results = await Future.wait(batch);
    createdAccountSlugs.addAll(results.map((result) => result.account.slug));
  }

  return createdAccountSlugs;
}

Future<void> _cleanupAccounts({
  required TenantAdminAccountsRepository accountsRepository,
  required List<String> accountSlugs,
}) async {
  if (accountSlugs.isEmpty) {
    return;
  }

  const batchSize = 10;
  final orderedSlugs = accountSlugs.reversed.toList(growable: false);
  for (var start = 0; start < orderedSlugs.length; start += batchSize) {
    final end = (start + batchSize) > orderedSlugs.length
        ? orderedSlugs.length
        : start + batchSize;
    final chunk = orderedSlugs.sublist(start, end);
    await Future.wait(
      chunk.map((slug) async {
        final slugValue =
            TenantAdminAccountsRepositoryContractPrimString.fromRaw(
          slug,
          isRequired: true,
        );
        try {
          await accountsRepository.deleteAccount(slugValue);
        } catch (_) {
          // Best-effort cleanup for local integration data.
        }
        try {
          await accountsRepository.forceDeleteAccount(slugValue);
        } catch (_) {
          // Best-effort cleanup for local integration data.
        }
      }),
    );
  }
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
