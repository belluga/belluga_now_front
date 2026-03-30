import 'package:belluga_now/application/application.dart';
import 'package:belluga_now/application/application_contract.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_tenants_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_onboarding_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_accounts_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/presentation/tenant_admin/taxonomies/controllers/tenant_admin_taxonomies_controller.dart';
import 'support/fake_landlord_app_data_backend.dart';
import 'package:belluga_now/infrastructure/platform/app_data_local_info_source/app_data_local_info_source.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stream_value/core/stream_value.dart';
import 'support/integration_test_bootstrap.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  IntegrationTestBootstrap.ensureNonProductionLandlordDomain();

  Future<void> _waitForFinder(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 20),
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

  Finder _tenantAdminShellRouterFinder() {
    return find.byWidgetPredicate((widget) {
      final key = widget.key;
      if (key is! ValueKey<String>) {
        return false;
      }
      return key.value.startsWith('tenant-admin-shell-router-');
    });
  }

  Future<void> _registerCommonDependencies({
    required TenantAdminTaxonomiesRepositoryContract taxonomiesRepository,
    TenantAdminAccountsRepositoryContract? accountsRepository,
    TenantAdminAccountProfilesRepositoryContract? profilesRepository,
  }) async {
    final getIt = GetIt.I;
    await getIt.reset();
    if (getIt.isRegistered<ApplicationContract>()) {
      getIt.unregister<ApplicationContract>();
    }
    if (getIt.isRegistered<AppDataRepository>()) {
      getIt.unregister<AppDataRepository>();
    }
    if (getIt.isRegistered<AdminModeRepositoryContract>()) {
      getIt.unregister<AdminModeRepositoryContract>();
    }
    if (getIt.isRegistered<LandlordAuthRepositoryContract>()) {
      getIt.unregister<LandlordAuthRepositoryContract>();
    }
    if (getIt.isRegistered<LandlordTenantsRepositoryContract>()) {
      getIt.unregister<LandlordTenantsRepositoryContract>();
    }
    if (getIt.isRegistered<TenantAdminTaxonomiesRepositoryContract>()) {
      getIt.unregister<TenantAdminTaxonomiesRepositoryContract>();
    }
    if (getIt.isRegistered<TenantAdminAccountsRepositoryContract>()) {
      getIt.unregister<TenantAdminAccountsRepositoryContract>();
    }
    if (getIt.isRegistered<TenantAdminAccountProfilesRepositoryContract>()) {
      getIt.unregister<TenantAdminAccountProfilesRepositoryContract>();
    }

    getIt.registerSingleton<AppDataRepositoryContract>(
      AppDataRepository(
        backend: const FakeLandlordAppDataBackend(),
        localInfoSource: AppDataLocalInfoSource(),
      ),
    );
    getIt.registerSingleton<AdminModeRepositoryContract>(
      _FakeAdminModeRepository(AdminMode.landlord),
    );
    getIt.registerSingleton<LandlordAuthRepositoryContract>(
      _FakeLandlordAuthRepository(hasValidSession: true),
    );
    getIt.registerSingleton<LandlordTenantsRepositoryContract>(
      _FakeLandlordTenantsRepository(),
    );
    getIt.registerSingleton<TenantAdminTaxonomiesRepositoryContract>(
      taxonomiesRepository,
    );
    if (accountsRepository != null) {
      getIt.registerSingleton<TenantAdminAccountsRepositoryContract>(
        accountsRepository,
      );
    }
    if (profilesRepository != null) {
      getIt.registerSingleton<TenantAdminAccountProfilesRepositoryContract>(
        profilesRepository,
      );
    }
  }

  testWidgets('Tenant admin can create, edit, and delete taxonomies',
      (tester) async {
    final repository = _FakeTaxonomiesRepository();
    await _registerCommonDependencies(taxonomiesRepository: repository);

    final app = Application();
    GetIt.I.registerSingleton<ApplicationContract>(app);
    await app.init();

    app.appRouter.replaceAll(
      [
        TenantAdminShellRoute(
          children: [TenantAdminTaxonomyCreateRoute()],
        ),
      ],
    );

    await tester.pumpWidget(app);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await _waitForFinder(tester, _tenantAdminShellRouterFinder());
    app.appRouter.navigate(
      TenantAdminShellRoute(
        children: [TenantAdminTaxonomyCreateRoute()],
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome'),
      'Cozinha',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Slug'),
      'cuisine',
    );
    final appliesToAccountProfile =
        find.widgetWithText(FilterChip, 'account_profile');
    await tester.ensureVisible(appliesToAccountProfile);
    await tester.tap(appliesToAccountProfile, warnIfMissed: false);
    await tester.pumpAndSettle();
    final taxonomiesController = GetIt.I.get<TenantAdminTaxonomiesController>();
    taxonomiesController.toggleTaxonomyAppliesToTarget('account_profile', true);
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final taxonomySubmitButton =
        find.byKey(const ValueKey('taxonomy-form-submit-button'));
    await tester.ensureVisible(taxonomySubmitButton);
    await tester.tap(taxonomySubmitButton);
    await tester.pumpAndSettle();
    final created = (await repository.fetchTaxonomies())
        .firstWhere((taxonomy) => taxonomy.slug == 'cuisine');

    expect(created.name, 'Cozinha');
    expect(created.appliesTo.contains('account_profile'), isTrue);

    app.appRouter.replaceAll(
      [
        TenantAdminShellRoute(
          children: [
            TenantAdminTaxonomyEditRoute(
              taxonomyId: created.id,
            ),
          ],
        ),
      ],
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome'),
      'Cozinha Nova',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(taxonomySubmitButton);
    await tester.tap(taxonomySubmitButton);
    await tester.pumpAndSettle();

    final updated = (await repository.fetchTaxonomies())
        .firstWhere((taxonomy) => taxonomy.id == created.id);
    expect(updated.name, 'Cozinha Nova');

    await repository.deleteTaxonomy(tenantAdminTaxRepoString(created.id));
    final taxonomies = await repository.fetchTaxonomies();
    expect(
      taxonomies.where((taxonomy) => taxonomy.id == created.id),
      isEmpty,
    );
  });

  testWidgets('Account onboarding selects taxonomy terms by registry',
      (tester) async {
    final repository = _FakeTaxonomiesRepository()
      ..seedTaxonomy(
        tenantAdminTaxonomyDefinitionFromRaw(
          id: 'tax-1',
          slug: 'music_genre',
          name: 'Genero',
          appliesTo: ['account_profile'],
          icon: null,
          color: null,
        ),
        [
          tenantAdminTaxonomyTermDefinitionFromRaw(
            id: 'term-1',
            taxonomyId: 'tax-1',
            slug: 'samba',
            name: 'Samba',
          ),
        ],
      )
      ..seedTaxonomy(
        tenantAdminTaxonomyDefinitionFromRaw(
          id: 'tax-2',
          slug: 'cuisine',
          name: 'Cozinha',
          appliesTo: ['static_asset'],
          icon: null,
          color: null,
        ),
        [],
      );

    final accountsRepository = _FakeAccountsRepository();
    final profilesRepository = _FakeAccountProfilesRepository();
    await _registerCommonDependencies(
      taxonomiesRepository: repository,
      accountsRepository: accountsRepository,
      profilesRepository: profilesRepository,
    );

    final app = Application();
    GetIt.I.registerSingleton<ApplicationContract>(app);
    await app.init();

    app.appRouter.replaceAll([
      TenantAdminShellRoute(children: [TenantAdminAccountCreateRoute()]),
    ]);

    await tester.pumpWidget(app);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await _waitForFinder(tester, _tenantAdminShellRouterFinder());
    app.appRouter.navigate(
      TenantAdminShellRoute(children: [TenantAdminAccountCreateRoute()]),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await _waitForFinder(tester, find.byType(DropdownButtonFormField<String>));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Artista').last);
    await tester.pumpAndSettle();

    expect(find.text('Taxonomias'), findsWidgets);
    expect(find.text('Genero'), findsOneWidget);
    expect(find.text('Samba'), findsOneWidget);
    expect(find.text('Cozinha'), findsNothing);

    await tester.tap(find.text('Samba'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome'),
      'Perfil Teste',
    );
    final saveButton =
        find.byKey(const ValueKey('tenant_admin_account_create_save'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    final hasSamba = accountsRepository.lastOnboardingTerms.any(
      (term) => term.type == 'music_genre' && term.value == 'samba',
    );
    expect(hasSamba, true);
  });
}

class _FakeAdminModeRepository implements AdminModeRepositoryContract {
  _FakeAdminModeRepository(this._mode);

  final AdminMode _mode;

  @override
  StreamValue<AdminMode> get modeStreamValue =>
      StreamValue<AdminMode>(defaultValue: _mode);

  @override
  AdminMode get mode => _mode;

  @override
  bool get isLandlordMode => _mode == AdminMode.landlord;

  @override
  Future<void> init() async {}

  @override
  Future<void> setLandlordMode() async {}

  @override
  Future<void> setUserMode() async {}
}

class _FakeLandlordAuthRepository implements LandlordAuthRepositoryContract {
  _FakeLandlordAuthRepository({required this.hasValidSession});

  @override
  final bool hasValidSession;

  @override
  String get token => hasValidSession ? 'token' : '';

  @override
  Future<void> init() async {}

  @override
  Future<void> loginWithEmailPassword(
      LandlordAuthRepositoryContractPrimString email,
      LandlordAuthRepositoryContractPrimString password) async {}

  @override
  Future<void> logout() async {}
}

class _FakeAccountsRepository
    with TenantAdminAccountsRepositoryPaginationMixin
    implements TenantAdminAccountsRepositoryContract {
  TenantAdminTaxonomyTerms lastOnboardingTerms =
      const TenantAdminTaxonomyTerms.empty();

  @override
  Future<List<TenantAdminAccount>> fetchAccounts() async => [];

  @override
  Future<TenantAdminPagedAccountsResult> fetchAccountsPage({
    required TenantAdminAccountsRepositoryContractPrimInt page,
    required TenantAdminAccountsRepositoryContractPrimInt pageSize,
    TenantAdminOwnershipState? ownershipState,
    TenantAdminAccountsRepositoryContractPrimString? searchQuery,
  }) async {
    return tenantAdminPagedAccountsResultFromRaw(
      accounts: <TenantAdminAccount>[],
      hasMore: false,
    );
  }

  @override
  Future<TenantAdminAccount> fetchAccountBySlug(
    TenantAdminAccountsRepositoryContractPrimString accountSlug,
  ) async {
    return tenantAdminAccountFromRaw(
      id: 'account-1',
      name: 'Conta Teste',
      slug: accountSlug.value,
      document: tenantAdminDocumentFromRaw(type: 'cpf', number: '000'),
      ownershipState: TenantAdminOwnershipState.tenantOwned,
    );
  }

  @override
  Future<TenantAdminAccount> createAccount({
    required TenantAdminAccountsRepositoryContractPrimString name,
    TenantAdminDocument? document,
    required TenantAdminOwnershipState ownershipState,
    TenantAdminAccountsRepositoryContractPrimString? organizationId,
  }) async {
    return tenantAdminAccountFromRaw(
      id: 'account-1',
      name: name.value,
      slug: 'account-1',
      document:
          document ?? tenantAdminDocumentFromRaw(type: 'cpf', number: '000'),
      ownershipState: ownershipState,
      organizationId: organizationId?.value,
    );
  }

  @override
  Future<TenantAdminAccountOnboardingResult> createAccountOnboarding({
    required TenantAdminAccountsRepositoryContractPrimString name,
    required TenantAdminOwnershipState ownershipState,
    required TenantAdminAccountsRepositoryContractPrimString profileType,
    TenantAdminLocation? location,
    TenantAdminTaxonomyTerms taxonomyTerms =
        const TenantAdminTaxonomyTerms.empty(),
    TenantAdminAccountsRepositoryContractPrimString? bio,
    TenantAdminAccountsRepositoryContractPrimString? content,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    lastOnboardingTerms = taxonomyTerms;
    final account = await createAccount(
      name: name,
      ownershipState: ownershipState,
    );
    return TenantAdminAccountOnboardingResult(
      account: account,
      accountProfile: tenantAdminAccountProfileFromRaw(
        id: 'profile-1',
        accountId: account.id,
        profileType: profileType.value,
        displayName: name.value,
        location: location,
        taxonomyTerms: taxonomyTerms,
        bio: bio?.value,
        content: content?.value,
      ),
    );
  }

  @override
  Future<TenantAdminAccount> updateAccount({
    required TenantAdminAccountsRepositoryContractPrimString accountSlug,
    TenantAdminAccountsRepositoryContractPrimString? name,
    TenantAdminAccountsRepositoryContractPrimString? slug,
    TenantAdminDocument? document,
    TenantAdminOwnershipState? ownershipState,
  }) async {
    return tenantAdminAccountFromRaw(
      id: 'account-1',
      name: name?.value ?? 'Conta',
      slug: slug?.value ?? accountSlug.value,
      document:
          document ?? tenantAdminDocumentFromRaw(type: 'cpf', number: '000'),
      ownershipState: TenantAdminOwnershipState.tenantOwned,
    );
  }

  @override
  Future<void> deleteAccount(
      TenantAdminAccountsRepositoryContractPrimString accountSlug) async {}

  @override
  Future<TenantAdminAccount> restoreAccount(
    TenantAdminAccountsRepositoryContractPrimString accountSlug,
  ) async {
    return tenantAdminAccountFromRaw(
      id: 'account-1',
      name: 'Conta',
      slug: accountSlug.value,
      document: tenantAdminDocumentFromRaw(type: 'cpf', number: '000'),
      ownershipState: TenantAdminOwnershipState.tenantOwned,
    );
  }

  @override
  Future<void> forceDeleteAccount(
      TenantAdminAccountsRepositoryContractPrimString accountSlug) async {}
}

class _FakeLandlordTenantsRepository
    implements LandlordTenantsRepositoryContract {
  @override
  Future<List<LandlordTenantOption>> fetchTenants() async {
    return [
      landlordTenantOptionFromRaw(
        id: 'tenant-guarappari',
        name: 'Guarappari',
        mainDomain: 'guarappari.local.test',
      ),
    ];
  }
}

class _FakeAccountProfilesRepository
    with TenantAdminProfileTypesPaginationMixin
    implements TenantAdminAccountProfilesRepositoryContract {
  TenantAdminTaxonomyTerms lastCreatedTerms =
      const TenantAdminTaxonomyTerms.empty();

  @override
  Future<List<TenantAdminProfileTypeDefinition>> fetchProfileTypes() async {
    return [
      tenantAdminProfileTypeDefinitionFromRaw(
        type: 'artist',
        label: 'Artista',
        allowedTaxonomies: ['music_genre'],
        capabilities: TenantAdminProfileTypeCapabilities(
          isFavoritable: TenantAdminFlagValue(true),
          isPoiEnabled: TenantAdminFlagValue(false),
          hasBio: TenantAdminFlagValue(false),
          hasContent: TenantAdminFlagValue(false),
          hasTaxonomies: TenantAdminFlagValue(true),
          hasAvatar: TenantAdminFlagValue(false),
          hasCover: TenantAdminFlagValue(false),
          hasEvents: TenantAdminFlagValue(false),
        ),
      ),
    ];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminProfileTypeDefinition>>
      fetchProfileTypesPage({
    required TenantAdminAccountProfilesRepoInt page,
    required TenantAdminAccountProfilesRepoInt pageSize,
  }) async {
    final types = await fetchProfileTypes();
    final start = (page.value - 1) * pageSize.value;
    if (page.value <= 0 || pageSize.value <= 0 || start >= types.length) {
      return tenantAdminPagedResultFromRaw(
        items: <TenantAdminProfileTypeDefinition>[],
        hasMore: false,
      );
    }
    final end = start + pageSize.value < types.length
        ? start + pageSize.value
        : types.length;
    return tenantAdminPagedResultFromRaw(
      items: types.sublist(start, end),
      hasMore: end < types.length,
    );
  }

  @override
  Future<List<TenantAdminAccountProfile>> fetchAccountProfiles({
    TenantAdminAccountProfilesRepoString? accountId,
  }) async =>
      [];

  @override
  Future<TenantAdminAccountProfile> fetchAccountProfile(
    TenantAdminAccountProfilesRepoString accountProfileId,
  ) async {
    return tenantAdminAccountProfileFromRaw(
      id: 'profile-1',
      accountId: 'account-1',
      profileType: 'artist',
      displayName: 'Perfil',
    );
  }

  @override
  Future<TenantAdminAccountProfile> createAccountProfile({
    required TenantAdminAccountProfilesRepoString accountId,
    required TenantAdminAccountProfilesRepoString profileType,
    required TenantAdminAccountProfilesRepoString displayName,
    TenantAdminLocation? location,
    TenantAdminTaxonomyTerms taxonomyTerms =
        const TenantAdminTaxonomyTerms.empty(),
    TenantAdminAccountProfilesRepoString? bio,
    TenantAdminAccountProfilesRepoString? content,
    TenantAdminAccountProfilesRepoString? avatarUrl,
    TenantAdminAccountProfilesRepoString? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    lastCreatedTerms = taxonomyTerms;
    return tenantAdminAccountProfileFromRaw(
      id: 'profile-1',
      accountId: accountId,
      profileType: profileType,
      displayName: displayName,
      taxonomyTerms: taxonomyTerms,
      location: location,
      bio: bio,
      avatarUrl: avatarUrl,
      coverUrl: coverUrl,
    );
  }

  @override
  Future<TenantAdminAccountProfile> updateAccountProfile({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    TenantAdminAccountProfilesRepoString? profileType,
    TenantAdminAccountProfilesRepoString? displayName,
    TenantAdminAccountProfilesRepoString? slug,
    TenantAdminLocation? location,
    TenantAdminTaxonomyTerms? taxonomyTerms,
    TenantAdminAccountProfilesRepoString? bio,
    TenantAdminAccountProfilesRepoString? content,
    TenantAdminAccountProfilesRepoString? avatarUrl,
    TenantAdminAccountProfilesRepoString? coverUrl,
    TenantAdminAccountProfilesRepoBool? removeAvatar,
    TenantAdminAccountProfilesRepoBool? removeCover,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    return tenantAdminAccountProfileFromRaw(
      id: accountProfileId,
      accountId: 'account-1',
      profileType: profileType ?? 'artist',
      displayName: displayName ?? 'Perfil',
      taxonomyTerms: taxonomyTerms ?? const TenantAdminTaxonomyTerms.empty(),
      location: location,
      bio: bio,
      avatarUrl: avatarUrl,
      coverUrl: coverUrl,
    );
  }

  @override
  Future<void> deleteAccountProfile(
      TenantAdminAccountProfilesRepoString accountProfileId) async {}

  @override
  Future<TenantAdminAccountProfile> restoreAccountProfile(
    TenantAdminAccountProfilesRepoString accountProfileId,
  ) async {
    return tenantAdminAccountProfileFromRaw(
      id: 'profile-1',
      accountId: 'account-1',
      profileType: 'artist',
      displayName: 'Perfil',
    );
  }

  @override
  Future<void> forceDeleteAccountProfile(
      TenantAdminAccountProfilesRepoString accountProfileId) async {}

  @override
  Future<TenantAdminProfileTypeDefinition> createProfileType({
    required TenantAdminAccountProfilesRepoString type,
    required TenantAdminAccountProfilesRepoString label,
    List<TenantAdminAccountProfilesRepoString> allowedTaxonomies = const [],
    required TenantAdminProfileTypeCapabilities capabilities,
  }) async {
    return tenantAdminProfileTypeDefinitionFromRaw(
      type: type,
      label: label,
      allowedTaxonomies: allowedTaxonomies,
      capabilities: capabilities,
    );
  }

  @override
  Future<TenantAdminProfileTypeDefinition> updateProfileType({
    required TenantAdminAccountProfilesRepoString type,
    TenantAdminAccountProfilesRepoString? newType,
    TenantAdminAccountProfilesRepoString? label,
    List<TenantAdminAccountProfilesRepoString>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
  }) async {
    return tenantAdminProfileTypeDefinitionFromRaw(
      type: type,
      label: label ?? 'Artista',
      allowedTaxonomies: allowedTaxonomies ?? ['music_genre'],
      capabilities: capabilities ??
          TenantAdminProfileTypeCapabilities(
            isFavoritable: TenantAdminFlagValue(true),
            isPoiEnabled: TenantAdminFlagValue(false),
            hasBio: TenantAdminFlagValue(false),
            hasContent: TenantAdminFlagValue(false),
            hasTaxonomies: TenantAdminFlagValue(true),
            hasAvatar: TenantAdminFlagValue(false),
            hasCover: TenantAdminFlagValue(false),
            hasEvents: TenantAdminFlagValue(false),
          ),
    );
  }

  @override
  Future<void> deleteProfileType(
      TenantAdminAccountProfilesRepoString type) async {}
}

class _FakeTaxonomiesRepository
    with TenantAdminTaxonomiesPaginationMixin
    implements TenantAdminTaxonomiesRepositoryContract {
  final List<TenantAdminTaxonomyDefinition> _taxonomies = const [];
  final Map<String, List<TenantAdminTaxonomyTermDefinition>> _terms = const {};

  void seedTaxonomy(
    TenantAdminTaxonomyDefinition taxonomy,
    List<TenantAdminTaxonomyTermDefinition> terms,
  ) {
    _taxonomies.add(taxonomy);
    _terms[taxonomy.id] = List.of(terms);
  }

  @override
  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomies() async =>
      List.of(_taxonomies);

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyDefinition>>
      fetchTaxonomiesPage({
    required TenantAdminTaxRepoInt page,
    required TenantAdminTaxRepoInt pageSize,
  }) async {
    final taxonomies = await fetchTaxonomies();
    final start = (page.value - 1) * pageSize.value;
    if (page.value <= 0 || pageSize.value <= 0 || start >= taxonomies.length) {
      return tenantAdminPagedResultFromRaw(
        items: <TenantAdminTaxonomyDefinition>[],
        hasMore: false,
      );
    }
    final end = start + pageSize.value < taxonomies.length
        ? start + pageSize.value
        : taxonomies.length;
    return tenantAdminPagedResultFromRaw(
      items: taxonomies.sublist(start, end),
      hasMore: end < taxonomies.length,
    );
  }

  @override
  Future<TenantAdminTaxonomyDefinition> createTaxonomy({
    required TenantAdminTaxRepoString slug,
    required TenantAdminTaxRepoString name,
    required List<TenantAdminTaxRepoString> appliesTo,
    TenantAdminTaxRepoString? icon,
    TenantAdminTaxRepoString? color,
  }) async {
    final taxonomy = tenantAdminTaxonomyDefinitionFromRaw(
      id: 'tax-${_taxonomies.length + 1}',
      slug: slug.value,
      name: name.value,
      appliesTo: appliesTo.map((entry) => entry.value).toList(growable: false),
      icon: icon?.value,
      color: color?.value,
    );
    _taxonomies.add(taxonomy);
    _terms.putIfAbsent(taxonomy.id, () => []);
    return taxonomy;
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
    final index = _taxonomies.indexWhere((item) => item.id == taxonomyId.value);
    if (index == -1) {
      throw Exception('Taxonomy not found');
    }
    final existing = _taxonomies[index];
    final updated = tenantAdminTaxonomyDefinitionFromRaw(
      id: taxonomyId.value,
      slug: slug?.value ?? existing.slug,
      name: name?.value ?? existing.name,
      appliesTo:
          appliesTo?.map((entry) => entry.value).toList(growable: false) ??
              existing.appliesTo,
      icon: icon?.value ?? existing.icon,
      color: color?.value ?? existing.color,
    );
    _taxonomies[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteTaxonomy(TenantAdminTaxRepoString taxonomyId) async {
    _taxonomies.removeWhere((item) => item.id == taxonomyId.value);
    _terms.remove(taxonomyId.value);
  }

  @override
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required TenantAdminTaxRepoString taxonomyId,
  }) async {
    return List.of(_terms[taxonomyId.value] ?? []);
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyTermDefinition>>
      fetchTermsPage({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoInt page,
    required TenantAdminTaxRepoInt pageSize,
  }) async {
    final terms = await fetchTerms(taxonomyId: taxonomyId);
    final start = (page.value - 1) * pageSize.value;
    if (page.value <= 0 || pageSize.value <= 0 || start >= terms.length) {
      return tenantAdminPagedResultFromRaw(
        items: <TenantAdminTaxonomyTermDefinition>[],
        hasMore: false,
      );
    }
    final end = start + pageSize.value < terms.length
        ? start + pageSize.value
        : terms.length;
    return tenantAdminPagedResultFromRaw(
      items: terms.sublist(start, end),
      hasMore: end < terms.length,
    );
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> createTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString slug,
    required TenantAdminTaxRepoString name,
  }) async {
    final list = _terms.putIfAbsent(taxonomyId.value, () => []);
    final term = tenantAdminTaxonomyTermDefinitionFromRaw(
      id: 'term-${list.length + 1}',
      taxonomyId: taxonomyId.value,
      slug: slug.value,
      name: name.value,
    );
    list.add(term);
    return term;
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> updateTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString termId,
    TenantAdminTaxRepoString? slug,
    TenantAdminTaxRepoString? name,
  }) async {
    final list = _terms[taxonomyId.value] ?? [];
    final index = list.indexWhere((term) => term.id == termId.value);
    if (index == -1) {
      throw Exception('Term not found');
    }
    final existing = list[index];
    final updated = tenantAdminTaxonomyTermDefinitionFromRaw(
      id: termId.value,
      taxonomyId: taxonomyId.value,
      slug: slug?.value ?? existing.slug,
      name: name?.value ?? existing.name,
    );
    list[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString termId,
  }) async {
    final list = _terms[taxonomyId.value];
    list?.removeWhere((term) => term.id == termId.value);
  }
}
