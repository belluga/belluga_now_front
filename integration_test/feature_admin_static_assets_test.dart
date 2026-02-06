import 'package:belluga_now/application/application.dart';
import 'package:belluga_now/application/application_contract.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_static_assets_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
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
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/app_data_backend/app_data_backend_stub.dart';
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

  testWidgets('Admin static asset create flow', (tester) async {
    if (GetIt.I.isRegistered<ApplicationContract>()) {
      GetIt.I.unregister<ApplicationContract>();
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
    if (GetIt.I
        .isRegistered<TenantAdminStaticAssetsRepositoryContract>()) {
      GetIt.I.unregister<TenantAdminStaticAssetsRepositoryContract>();
    }
    if (GetIt.I.isRegistered<TenantAdminTaxonomiesRepositoryContract>()) {
      GetIt.I.unregister<TenantAdminTaxonomiesRepositoryContract>();
    }

    GetIt.I.registerSingleton<AppDataRepository>(
      AppDataRepository(
        backend: AppDataBackend(),
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

    await _waitForFinder(tester, find.text('Criar ativo'));

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Praia').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Praia do Morro',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'praia-do-morro',
    );

    await tester.tap(find.text('Urbana'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(8),
      '-20.659900',
    );
    await tester.enterText(
      find.byType(TextFormField).at(9),
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
  AccountProfilesBackendContract get accountProfiles => throw UnimplementedError();

  @override
  FavoriteBackendContract get favorites => throw UnimplementedError();

  @override
  VenueEventBackendContract get venueEvents => throw UnimplementedError();

  @override
  ScheduleBackendContract get schedule => throw UnimplementedError();
}

class _FakeStaticAssetsRepository
    implements TenantAdminStaticAssetsRepositoryContract {
  final List<TenantAdminStaticAsset> createdAssets = [];

  @override
  Future<List<TenantAdminStaticAsset>> fetchStaticAssets() async => const [];

  @override
  Future<TenantAdminStaticAsset> fetchStaticAsset(String assetId) async {
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
    required String slug,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm> taxonomyTerms = const [],
    List<String> tags = const [],
    List<String> categories = const [],
    String? bio,
    String? content,
    String? avatarUrl,
    String? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
    required bool isActive,
  }) async {
    final asset = TenantAdminStaticAsset(
      id: 'asset-1',
      profileType: profileType,
      displayName: displayName,
      slug: slug,
      isActive: isActive,
      location: location,
      taxonomyTerms: taxonomyTerms,
      tags: tags,
      categories: categories,
      bio: bio,
      content: content,
      avatarUrl: avatarUrl,
      coverUrl: coverUrl,
    );
    createdAssets.add(asset);
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
    List<String>? categories,
    String? bio,
    String? content,
    String? avatarUrl,
    String? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
    bool? isActive,
  }) async {
    return TenantAdminStaticAsset(
      id: assetId,
      profileType: profileType ?? 'beach',
      displayName: displayName ?? 'Praia',
      slug: slug ?? 'praia',
      isActive: isActive ?? true,
      location: location,
      taxonomyTerms: taxonomyTerms ?? const [],
      tags: tags ?? const [],
      categories: categories ?? const [],
      bio: bio,
      content: content,
      avatarUrl: avatarUrl,
      coverUrl: coverUrl,
    );
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

}

class _FakeTaxonomiesRepository
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
