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
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_accounts_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/presentation/tenant_admin/taxonomies/controllers/tenant_admin_taxonomies_controller.dart';
import 'support/fake_landlord_app_data_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/local/app_data_local_info_source/app_data_local_info_source_stub.dart';
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
        const TenantAdminShellRoute(
          children: [TenantAdminTaxonomyCreateRoute()],
        ),
      ],
    );

    await tester.pumpWidget(app);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await _waitForFinder(tester, _tenantAdminShellRouterFinder());
    app.appRouter.navigate(
      const TenantAdminShellRoute(
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
            TenantAdminTaxonomyEditRoute(taxonomy: created),
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

    await repository.deleteTaxonomy(created.id);
    final taxonomies = await repository.fetchTaxonomies();
    expect(
      taxonomies.where((taxonomy) => taxonomy.id == created.id),
      isEmpty,
    );
  });

  testWidgets('Account profile creation selects taxonomy terms by registry',
      (tester) async {
    final repository = _FakeTaxonomiesRepository()
      ..seedTaxonomy(
        TenantAdminTaxonomyDefinition(
          id: 'tax-1',
          slug: 'music_genre',
          name: 'Genero',
          appliesTo: const ['account_profile'],
          icon: null,
          color: null,
        ),
        [
          const TenantAdminTaxonomyTermDefinition(
            id: 'term-1',
            taxonomyId: 'tax-1',
            slug: 'samba',
            name: 'Samba',
          ),
        ],
      )
      ..seedTaxonomy(
        TenantAdminTaxonomyDefinition(
          id: 'tax-2',
          slug: 'cuisine',
          name: 'Cozinha',
          appliesTo: const ['static_asset'],
          icon: null,
          color: null,
        ),
        const [],
      );

    final profilesRepository = _FakeAccountProfilesRepository();
    await _registerCommonDependencies(
      taxonomiesRepository: repository,
      accountsRepository: _FakeAccountsRepository(),
      profilesRepository: profilesRepository,
    );

    final app = Application();
    GetIt.I.registerSingleton<ApplicationContract>(app);
    await app.init();

    app.appRouter.replaceAll([
      TenantAdminShellRoute(
        children: [
          TenantAdminAccountProfileCreateRoute(accountSlug: 'account-1'),
        ],
      ),
    ]);

    await tester.pumpWidget(app);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await _waitForFinder(tester, _tenantAdminShellRouterFinder());
    app.appRouter.navigate(
      TenantAdminShellRoute(
        children: [
          TenantAdminAccountProfileCreateRoute(accountSlug: 'account-1'),
        ],
      ),
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

    await tester.enterText(find.byType(TextFormField).at(0), 'Perfil Teste');
    await tester.tap(find.text('Salvar perfil'));
    await tester.pumpAndSettle();

    final hasSamba = profilesRepository.lastCreatedTerms.any(
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
  Future<void> loginWithEmailPassword(String email, String password) async {}

  @override
  Future<void> logout() async {}
}

class _FakeAccountsRepository implements TenantAdminAccountsRepositoryContract {
  @override
  Future<List<TenantAdminAccount>> fetchAccounts() async => const [];

  @override
  Future<TenantAdminPagedAccountsResult> fetchAccountsPage({
    required int page,
    required int pageSize,
  }) async {
    return const TenantAdminPagedAccountsResult(
      accounts: <TenantAdminAccount>[],
      hasMore: false,
    );
  }

  @override
  Future<TenantAdminAccount> fetchAccountBySlug(String accountSlug) async {
    return TenantAdminAccount(
      id: 'account-1',
      name: 'Conta Teste',
      slug: accountSlug,
      document: const TenantAdminDocument(type: 'cpf', number: '000'),
      ownershipState: TenantAdminOwnershipState.tenantOwned,
    );
  }

  @override
  Future<TenantAdminAccount> createAccount({
    required String name,
    required TenantAdminDocument document,
    required TenantAdminOwnershipState ownershipState,
    String? organizationId,
  }) async {
    return TenantAdminAccount(
      id: 'account-1',
      name: name,
      slug: 'account-1',
      document: document,
      ownershipState: ownershipState,
      organizationId: organizationId,
    );
  }

  @override
  Future<TenantAdminAccount> updateAccount({
    required String accountSlug,
    String? name,
    TenantAdminDocument? document,
  }) async {
    return TenantAdminAccount(
      id: 'account-1',
      name: name ?? 'Conta',
      slug: accountSlug,
      document:
          document ?? const TenantAdminDocument(type: 'cpf', number: '000'),
      ownershipState: TenantAdminOwnershipState.tenantOwned,
    );
  }

  @override
  Future<void> deleteAccount(String accountSlug) async {}

  @override
  Future<TenantAdminAccount> restoreAccount(String accountSlug) async {
    return TenantAdminAccount(
      id: 'account-1',
      name: 'Conta',
      slug: accountSlug,
      document: const TenantAdminDocument(type: 'cpf', number: '000'),
      ownershipState: TenantAdminOwnershipState.tenantOwned,
    );
  }

  @override
  Future<void> forceDeleteAccount(String accountSlug) async {}
}

class _FakeLandlordTenantsRepository
    implements LandlordTenantsRepositoryContract {
  @override
  Future<List<LandlordTenantOption>> fetchTenants() async {
    return const [
      LandlordTenantOption(
        id: 'tenant-guarappari',
        name: 'Guarappari',
        mainDomain: 'guarappari.local.test',
      ),
    ];
  }
}

class _FakeAccountProfilesRepository
    implements TenantAdminAccountProfilesRepositoryContract {
  List<TenantAdminTaxonomyTerm> lastCreatedTerms = const [];

  @override
  Future<List<TenantAdminProfileTypeDefinition>> fetchProfileTypes() async {
    return const [
      TenantAdminProfileTypeDefinition(
        type: 'artist',
        label: 'Artista',
        allowedTaxonomies: ['music_genre'],
        capabilities: TenantAdminProfileTypeCapabilities(
          isFavoritable: true,
          isPoiEnabled: false,
          hasBio: false,
          hasTaxonomies: true,
          hasAvatar: false,
          hasCover: false,
          hasEvents: false,
        ),
      ),
    ];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminProfileTypeDefinition>>
      fetchProfileTypesPage({
    required int page,
    required int pageSize,
  }) async {
    final types = await fetchProfileTypes();
    final start = (page - 1) * pageSize;
    if (page <= 0 || pageSize <= 0 || start >= types.length) {
      return const TenantAdminPagedResult<TenantAdminProfileTypeDefinition>(
        items: <TenantAdminProfileTypeDefinition>[],
        hasMore: false,
      );
    }
    final end =
        start + pageSize < types.length ? start + pageSize : types.length;
    return TenantAdminPagedResult<TenantAdminProfileTypeDefinition>(
      items: types.sublist(start, end),
      hasMore: end < types.length,
    );
  }

  @override
  Future<List<TenantAdminAccountProfile>> fetchAccountProfiles({
    String? accountId,
  }) async =>
      const [];

  @override
  Future<TenantAdminAccountProfile> fetchAccountProfile(
    String accountProfileId,
  ) async {
    return const TenantAdminAccountProfile(
      id: 'profile-1',
      accountId: 'account-1',
      profileType: 'artist',
      displayName: 'Perfil',
    );
  }

  @override
  Future<TenantAdminAccountProfile> createAccountProfile({
    required String accountId,
    required String profileType,
    required String displayName,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm> taxonomyTerms = const [],
    String? bio,
    String? avatarUrl,
    String? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    lastCreatedTerms = taxonomyTerms;
    return TenantAdminAccountProfile(
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
    required String accountProfileId,
    String? profileType,
    String? displayName,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm>? taxonomyTerms,
    String? bio,
    String? avatarUrl,
    String? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    return TenantAdminAccountProfile(
      id: accountProfileId,
      accountId: 'account-1',
      profileType: profileType ?? 'artist',
      displayName: displayName ?? 'Perfil',
      taxonomyTerms: taxonomyTerms ?? const [],
      location: location,
      bio: bio,
      avatarUrl: avatarUrl,
      coverUrl: coverUrl,
    );
  }

  @override
  Future<void> deleteAccountProfile(String accountProfileId) async {}

  @override
  Future<TenantAdminAccountProfile> restoreAccountProfile(
    String accountProfileId,
  ) async {
    return const TenantAdminAccountProfile(
      id: 'profile-1',
      accountId: 'account-1',
      profileType: 'artist',
      displayName: 'Perfil',
    );
  }

  @override
  Future<void> forceDeleteAccountProfile(String accountProfileId) async {}

  @override
  Future<TenantAdminProfileTypeDefinition> createProfileType({
    required String type,
    required String label,
    List<String> allowedTaxonomies = const [],
    required TenantAdminProfileTypeCapabilities capabilities,
  }) async {
    return TenantAdminProfileTypeDefinition(
      type: type,
      label: label,
      allowedTaxonomies: allowedTaxonomies,
      capabilities: capabilities,
    );
  }

  @override
  Future<TenantAdminProfileTypeDefinition> updateProfileType({
    required String type,
    String? label,
    List<String>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
  }) async {
    return TenantAdminProfileTypeDefinition(
      type: type,
      label: label ?? 'Artista',
      allowedTaxonomies: allowedTaxonomies ?? const ['music_genre'],
      capabilities: capabilities ??
          const TenantAdminProfileTypeCapabilities(
            isFavoritable: true,
            isPoiEnabled: false,
            hasBio: false,
            hasTaxonomies: true,
            hasAvatar: false,
            hasCover: false,
            hasEvents: false,
          ),
    );
  }

  @override
  Future<void> deleteProfileType(String type) async {}
}

class _FakeTaxonomiesRepository
    implements TenantAdminTaxonomiesRepositoryContract {
  final List<TenantAdminTaxonomyDefinition> _taxonomies = [];
  final Map<String, List<TenantAdminTaxonomyTermDefinition>> _terms = {};

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
    required int page,
    required int pageSize,
  }) async {
    final taxonomies = await fetchTaxonomies();
    final start = (page - 1) * pageSize;
    if (page <= 0 || pageSize <= 0 || start >= taxonomies.length) {
      return const TenantAdminPagedResult<TenantAdminTaxonomyDefinition>(
        items: <TenantAdminTaxonomyDefinition>[],
        hasMore: false,
      );
    }
    final end = start + pageSize < taxonomies.length
        ? start + pageSize
        : taxonomies.length;
    return TenantAdminPagedResult<TenantAdminTaxonomyDefinition>(
      items: taxonomies.sublist(start, end),
      hasMore: end < taxonomies.length,
    );
  }

  @override
  Future<TenantAdminTaxonomyDefinition> createTaxonomy({
    required String slug,
    required String name,
    required List<String> appliesTo,
    String? icon,
    String? color,
  }) async {
    final taxonomy = TenantAdminTaxonomyDefinition(
      id: 'tax-${_taxonomies.length + 1}',
      slug: slug,
      name: name,
      appliesTo: List.of(appliesTo),
      icon: icon,
      color: color,
    );
    _taxonomies.add(taxonomy);
    _terms.putIfAbsent(taxonomy.id, () => []);
    return taxonomy;
  }

  @override
  Future<TenantAdminTaxonomyDefinition> updateTaxonomy({
    required String taxonomyId,
    String? slug,
    String? name,
    List<String>? appliesTo,
    String? icon,
    String? color,
  }) async {
    final index = _taxonomies.indexWhere((item) => item.id == taxonomyId);
    if (index == -1) {
      throw Exception('Taxonomy not found');
    }
    final existing = _taxonomies[index];
    final updated = TenantAdminTaxonomyDefinition(
      id: taxonomyId,
      slug: slug ?? existing.slug,
      name: name ?? existing.name,
      appliesTo: appliesTo ?? existing.appliesTo,
      icon: icon ?? existing.icon,
      color: color ?? existing.color,
    );
    _taxonomies[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteTaxonomy(String taxonomyId) async {
    _taxonomies.removeWhere((item) => item.id == taxonomyId);
    _terms.remove(taxonomyId);
  }

  @override
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required String taxonomyId,
  }) async {
    return List.of(_terms[taxonomyId] ?? const []);
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyTermDefinition>>
      fetchTermsPage({
    required String taxonomyId,
    required int page,
    required int pageSize,
  }) async {
    final terms = await fetchTerms(taxonomyId: taxonomyId);
    final start = (page - 1) * pageSize;
    if (page <= 0 || pageSize <= 0 || start >= terms.length) {
      return const TenantAdminPagedResult<TenantAdminTaxonomyTermDefinition>(
        items: <TenantAdminTaxonomyTermDefinition>[],
        hasMore: false,
      );
    }
    final end =
        start + pageSize < terms.length ? start + pageSize : terms.length;
    return TenantAdminPagedResult<TenantAdminTaxonomyTermDefinition>(
      items: terms.sublist(start, end),
      hasMore: end < terms.length,
    );
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> createTerm({
    required String taxonomyId,
    required String slug,
    required String name,
  }) async {
    final list = _terms.putIfAbsent(taxonomyId, () => []);
    final term = TenantAdminTaxonomyTermDefinition(
      id: 'term-${list.length + 1}',
      taxonomyId: taxonomyId,
      slug: slug,
      name: name,
    );
    list.add(term);
    return term;
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> updateTerm({
    required String taxonomyId,
    required String termId,
    String? slug,
    String? name,
  }) async {
    final list = _terms[taxonomyId] ?? [];
    final index = list.indexWhere((term) => term.id == termId);
    if (index == -1) {
      throw Exception('Term not found');
    }
    final existing = list[index];
    final updated = TenantAdminTaxonomyTermDefinition(
      id: termId,
      taxonomyId: taxonomyId,
      slug: slug ?? existing.slug,
      name: name ?? existing.name,
    );
    list[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteTerm({
    required String taxonomyId,
    required String termId,
  }) async {
    final list = _terms[taxonomyId];
    list?.removeWhere((term) => term.id == termId);
  }
}
