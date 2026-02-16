import 'package:belluga_now/application/application.dart';
import 'package:belluga_now/application/application_contract.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_tenants_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_static_assets_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_asset.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/infrastructure/dal/dao/account_profiles_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/auth_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/favorite_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/venue_event_backend_contract.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';
import 'support/fake_landlord_app_data_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/local/app_data_local_info_source/app_data_local_info_source_stub.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
    final end = DateTime.now().add(duration);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> _waitForFinder(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 200));
      if (finder.evaluate().isNotEmpty) {
        return;
      }
    }
    throw TestFailure(
      'Timed out waiting for ${finder.describeMatch(Plurality.one)}.',
    );
  }

  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  Finder _tenantAdminShellRouterFinder() {
    return find.byWidgetPredicate((widget) {
      final key = widget.key;
      if (key is! ValueKey<String>) {
        return false;
      }
      return key.value.startsWith('tenant-admin-shell-router-');
    });
  }

  testWidgets('Admin static asset create flow', (tester) async {
    if (GetIt.I.isRegistered<ApplicationContract>()) {
      GetIt.I.unregister<ApplicationContract>();
    }
    if (GetIt.I.isRegistered<AppDataRepositoryContract>()) {
      GetIt.I.unregister<AppDataRepositoryContract>();
    }
    if (GetIt.I.isRegistered<AppDataRepository>()) {
      GetIt.I.unregister<AppDataRepository>();
    }
    if (GetIt.I.isRegistered<AdminModeRepositoryContract>()) {
      GetIt.I.unregister<AdminModeRepositoryContract>();
    }
    if (GetIt.I.isRegistered<AuthRepositoryContract<UserContract>>()) {
      GetIt.I.unregister<AuthRepositoryContract<UserContract>>();
    }
    if (GetIt.I.isRegistered<LandlordAuthRepositoryContract>()) {
      GetIt.I.unregister<LandlordAuthRepositoryContract>();
    }
    if (GetIt.I.isRegistered<LandlordTenantsRepositoryContract>()) {
      GetIt.I.unregister<LandlordTenantsRepositoryContract>();
    }
    if (GetIt.I.isRegistered<TenantAdminStaticAssetsRepositoryContract>()) {
      GetIt.I.unregister<TenantAdminStaticAssetsRepositoryContract>();
    }
    if (GetIt.I.isRegistered<TenantAdminTaxonomiesRepositoryContract>()) {
      GetIt.I.unregister<TenantAdminTaxonomiesRepositoryContract>();
    }

    GetIt.I.registerSingleton<AppDataRepositoryContract>(
      AppDataRepository(
        backend: const FakeLandlordAppDataBackend(),
        localInfoSource: AppDataLocalInfoSource(),
      ),
    );
    GetIt.I.registerSingleton<AdminModeRepositoryContract>(
      _FakeAdminModeRepository(AdminMode.landlord),
    );
    GetIt.I.registerSingleton<AuthRepositoryContract<UserContract>>(
      _FakeAuthRepository(),
    );
    GetIt.I.registerSingleton<LandlordAuthRepositoryContract>(
      _FakeLandlordAuthRepository(hasValidSession: true),
    );
    GetIt.I.registerSingleton<LandlordTenantsRepositoryContract>(
      _FakeLandlordTenantsRepository(),
    );
    final staticAssetsRepository = _FakeStaticAssetsRepository();
    GetIt.I.registerSingleton<TenantAdminStaticAssetsRepositoryContract>(
      staticAssetsRepository,
    );
    GetIt.I.registerSingleton<TenantAdminTaxonomiesRepositoryContract>(
      _FakeTaxonomiesRepository(),
    );

    final app = Application();
    GetIt.I.registerSingleton<ApplicationContract>(app);
    await app.init();

    app.appRouter.replaceAll([
      const TenantAdminShellRoute(
        children: [TenantAdminStaticAssetCreateRoute()],
      ),
    ]);

    await tester.pumpWidget(app);
    await _pumpFor(tester, const Duration(seconds: 2));
    await _waitForFinder(tester, _tenantAdminShellRouterFinder());
    app.appRouter.navigate(
      const TenantAdminShellRoute(
        children: [TenantAdminStaticAssetCreateRoute()],
      ),
    );
    await _pumpFor(tester, const Duration(seconds: 2));

    await _waitForFinder(tester, find.text('Criar ativo'));

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Praia').last);
    await tester.pumpAndSettle();

    expect(find.text('Tags'), findsNothing);
    expect(find.text('Categorias'), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome de exibicao'),
      'Praia do Morro',
    );
    final urbanaOption = find.text('Urbana').last;
    await _waitForFinder(tester, urbanaOption);
    await tester.ensureVisible(urbanaOption);
    await tester.tap(urbanaOption, warnIfMissed: false);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Latitude'),
      '-20.659900',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Longitude'),
      '-40.503300',
    );

    final saveButton = find.text('Salvar ativo');
    await _waitForFinder(tester, saveButton);
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    await _waitForFinder(tester, find.text('Ativo criado.'));
    expect(staticAssetsRepository.createdAssets.length, 1);
  });

  testWidgets('Admin static assets list applies search and type filters', (
    tester,
  ) async {
    if (GetIt.I.isRegistered<ApplicationContract>()) {
      GetIt.I.unregister<ApplicationContract>();
    }
    if (GetIt.I.isRegistered<AppDataRepositoryContract>()) {
      GetIt.I.unregister<AppDataRepositoryContract>();
    }
    if (GetIt.I.isRegistered<AppDataRepository>()) {
      GetIt.I.unregister<AppDataRepository>();
    }
    if (GetIt.I.isRegistered<AdminModeRepositoryContract>()) {
      GetIt.I.unregister<AdminModeRepositoryContract>();
    }
    if (GetIt.I.isRegistered<AuthRepositoryContract<UserContract>>()) {
      GetIt.I.unregister<AuthRepositoryContract<UserContract>>();
    }
    if (GetIt.I.isRegistered<LandlordAuthRepositoryContract>()) {
      GetIt.I.unregister<LandlordAuthRepositoryContract>();
    }
    if (GetIt.I.isRegistered<LandlordTenantsRepositoryContract>()) {
      GetIt.I.unregister<LandlordTenantsRepositoryContract>();
    }
    if (GetIt.I.isRegistered<TenantAdminStaticAssetsRepositoryContract>()) {
      GetIt.I.unregister<TenantAdminStaticAssetsRepositoryContract>();
    }
    if (GetIt.I.isRegistered<TenantAdminTaxonomiesRepositoryContract>()) {
      GetIt.I.unregister<TenantAdminTaxonomiesRepositoryContract>();
    }

    GetIt.I.registerSingleton<AppDataRepositoryContract>(
      AppDataRepository(
        backend: const FakeLandlordAppDataBackend(),
        localInfoSource: AppDataLocalInfoSource(),
      ),
    );
    GetIt.I.registerSingleton<AdminModeRepositoryContract>(
      _FakeAdminModeRepository(AdminMode.landlord),
    );
    GetIt.I.registerSingleton<AuthRepositoryContract<UserContract>>(
      _FakeAuthRepository(),
    );
    GetIt.I.registerSingleton<LandlordAuthRepositoryContract>(
      _FakeLandlordAuthRepository(hasValidSession: true),
    );
    GetIt.I.registerSingleton<LandlordTenantsRepositoryContract>(
      _FakeLandlordTenantsRepository(),
    );
    final staticAssetsRepository = _FakeStaticAssetsRepository(
      seededAssets: const [
        TenantAdminStaticAsset(
          id: 'asset-1',
          profileType: 'beach',
          displayName: 'Praia do Morro',
          slug: 'praia-do-morro',
          isActive: true,
        ),
        TenantAdminStaticAsset(
          id: 'asset-2',
          profileType: 'museum',
          displayName: 'Museu Vale',
          slug: 'museu-vale',
          isActive: true,
        ),
      ],
    );
    GetIt.I.registerSingleton<TenantAdminStaticAssetsRepositoryContract>(
      staticAssetsRepository,
    );
    GetIt.I.registerSingleton<TenantAdminTaxonomiesRepositoryContract>(
      _FakeTaxonomiesRepository(),
    );

    final app = Application();
    GetIt.I.registerSingleton<ApplicationContract>(app);
    await app.init();

    app.appRouter.replaceAll([
      const TenantAdminShellRoute(
        children: [TenantAdminStaticAssetsListRoute()],
      ),
    ]);

    await tester.pumpWidget(app);
    await _pumpFor(tester, const Duration(seconds: 2));
    await _waitForFinder(tester, _tenantAdminShellRouterFinder());
    app.appRouter.navigate(
      const TenantAdminShellRoute(
        children: [TenantAdminStaticAssetsListRoute()],
      ),
    );
    await _pumpFor(tester, const Duration(seconds: 2));

    await _waitForFinder(tester, find.text('Ativos estaticos'));
    await _waitForFinder(tester, find.text('Praia do Morro'));
    await _waitForFinder(tester, find.text('Museu Vale'));

    final typeFilterDropdown = find.byType(DropdownButtonFormField<String?>);
    await _waitForFinder(tester, typeFilterDropdown);
    await tester.tap(typeFilterDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('beach').last);
    await tester.pumpAndSettle();

    expect(find.text('Praia do Morro'), findsOneWidget);
    expect(find.text('Museu Vale'), findsNothing);

    await tester.tap(typeFilterDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Todos os tipos').last);
    await tester.pumpAndSettle();

    expect(find.text('Praia do Morro'), findsOneWidget);
    expect(find.text('Museu Vale'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Buscar por nome ou slug'),
      'museu',
    );
    await tester.pumpAndSettle();

    expect(find.text('Praia do Morro'), findsNothing);
    expect(find.text('Museu Vale'), findsOneWidget);
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

class _FakeAuthRepository extends AuthRepositoryContract<UserContract> {
  @override
  BackendContract get backend => _NoopBackend();

  @override
  String get userToken => '';

  @override
  void setUserToken(String? token) {}

  @override
  Future<String> getDeviceId() async => 'integration-device';

  @override
  Future<String?> getUserId() async => null;

  @override
  bool get isUserLoggedIn => false;

  @override
  bool get isAuthorized => false;

  @override
  Future<void> init() async {}

  @override
  Future<void> autoLogin() async {}

  @override
  Future<void> loginWithEmailPassword(String email, String password) async {}

  @override
  Future<void> signUpWithEmailPassword(
    String name,
    String email,
    String password,
  ) async {}

  @override
  Future<void> sendTokenRecoveryPassword(
    String email,
    String codigoEnviado,
  ) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> createNewPassword(
    String newPassword,
    String confirmPassword,
  ) async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> updateUser(Map<String, Object?> data) async {}
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

class _NoopBackend extends BackendContract {
  BackendContext? _context;

  @override
  BackendContext? get context => _context;

  @override
  void setContext(BackendContext context) {
    _context = context;
  }

  @override
  AppDataBackendContract get appData => throw UnimplementedError();

  @override
  AuthBackendContract get auth => throw UnimplementedError();

  @override
  TenantBackendContract get tenant => throw UnimplementedError();

  @override
  AccountProfilesBackendContract get accountProfiles =>
      throw UnimplementedError();

  @override
  FavoriteBackendContract get favorites => throw UnimplementedError();

  @override
  VenueEventBackendContract get venueEvents => throw UnimplementedError();

  @override
  ScheduleBackendContract get schedule => throw UnimplementedError();
}

class _FakeStaticAssetsRepository
    with TenantAdminStaticAssetsPaginationMixin
    implements TenantAdminStaticAssetsRepositoryContract {
  _FakeStaticAssetsRepository({
    List<TenantAdminStaticAsset> seededAssets = const [],
  }) : _assets = List<TenantAdminStaticAsset>.of(seededAssets);

  final List<TenantAdminStaticAsset> createdAssets = [];
  final List<TenantAdminStaticAsset> _assets;

  @override
  Future<List<TenantAdminStaticAsset>> fetchStaticAssets() async =>
      List<TenantAdminStaticAsset>.unmodifiable(_assets);

  @override
  Future<TenantAdminPagedResult<TenantAdminStaticAsset>> fetchStaticAssetsPage({
    required int page,
    required int pageSize,
  }) async {
    final assets = await fetchStaticAssets();
    final start = (page - 1) * pageSize;
    if (page <= 0 || pageSize <= 0 || start >= assets.length) {
      return const TenantAdminPagedResult<TenantAdminStaticAsset>(
        items: <TenantAdminStaticAsset>[],
        hasMore: false,
      );
    }
    final end =
        start + pageSize < assets.length ? start + pageSize : assets.length;
    return TenantAdminPagedResult<TenantAdminStaticAsset>(
      items: assets.sublist(start, end),
      hasMore: end < assets.length,
    );
  }

  @override
  Future<TenantAdminStaticAsset> fetchStaticAsset(String assetId) async {
    for (final asset in _assets) {
      if (asset.id == assetId) {
        return asset;
      }
    }
    return TenantAdminStaticAsset(
      id: assetId,
      profileType: 'beach',
      displayName: 'Praia',
      slug: 'praia',
      isActive: true,
    );
  }

  @override
  Future<TenantAdminStaticAsset> createStaticAsset({
    required String profileType,
    required String displayName,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm> taxonomyTerms = const [],
    List<String> tags = const [],
    String? bio,
    String? content,
    String? avatarUrl,
    String? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    final asset = TenantAdminStaticAsset(
      id: 'asset-1',
      profileType: profileType,
      displayName: displayName,
      slug: 'asset-1',
      isActive: true,
      location: location,
      taxonomyTerms: taxonomyTerms,
      tags: tags,
      bio: bio,
      content: content,
      avatarUrl: avatarUrl,
      coverUrl: coverUrl,
    );
    createdAssets.add(asset);
    _assets.add(asset);
    return asset;
  }

  @override
  Future<TenantAdminStaticAsset> updateStaticAsset({
    required String assetId,
    String? profileType,
    String? displayName,
    String? slug,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm>? taxonomyTerms,
    List<String>? tags,
    String? bio,
    String? content,
    String? avatarUrl,
    String? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    final updated = TenantAdminStaticAsset(
      id: assetId,
      profileType: profileType ?? 'beach',
      displayName: displayName ?? 'Praia',
      slug: 'praia',
      isActive: true,
      location: location,
      taxonomyTerms: taxonomyTerms ?? const [],
      tags: tags ?? const [],
      bio: bio,
      content: content,
      avatarUrl: avatarUrl,
      coverUrl: coverUrl,
    );
    final index = _assets.indexWhere((asset) => asset.id == assetId);
    if (index >= 0) {
      _assets[index] = updated;
    }
    return updated;
  }

  @override
  Future<void> deleteStaticAsset(String assetId) async {}

  @override
  Future<TenantAdminStaticAsset> restoreStaticAsset(String assetId) async {
    return TenantAdminStaticAsset(
      id: assetId,
      profileType: 'beach',
      displayName: 'Praia',
      slug: 'praia',
      isActive: true,
    );
  }

  @override
  Future<void> forceDeleteStaticAsset(String assetId) async {}

  @override
  Future<List<TenantAdminStaticProfileTypeDefinition>>
      fetchStaticProfileTypes() async {
    return const [
      TenantAdminStaticProfileTypeDefinition(
        type: 'beach',
        label: 'Praia',
        allowedTaxonomies: ['beach_style'],
        capabilities: TenantAdminStaticProfileTypeCapabilities(
          isPoiEnabled: true,
          hasBio: true,
          hasTaxonomies: true,
          hasAvatar: true,
          hasCover: true,
          hasContent: true,
        ),
      ),
    ];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminStaticProfileTypeDefinition>>
      fetchStaticProfileTypesPage({
    required int page,
    required int pageSize,
  }) async {
    final profileTypes = await fetchStaticProfileTypes();
    final start = (page - 1) * pageSize;
    if (page <= 0 || pageSize <= 0 || start >= profileTypes.length) {
      return const TenantAdminPagedResult<
          TenantAdminStaticProfileTypeDefinition>(
        items: <TenantAdminStaticProfileTypeDefinition>[],
        hasMore: false,
      );
    }
    final end = start + pageSize < profileTypes.length
        ? start + pageSize
        : profileTypes.length;
    return TenantAdminPagedResult<TenantAdminStaticProfileTypeDefinition>(
      items: profileTypes.sublist(start, end),
      hasMore: end < profileTypes.length,
    );
  }

  @override
  Future<TenantAdminStaticProfileTypeDefinition> createStaticProfileType({
    required String type,
    required String label,
    List<String> allowedTaxonomies = const [],
    required TenantAdminStaticProfileTypeCapabilities capabilities,
  }) async {
    return TenantAdminStaticProfileTypeDefinition(
      type: type,
      label: label,
      allowedTaxonomies: allowedTaxonomies,
      capabilities: capabilities,
    );
  }

  @override
  Future<TenantAdminStaticProfileTypeDefinition> updateStaticProfileType({
    required String type,
    String? newType,
    String? label,
    List<String>? allowedTaxonomies,
    TenantAdminStaticProfileTypeCapabilities? capabilities,
  }) async {
    return TenantAdminStaticProfileTypeDefinition(
      type: type,
      label: label ?? 'Praia',
      allowedTaxonomies: allowedTaxonomies ?? const [],
      capabilities: capabilities ??
          const TenantAdminStaticProfileTypeCapabilities(
            isPoiEnabled: true,
            hasBio: true,
            hasTaxonomies: true,
            hasAvatar: true,
            hasCover: true,
            hasContent: true,
          ),
    );
  }

  @override
  Future<void> deleteStaticProfileType(String type) async {}
}

class _FakeTaxonomiesRepository
    with TenantAdminTaxonomiesPaginationMixin
    implements TenantAdminTaxonomiesRepositoryContract {
  @override
  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomies() async {
    return const [
      TenantAdminTaxonomyDefinition(
        id: 'taxonomy-1',
        slug: 'beach_style',
        name: 'Estilo da praia',
        appliesTo: ['static_asset'],
        icon: null,
        color: null,
      ),
    ];
  }

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
    return TenantAdminTaxonomyDefinition(
      id: 'taxonomy-2',
      slug: slug,
      name: name,
      appliesTo: appliesTo,
      icon: icon,
      color: color,
    );
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
    return TenantAdminTaxonomyDefinition(
      id: taxonomyId,
      slug: slug ?? 'beach_style',
      name: name ?? 'Estilo da praia',
      appliesTo: appliesTo ?? const ['static_asset'],
      icon: icon,
      color: color,
    );
  }

  @override
  Future<void> deleteTaxonomy(String taxonomyId) async {}

  @override
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required String taxonomyId,
  }) async {
    return const [
      TenantAdminTaxonomyTermDefinition(
        id: 'term-1',
        taxonomyId: 'taxonomy-1',
        slug: 'urbana',
        name: 'Urbana',
      ),
    ];
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
    return TenantAdminTaxonomyTermDefinition(
      id: 'term-2',
      taxonomyId: taxonomyId,
      slug: slug,
      name: name,
    );
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> updateTerm({
    required String taxonomyId,
    required String termId,
    String? slug,
    String? name,
  }) async {
    return TenantAdminTaxonomyTermDefinition(
      id: termId,
      taxonomyId: taxonomyId,
      slug: slug ?? 'urbana',
      name: name ?? 'Urbana',
    );
  }

  @override
  Future<void> deleteTerm({
    required String taxonomyId,
    required String termId,
  }) async {}
}
