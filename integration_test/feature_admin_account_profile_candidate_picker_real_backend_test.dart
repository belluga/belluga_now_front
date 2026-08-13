import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_meta.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_tenants_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/landlord_auth_repository_contract_values.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/infrastructure/repositories/landlord_auth_repository.dart';
import 'package:belluga_now/infrastructure/repositories/landlord_tenants_repository.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_account_profiles_repository.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_accounts_repository.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_selected_tenant_repository.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_location_selection_service.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profiles_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/screens/tenant_admin_account_profile_edit_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/screens/tenant_admin_account_profile_group_members_screen.dart';
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
    'real backend account-profile group flow creates a persisted group head, adds a member, and deletes it after confirmation',
    (tester) async {
      await GetIt.I.reset(dispose: true);

      final adminEmail = _requireDefine(
        'LANDLORD_ADMIN_EMAIL',
        adminEmailDefine,
      );
      final adminPassword = _requireDefine(
        'LANDLORD_ADMIN_PASSWORD',
        adminPasswordDefine,
      );
      final expectedTenantHost = _normalizeHost(tenantDomainDefine);
      final landlordOrigin = _deriveLandlordOriginFromTenantHost(
        expectedTenantHost,
      );

      final authRepository = LandlordAuthRepository(
        dio: Dio(BaseOptions(baseUrl: '$landlordOrigin/admin/api')),
      );
      final tenantScopeRepository = TenantAdminSelectedTenantRepository();
      final tenantsRepository = LandlordTenantsRepository(
        landlordAuthRepository: authRepository,
        landlordOriginOverride: landlordOrigin,
      );
      final accountsRepository = TenantAdminAccountsRepository(
        tenantScope: tenantScopeRepository,
      );
      final profilesRepository = TenantAdminAccountProfilesRepository(
        tenantScope: tenantScopeRepository,
      );
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: accountsRepository,
        taxonomiesRepository: _NoopTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );

      GetIt.I.registerSingleton<LandlordAuthRepositoryContract>(authRepository);
      GetIt.I.registerSingleton<TenantAdminAccountProfilesController>(
        controller,
      );

      final createdAccountSlugs = <String>[];
      final createdProfileTypes = <String>[];

      try {
        await authRepository.init();
        await authRepository.loginWithEmailPassword(
          landlordAuthRepoString(adminEmail),
          landlordAuthRepoString(adminPassword),
        );
        expect(authRepository.hasValidSession, isTrue);

        final tenants = await tenantsRepository.fetchTenants();
        expect(tenants, isNotEmpty);
        final tenantOption = _resolveTenantByDomain(
          tenants,
          expectedTenantHost,
        );
        tenantScopeRepository.setAvailableTenants(tenants);
        tenantScopeRepository.selectTenant(tenantOption);

        final unique = DateTime.now().microsecondsSinceEpoch.toString();
        final nestedType = await profilesRepository.createProfileType(
          type: tenantAdminAccountProfilesRepoString(
            'u03-nested-$unique',
            isRequired: true,
          ),
          label: tenantAdminAccountProfilesRepoString(
            'U03 Nested $unique',
            isRequired: true,
          ),
          pluralLabel: tenantAdminAccountProfilesRepoString(
            'U03 Nested $unique',
          ),
          capabilities: TenantAdminProfileTypeCapabilities(
            isQueryable: TenantAdminFlagValue(true),
            isFavoritable: TenantAdminFlagValue(false),
            isPoiEnabled: TenantAdminFlagValue(false),
            hasBio: TenantAdminFlagValue(false),
            hasContent: TenantAdminFlagValue(false),
            hasTaxonomies: TenantAdminFlagValue(false),
            hasAvatar: TenantAdminFlagValue(false),
            hasCover: TenantAdminFlagValue(false),
            hasEvents: TenantAdminFlagValue(false),
            hasNestedProfileGroups: TenantAdminFlagValue(true),
          ),
        );
        createdProfileTypes.add(nestedType.type);

        for (var index = 1; index <= 21; index += 1) {
          final result = await accountsRepository.createAccountOnboarding(
            name: TenantAdminAccountsRepositoryContractPrimString.fromRaw(
              'Xa Fixture ${index.toString().padLeft(3, '0')} $unique',
              isRequired: true,
            ),
            ownershipState: TenantAdminOwnershipState.tenantOwned,
            profileType:
                TenantAdminAccountsRepositoryContractPrimString.fromRaw(
                  nestedType.type,
                  isRequired: true,
                ),
          );
          createdAccountSlugs.add(result.account.slug);
        }

        final xapuriResult = await accountsRepository.createAccountOnboarding(
          name: TenantAdminAccountsRepositoryContractPrimString.fromRaw(
            'Xapuri U03 $unique',
            isRequired: true,
          ),
          ownershipState: TenantAdminOwnershipState.tenantOwned,
          profileType: TenantAdminAccountsRepositoryContractPrimString.fromRaw(
            nestedType.type,
            isRequired: true,
          ),
        );
        createdAccountSlugs.add(xapuriResult.account.slug);
        final xapuriProfileId = xapuriResult.accountProfile.id;
        final xapuriDisplayName = xapuriResult.accountProfile.displayName;

        final parentResult = await accountsRepository.createAccountOnboarding(
          name: TenantAdminAccountsRepositoryContractPrimString.fromRaw(
            'U04 Nested Parent $unique',
            isRequired: true,
          ),
          ownershipState: TenantAdminOwnershipState.tenantOwned,
          profileType: TenantAdminAccountsRepositoryContractPrimString.fromRaw(
            nestedType.type,
            isRequired: true,
          ),
        );
        createdAccountSlugs.add(parentResult.account.slug);

        await _pumpWithAutoRoute(
          tester,
          accountSlug: parentResult.account.slug,
          accountProfileId: parentResult.accountProfile.id,
        );

        await _waitForFinder(
          tester,
          find.byType(Scrollable),
          timeout: const Duration(seconds: 60),
        );
        await tester.scrollUntilVisible(
          find.byKey(const Key('tenantAdminEditAddNestedGroupButton')),
          240,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(
          find.byKey(const Key('tenantAdminEditAddNestedGroupButton')),
        );
        await tester.pumpAndSettle();
        await _waitForFinder(tester, find.text('Novo grupo'));
        await tester.enterText(find.byType(TextField).last, 'Parceiros');
        await tester.tap(find.text('Criar grupo').last);
        await tester.pumpAndSettle();

        await _waitForFinder(
          tester,
          find.text('Parceiros'),
          timeout: const Duration(seconds: 30),
        );
        final createdGroup = controller.editStateStreamValue.value
            .nestedProfileGroups
            .single;
        expect(createdGroup.id.trim(), isNotEmpty);
        expect(createdGroup.memberCount, 0);

        await tester.tap(find.widgetWithText(OutlinedButton, 'Gerenciar perfis'));
        await tester.pumpAndSettle();

        await _waitForFinder(
          tester,
          find.byTooltip('Adicionar perfis'),
          timeout: const Duration(seconds: 30),
        );
        await tester.tap(find.byTooltip('Adicionar perfis'));
        await tester.pumpAndSettle();

        await _waitForFinder(
          tester,
          find.byKey(const Key('tenantAdminAccountProfilePickerSearchField')),
          timeout: const Duration(seconds: 30),
        );
        expect(tester.takeException(), isNull);

        await tester.enterText(
          find.byKey(const Key('tenantAdminAccountProfilePickerSearchField')),
          'xa',
        );
        await _pumpFor(tester, const Duration(seconds: 2));
        expect(find.textContaining('Xa Fixture').evaluate().isNotEmpty, isTrue);

        // This owner proves the narrow-flow stability plus persisted selection.
        // Generic-prefix ranking and pagination remain outside this TODO.
        await tester.enterText(
          find.byKey(const Key('tenantAdminAccountProfilePickerSearchField')),
          'xapuri',
        );
        await _waitForFinder(
          tester,
          find.text(xapuriDisplayName),
          timeout: const Duration(seconds: 30),
        );
        await tester.tap(find.text(xapuriDisplayName).first);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('Adicionar').last);
        await tester.pump();
        await _pumpFor(tester, const Duration(seconds: 3));

        await _waitForFinder(
          tester,
          find.text(xapuriDisplayName),
          timeout: const Duration(seconds: 60),
        );
        expect(tester.takeException(), isNull);

        final readback = await profilesRepository.fetchAllNestedGroupMembers(
          accountProfileId: tenantAdminAccountProfilesRepoString(
            parentResult.accountProfile.id,
            isRequired: true,
          ),
          groupId: tenantAdminAccountProfilesRepoString(
            createdGroup.id,
            isRequired: true,
          ),
        );
        expect(
          readback.items.map((item) => item.id).toList(growable: false),
          contains(xapuriProfileId),
        );

        await tester.pageBack();
        await tester.pumpAndSettle();
        await _waitForFinder(
          tester,
          find.byKey(const Key('tenantAdminEditAddNestedGroupButton')),
          timeout: const Duration(seconds: 30),
        );
        await tester.tap(find.byTooltip('Remover grupo').last);
        await tester.pumpAndSettle();
        await _waitForFinder(tester, find.text('Excluir grupo'));
        expect(
          find.textContaining('Este grupo possui 1 conta(s) vinculada(s).'),
          findsOneWidget,
        );
        await tester.tap(find.text('Excluir').last);
        await tester.pumpAndSettle();

        expect(find.text('Parceiros'), findsNothing);

        final refreshedParent = await profilesRepository.fetchAccountProfile(
          tenantAdminAccountProfilesRepoString(
            parentResult.accountProfile.id,
            isRequired: true,
          ),
        );
        expect(
          refreshedParent.nestedProfileGroups
              .where((group) => group.id == createdGroup.id),
          isEmpty,
        );
      } finally {
        await _cleanupAccounts(
          accountsRepository: accountsRepository,
          accountSlugs: createdAccountSlugs,
        );
        for (final profileType in createdProfileTypes.reversed) {
          try {
            await profilesRepository.deleteProfileType(
              tenantAdminAccountProfilesRepoString(
                profileType,
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
  WidgetTester tester, {
  required String accountSlug,
  required String accountProfileId,
}) async {
  final router = RootStackRouter.build(
    routes: [
      NamedRouteDef(
        name: TenantAdminAccountProfileEditRoute.name,
        path: '/',
        meta: canonicalRouteMeta(
          family: CanonicalRouteFamily.tenantAdminAccountsInternal,
          chromeMode: RouteChromeMode.fullscreen,
        ),
        builder: (_, _) => Scaffold(
          body: TenantAdminAccountProfileEditScreen(
            accountSlug: accountSlug,
            accountProfileId: accountProfileId,
          ),
        ),
      ),
      NamedRouteDef(
        name: TenantAdminAccountProfileGroupMembersRoute.name,
        path: '/profile-group-members',
        meta: canonicalRouteMeta(
          family: CanonicalRouteFamily.tenantAdminAccountsInternal,
          chromeMode: RouteChromeMode.fullscreen,
        ),
        builder: (_, routeData) {
          final args = routeData
              .argsAs<TenantAdminAccountProfileGroupMembersRouteArgs>();
          final controller =
              GetIt.I.get<TenantAdminAccountProfilesController>();
          final liveGroup = _findCurrentNestedGroup(
            controller: controller,
            groupId: args.groupId,
          );
          return TenantAdminAccountProfileGroupMembersScreen(
            key: args.key,
            accountProfileId: args.accountProfileId,
            group: liveGroup,
          );
        },
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

TenantAdminNestedProfileGroup _findCurrentNestedGroup({
  required TenantAdminAccountProfilesController controller,
  required String groupId,
}) {
  for (final group in controller.editStateStreamValue.value.nestedProfileGroups) {
    if (group.id == groupId) {
      return group;
    }
  }
  final profile = controller.accountProfileStreamValue.value;
  if (profile != null) {
    for (final group in profile.nestedProfileGroups) {
      if (group.id == groupId) {
        return group;
      }
    }
  }
  return TenantAdminNestedProfileGroup(
    idValue: TenantAdminNestedProfileGroupTextValue(groupId),
    labelValue: TenantAdminNestedProfileGroupTextValue('Grupo'),
    orderValue: TenantAdminNestedProfileGroupOrderValue(),
  );
}

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
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
  final landlordHost = labels.length >= 3
      ? labels.sublist(1).join('.')
      : labels.join('.');
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
