import 'package:belluga_now/application/application.dart';
import 'package:belluga_now/application/application_contract.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
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

  testWidgets('Admin create account with POI location', (tester) async {
    if (GetIt.I.isRegistered<ApplicationContract>()) {
      GetIt.I.unregister<ApplicationContract>();
    }
    if (GetIt.I.isRegistered<AppDataRepository>()) {
      GetIt.I.unregister<AppDataRepository>();
    }
    if (GetIt.I.isRegistered<AdminModeRepositoryContract>()) {
      GetIt.I.unregister<AdminModeRepositoryContract>();
    }
    if (GetIt.I.isRegistered<LandlordAuthRepositoryContract>()) {
      GetIt.I.unregister<LandlordAuthRepositoryContract>();
    }
    if (GetIt.I.isRegistered<TenantAdminAccountsRepositoryContract>()) {
      GetIt.I.unregister<TenantAdminAccountsRepositoryContract>();
    }
    if (GetIt.I.isRegistered<TenantAdminAccountProfilesRepositoryContract>()) {
      GetIt.I.unregister<TenantAdminAccountProfilesRepositoryContract>();
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
    GetIt.I.registerSingleton<LandlordAuthRepositoryContract>(
      _FakeLandlordAuthRepository(hasValidSession: true),
    );
    GetIt.I.registerSingleton<TenantAdminAccountsRepositoryContract>(
      _FakeAccountsRepository(),
    );
    GetIt.I.registerSingleton<TenantAdminAccountProfilesRepositoryContract>(
      _FakeAccountProfilesRepository(),
    );

    final app = Application();
    GetIt.I.registerSingleton<ApplicationContract>(app);
    await app.init();

    app.appRouter.replaceAll([
      const TenantAdminShellRoute(
        children: [TenantAdminAccountCreateRoute()],
      ),
    ]);

    await tester.pumpWidget(app);
    await _pumpFor(tester, const Duration(seconds: 2));

    await _waitForFinder(tester, find.text('Criar Conta'));

    await tester.enterText(find.byType(TextFormField).at(0), 'Conta Teste');
    await tester.enterText(find.byType(TextFormField).at(1), 'cpf');
    await tester.enterText(find.byType(TextFormField).at(2), 'Perfil Teste');
    await tester.enterText(find.byType(TextFormField).at(3), '000');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Venue').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(4),
      '-20.673600',
    );
    await tester.enterText(
      find.byType(TextFormField).at(5),
      '-40.497600',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final saveButton = find.text('Salvar conta');
    await _waitForFinder(tester, saveButton);
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    await _waitForFinder(tester, find.text('Conta e perfil salvos.'));
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
  Future<TenantAdminAccount> createAccount({
    required String name,
    required TenantAdminDocument document,
    String? organizationId,
  }) async {
    return TenantAdminAccount(
      id: 'acc-1',
      name: name,
      slug: 'acc-1',
      document: document,
      ownershipState: TenantAdminOwnershipState.tenantOwned,
      organizationId: organizationId,
    );
  }

  @override
  Future<void> deleteAccount(String accountSlug) async {}

  @override
  Future<TenantAdminAccount> fetchAccountBySlug(String accountSlug) async {
    return TenantAdminAccount(
      id: 'acc-1',
      name: 'Conta',
      slug: accountSlug,
      document: const TenantAdminDocument(type: 'cpf', number: '000'),
      ownershipState: TenantAdminOwnershipState.tenantOwned,
    );
  }

  @override
  Future<List<TenantAdminAccount>> fetchAccounts() async => const [];

  @override
  Future<void> forceDeleteAccount(String accountSlug) async {}

  @override
  Future<TenantAdminAccount> restoreAccount(String accountSlug) async {
    return TenantAdminAccount(
      id: 'acc-1',
      name: 'Conta',
      slug: accountSlug,
      document: const TenantAdminDocument(type: 'cpf', number: '000'),
      ownershipState: TenantAdminOwnershipState.tenantOwned,
    );
  }

  @override
  Future<TenantAdminAccount> updateAccount({
    required String accountSlug,
    String? name,
    TenantAdminDocument? document,
  }) async {
    return TenantAdminAccount(
      id: 'acc-1',
      name: name ?? 'Conta',
      slug: accountSlug,
      document: document ?? const TenantAdminDocument(type: 'cpf', number: '000'),
      ownershipState: TenantAdminOwnershipState.tenantOwned,
    );
  }
}

class _FakeAccountProfilesRepository
    implements TenantAdminAccountProfilesRepositoryContract {
  @override
  Future<List<TenantAdminProfileTypeDefinition>> fetchProfileTypes() async {
    return const [
      TenantAdminProfileTypeDefinition(
        type: 'venue',
        label: 'Venue',
        allowedTaxonomies: [],
        capabilities: TenantAdminProfileTypeCapabilities(
          isFavoritable: true,
          isPoiEnabled: true,
          hasBio: false,
          hasTaxonomies: false,
          hasAvatar: false,
          hasCover: false,
          hasEvents: false,
        ),
      ),
    ];
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
    return TenantAdminAccountProfile(
      id: 'profile-1',
      accountId: accountId,
      profileType: profileType,
      displayName: displayName,
      location: location,
      taxonomyTerms: taxonomyTerms,
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
      accountId: 'acc-1',
      profileType: 'venue',
      displayName: 'Perfil',
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
    return const TenantAdminAccountProfile(
      id: 'profile-1',
      accountId: 'acc-1',
      profileType: 'venue',
      displayName: 'Perfil',
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
      accountId: 'acc-1',
      profileType: 'venue',
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
      label: label ?? 'Venue',
      allowedTaxonomies: allowedTaxonomies ?? const [],
      capabilities: capabilities ??
          const TenantAdminProfileTypeCapabilities(
            isFavoritable: true,
            isPoiEnabled: true,
            hasBio: false,
            hasTaxonomies: false,
            hasAvatar: false,
            hasCover: false,
            hasEvents: false,
          ),
    );
  }

  @override
  Future<void> deleteProfileType(String type) async {}
}
