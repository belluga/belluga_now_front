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
import 'package:belluga_now/infrastructure/platform/app_data_local_info_source/app_data_local_info_source.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:belluga_now/presentation/shared/widgets/belluga_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const ValueKey<String> staticAssetsSearchToggleKey =
      ValueKey<String>('tenant_admin_assets_search_toggle');
  const ValueKey<String> staticAssetsSearchFieldKey =
      ValueKey<String>('tenant_admin_assets_search_field');

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
      TenantAdminShellRoute(
        children: [TenantAdminStaticAssetCreateRoute()],
      ),
    ]);

    await tester.pumpWidget(app);
    await _pumpFor(tester, const Duration(seconds: 2));
    await _waitForFinder(tester, _tenantAdminShellRouterFinder());
    app.appRouter.navigate(
      TenantAdminShellRoute(
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
      seededAssets: [
        tenantAdminStaticAssetFromRaw(
          id: 'asset-1',
          profileType: 'beach',
          displayName: 'Praia do Morro',
          slug: 'praia-do-morro',
          isActive: true,
        ),
        tenantAdminStaticAssetFromRaw(
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
      TenantAdminShellRoute(
        children: [TenantAdminStaticAssetsListRoute()],
      ),
    ]);

    await tester.pumpWidget(app);
    await _pumpFor(tester, const Duration(seconds: 2));
    await _waitForFinder(tester, _tenantAdminShellRouterFinder());
    app.appRouter.navigate(
      TenantAdminShellRoute(
        children: [TenantAdminStaticAssetsListRoute()],
      ),
    );
    await _pumpFor(tester, const Duration(seconds: 2));

    await _waitForFinder(tester, find.byKey(staticAssetsSearchToggleKey));
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

    await tester.tap(find.byKey(staticAssetsSearchToggleKey));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(staticAssetsSearchFieldKey),
      'museu',
    );
    await tester.pumpAndSettle();

    expect(find.text('Praia do Morro'), findsNothing);
    expect(find.text('Museu Vale'), findsOneWidget);
  });

  testWidgets('Admin static asset edit renders persisted media URLs', (
    tester,
  ) async {
    const avatarUrl = 'https://tenant-a.test/media/static-assets/avatar.png';
    const coverUrl = 'https://tenant-a.test/media/static-assets/cover.png';
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
    GetIt.I.registerSingleton<TenantAdminStaticAssetsRepositoryContract>(
      _FakeStaticAssetsRepository(
        seededAssets: [
          tenantAdminStaticAssetFromRaw(
            id: 'asset-1',
            profileType: 'beach',
            displayName: 'Praia do Morro',
            slug: 'praia-do-morro',
            isActive: true,
            avatarUrl: avatarUrl,
            coverUrl: coverUrl,
          ),
        ],
      ),
    );
    GetIt.I.registerSingleton<TenantAdminTaxonomiesRepositoryContract>(
      _FakeTaxonomiesRepository(),
    );

    final app = Application();
    GetIt.I.registerSingleton<ApplicationContract>(app);
    await app.init();

    app.appRouter.replaceAll([
      TenantAdminShellRoute(
        children: [TenantAdminStaticAssetEditRoute(assetId: 'asset-1')],
      ),
    ]);

    await tester.pumpWidget(app);
    await _pumpFor(tester, const Duration(seconds: 2));
    await _waitForFinder(tester, _tenantAdminShellRouterFinder());
    app.appRouter.navigate(
      TenantAdminShellRoute(
        children: [TenantAdminStaticAssetEditRoute(assetId: 'asset-1')],
      ),
    );
    await _pumpFor(tester, const Duration(seconds: 2));
    await _waitForFinder(tester, find.text('Editar ativo'));

    final avatarImageFinder = find.byWidgetPredicate((widget) {
      return widget is BellugaNetworkImage && widget.url == avatarUrl;
    });
    final coverImageFinder = find.byWidgetPredicate((widget) {
      return widget is BellugaNetworkImage && widget.url == coverUrl;
    });
    expect(avatarImageFinder, findsOneWidget);
    expect(coverImageFinder, findsOneWidget);
  });

  testWidgets('Admin static assets list cards render persisted media URLs', (
    tester,
  ) async {
    const avatarUrl = 'https://tenant-a.test/media/static-assets/avatar.png';
    const coverUrl = 'https://tenant-a.test/media/static-assets/cover.png';
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
    GetIt.I.registerSingleton<TenantAdminStaticAssetsRepositoryContract>(
      _FakeStaticAssetsRepository(
        seededAssets: [
          tenantAdminStaticAssetFromRaw(
            id: 'asset-1',
            profileType: 'beach',
            displayName: 'Praia do Morro',
            slug: 'praia-do-morro',
            isActive: true,
            avatarUrl: avatarUrl,
            coverUrl: coverUrl,
          ),
        ],
      ),
    );
    GetIt.I.registerSingleton<TenantAdminTaxonomiesRepositoryContract>(
      _FakeTaxonomiesRepository(),
    );

    final app = Application();
    GetIt.I.registerSingleton<ApplicationContract>(app);
    await app.init();

    app.appRouter.replaceAll([
      TenantAdminShellRoute(
        children: [TenantAdminStaticAssetsListRoute()],
      ),
    ]);

    await tester.pumpWidget(app);
    await _pumpFor(tester, const Duration(seconds: 2));
    await _waitForFinder(tester, _tenantAdminShellRouterFinder());
    app.appRouter.navigate(
      TenantAdminShellRoute(
        children: [TenantAdminStaticAssetsListRoute()],
      ),
    );
    await _pumpFor(tester, const Duration(seconds: 2));
    await _waitForFinder(tester, find.text('Praia do Morro'));

    final coverImageFinder = find.byWidgetPredicate((widget) {
      return widget is BellugaNetworkImage && widget.url == coverUrl;
    });
    final avatarImageFinder = find.byWidgetPredicate((widget) {
      return widget is BellugaNetworkImage && widget.url == avatarUrl;
    });
    expect(coverImageFinder, findsOneWidget);
    expect(avatarImageFinder, findsOneWidget);
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
    LandlordAuthRepositoryContractPrimString password,
  ) async {}

  @override
  Future<void> logout() async {}
}

class _FakeAuthRepository extends AuthRepositoryContract<UserContract> {
  @override
  BackendContract get backend => _NoopBackend();

  @override
  String get userToken => '';

  @override
  void setUserToken(AuthRepositoryContractParamString? token) {}

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
  Future<void> loginWithEmailPassword(AuthRepositoryContractParamString email,
      AuthRepositoryContractParamString password) async {}

  @override
  Future<void> signUpWithEmailPassword(
    AuthRepositoryContractParamString name,
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  ) async {}

  @override
  Future<void> sendTokenRecoveryPassword(
      AuthRepositoryContractParamString email,
      AuthRepositoryContractParamString codigoEnviado) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> createNewPassword(
    AuthRepositoryContractParamString newPassword,
    AuthRepositoryContractParamString confirmPassword,
  ) async {}

  @override
  Future<void> sendPasswordResetEmail(
      AuthRepositoryContractParamString email) async {}

  @override
  Future<void> updateUser(
      UserCustomData data) async {}
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

  static const String generatedAvatarUploadUrl =
      'https://tenant-a.test/media/static-assets/avatar-uploaded.png';
  static const String generatedCoverUploadUrl =
      'https://tenant-a.test/media/static-assets/cover-uploaded.png';

  final List<TenantAdminStaticAsset> createdAssets = const [];
  final List<TenantAdminStaticAsset> _assets;

  @override
  Future<List<TenantAdminStaticAsset>> fetchStaticAssets() async =>
      List<TenantAdminStaticAsset>.unmodifiable(_assets);

  @override
  Future<TenantAdminPagedResult<TenantAdminStaticAsset>> fetchStaticAssetsPage({
    required TenantAdminStaticAssetsRepoInt page,
    required TenantAdminStaticAssetsRepoInt pageSize,
  }) async {
    final assets = await fetchStaticAssets();
    final start = (page.value - 1) * pageSize.value;
    if (page.value <= 0 || pageSize.value <= 0 || start >= assets.length) {
      return tenantAdminPagedResultFromRaw(
        items: <TenantAdminStaticAsset>[],
        hasMore: false,
      );
    }
    final end = start + pageSize.value < assets.length
        ? start + pageSize.value
        : assets.length;
    return tenantAdminPagedResultFromRaw(
      items: assets.sublist(start, end),
      hasMore: end < assets.length,
    );
  }

  @override
  Future<TenantAdminStaticAsset> fetchStaticAsset(
    TenantAdminStaticAssetsRepoString assetId,
  ) async {
    for (final asset in _assets) {
      if (asset.id == assetId.value) {
        return asset;
      }
    }
    return tenantAdminStaticAssetFromRaw(
      id: assetId.value,
      profileType: 'beach',
      displayName: 'Praia',
      slug: 'praia',
      isActive: true,
    );
  }

  @override
  Future<TenantAdminStaticAsset> createStaticAsset({
    required TenantAdminStaticAssetsRepoString profileType,
    required TenantAdminStaticAssetsRepoString displayName,
    TenantAdminLocation? location,
    TenantAdminTaxonomyTerms taxonomyTerms =
        const TenantAdminTaxonomyTerms.empty(),
    TenantAdminStaticAssetsRepoString? bio,
    TenantAdminStaticAssetsRepoString? content,
    TenantAdminStaticAssetsRepoString? avatarUrl,
    TenantAdminStaticAssetsRepoString? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    final resolvedAvatarUrl =
        avatarUpload != null ? generatedAvatarUploadUrl : avatarUrl?.value;
    final resolvedCoverUrl =
        coverUpload != null ? generatedCoverUploadUrl : coverUrl?.value;
    final asset = tenantAdminStaticAssetFromRaw(
      id: 'asset-1',
      profileType: profileType.value,
      displayName: displayName.value,
      slug: 'asset-1',
      isActive: true,
      location: location,
      taxonomyTerms: taxonomyTerms,
      bio: bio?.value,
      content: content?.value,
      avatarUrl: resolvedAvatarUrl,
      coverUrl: resolvedCoverUrl,
    );
    createdAssets.add(asset);
    _assets.add(asset);
    return asset;
  }

  @override
  Future<TenantAdminStaticAsset> updateStaticAsset({
    required TenantAdminStaticAssetsRepoString assetId,
    TenantAdminStaticAssetsRepoString? profileType,
    TenantAdminStaticAssetsRepoString? displayName,
    TenantAdminStaticAssetsRepoString? slug,
    TenantAdminLocation? location,
    TenantAdminTaxonomyTerms? taxonomyTerms,
    TenantAdminStaticAssetsRepoString? bio,
    TenantAdminStaticAssetsRepoString? content,
    TenantAdminStaticAssetsRepoString? avatarUrl,
    TenantAdminStaticAssetsRepoString? coverUrl,
    TenantAdminStaticAssetsRepoBool? removeAvatar,
    TenantAdminStaticAssetsRepoBool? removeCover,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    TenantAdminStaticAsset? existing;
    for (final asset in _assets) {
      if (asset.id == assetId.value) {
        existing = asset;
        break;
      }
    }
    final resolvedAvatarUrl = avatarUpload != null
        ? generatedAvatarUploadUrl
        : avatarUrl?.value ?? existing?.avatarUrl;
    final resolvedCoverUrl = coverUpload != null
        ? generatedCoverUploadUrl
        : coverUrl?.value ?? existing?.coverUrl;
    final updated = tenantAdminStaticAssetFromRaw(
      id: assetId.value,
      profileType: profileType?.value ?? existing?.profileType ?? 'beach',
      displayName: displayName?.value ?? existing?.displayName ?? 'Praia',
      slug: slug?.value ?? existing?.slug ?? 'praia',
      isActive: true,
      location: location ?? existing?.location,
      taxonomyTerms: taxonomyTerms ?? existing?.taxonomyTerms ?? const TenantAdminTaxonomyTerms.empty(),
      bio: bio?.value ?? existing?.bio,
      content: content?.value ?? existing?.content,
      avatarUrl: resolvedAvatarUrl,
      coverUrl: resolvedCoverUrl,
    );
    final index = _assets.indexWhere((asset) => asset.id == assetId.value);
    if (index >= 0) {
      _assets[index] = updated;
    } else {
      _assets.add(updated);
    }
    return updated;
  }

  @override
  Future<void> deleteStaticAsset(
      TenantAdminStaticAssetsRepoString assetId) async {}

  @override
  Future<TenantAdminStaticAsset> restoreStaticAsset(
    TenantAdminStaticAssetsRepoString assetId,
  ) async {
    return tenantAdminStaticAssetFromRaw(
      id: assetId.value,
      profileType: 'beach',
      displayName: 'Praia',
      slug: 'praia',
      isActive: true,
    );
  }

  @override
  Future<void> forceDeleteStaticAsset(
    TenantAdminStaticAssetsRepoString assetId,
  ) async {}

  @override
  Future<List<TenantAdminStaticProfileTypeDefinition>>
      fetchStaticProfileTypes() async {
    return [
      tenantAdminStaticProfileTypeDefinitionFromRaw(
        type: 'beach',
        label: 'Praia',
        allowedTaxonomies: ['beach_style'],
        capabilities: TenantAdminStaticProfileTypeCapabilities(
          isPoiEnabled: TenantAdminFlagValue(true),
          hasBio: TenantAdminFlagValue(true),
          hasTaxonomies: TenantAdminFlagValue(true),
          hasAvatar: TenantAdminFlagValue(true),
          hasCover: TenantAdminFlagValue(true),
          hasContent: TenantAdminFlagValue(true),
        ),
      ),
    ];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminStaticProfileTypeDefinition>>
      fetchStaticProfileTypesPage({
    required TenantAdminStaticAssetsRepoInt page,
    required TenantAdminStaticAssetsRepoInt pageSize,
  }) async {
    final profileTypes = await fetchStaticProfileTypes();
    final start = (page.value - 1) * pageSize.value;
    if (page.value <= 0 ||
        pageSize.value <= 0 ||
        start >= profileTypes.length) {
      return tenantAdminPagedResultFromRaw(
        items: <TenantAdminStaticProfileTypeDefinition>[],
        hasMore: false,
      );
    }
    final end = start + pageSize.value < profileTypes.length
        ? start + pageSize.value
        : profileTypes.length;
    return tenantAdminPagedResultFromRaw(
      items: profileTypes.sublist(start, end),
      hasMore: end < profileTypes.length,
    );
  }

  @override
  Future<TenantAdminStaticProfileTypeDefinition> createStaticProfileType({
    required TenantAdminStaticAssetsRepoString type,
    required TenantAdminStaticAssetsRepoString label,
    List<TenantAdminStaticAssetsRepoString>? allowedTaxonomies,
    required TenantAdminStaticProfileTypeCapabilities capabilities,
  }) async {
    return tenantAdminStaticProfileTypeDefinitionFromRaw(
      type: type.value,
      label: label.value,
      allowedTaxonomies: allowedTaxonomies
              ?.map((entry) => entry.value)
              .toList(growable: false) ??
          const [],
      capabilities: capabilities,
    );
  }

  @override
  Future<TenantAdminStaticProfileTypeDefinition> updateStaticProfileType({
    required TenantAdminStaticAssetsRepoString type,
    TenantAdminStaticAssetsRepoString? newType,
    TenantAdminStaticAssetsRepoString? label,
    List<TenantAdminStaticAssetsRepoString>? allowedTaxonomies,
    TenantAdminStaticProfileTypeCapabilities? capabilities,
  }) async {
    return tenantAdminStaticProfileTypeDefinitionFromRaw(
      type: type.value,
      label: label?.value ?? 'Praia',
      allowedTaxonomies: allowedTaxonomies
              ?.map((entry) => entry.value)
              .toList(growable: false) ??
          const [],
      capabilities: capabilities ??
          TenantAdminStaticProfileTypeCapabilities(
            isPoiEnabled: TenantAdminFlagValue(true),
            hasBio: TenantAdminFlagValue(true),
            hasTaxonomies: TenantAdminFlagValue(true),
            hasAvatar: TenantAdminFlagValue(true),
            hasCover: TenantAdminFlagValue(true),
            hasContent: TenantAdminFlagValue(true),
          ),
    );
  }

  @override
  Future<void> deleteStaticProfileType(
    TenantAdminStaticAssetsRepoString type,
  ) async {}
}

class _FakeTaxonomiesRepository
    with TenantAdminTaxonomiesPaginationMixin
    implements TenantAdminTaxonomiesRepositoryContract {
  @override
  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomies() async {
    return [
      tenantAdminTaxonomyDefinitionFromRaw(
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
    return tenantAdminTaxonomyDefinitionFromRaw(
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
    required TenantAdminTaxRepoString taxonomyId,
    TenantAdminTaxRepoString? slug,
    TenantAdminTaxRepoString? name,
    List<TenantAdminTaxRepoString>? appliesTo,
    TenantAdminTaxRepoString? icon,
    TenantAdminTaxRepoString? color,
  }) async {
    return tenantAdminTaxonomyDefinitionFromRaw(
      id: taxonomyId,
      slug: slug ?? 'beach_style',
      name: name ?? 'Estilo da praia',
      appliesTo: appliesTo ?? ['static_asset'],
      icon: icon,
      color: color,
    );
  }

  @override
  Future<void> deleteTaxonomy(TenantAdminTaxRepoString taxonomyId) async {}

  @override
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required TenantAdminTaxRepoString taxonomyId,
  }) async {
    return [
      tenantAdminTaxonomyTermDefinitionFromRaw(
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
    return tenantAdminTaxonomyTermDefinitionFromRaw(
      id: 'term-2',
      taxonomyId: taxonomyId,
      slug: slug,
      name: name,
    );
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> updateTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString termId,
    TenantAdminTaxRepoString? slug,
    TenantAdminTaxRepoString? name,
  }) async {
    return tenantAdminTaxonomyTermDefinitionFromRaw(
      id: termId,
      taxonomyId: taxonomyId,
      slug: slug ?? 'urbana',
      name: name ?? 'Urbana',
    );
  }

  @override
  Future<void> deleteTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString termId,
  }) async {}
}
