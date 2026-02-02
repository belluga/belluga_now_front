import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profiles_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/screens/tenant_admin_account_profile_create_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/controllers/tenant_admin_location_picker_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Profile type capabilities toggle form fields', (tester) async {
    final getIt = GetIt.I;
    if (getIt.isRegistered<TenantAdminAccountsRepositoryContract>()) {
      getIt.unregister<TenantAdminAccountsRepositoryContract>();
    }
    if (getIt.isRegistered<TenantAdminAccountProfilesRepositoryContract>()) {
      getIt.unregister<TenantAdminAccountProfilesRepositoryContract>();
    }
    if (getIt.isRegistered<TenantAdminAccountProfilesController>()) {
      getIt.unregister<TenantAdminAccountProfilesController>();
    }
    if (getIt.isRegistered<TenantAdminLocationPickerController>()) {
      getIt.unregister<TenantAdminLocationPickerController>();
    }

    getIt.registerSingleton<TenantAdminAccountsRepositoryContract>(
      _FakeTenantAdminAccountsRepository(),
    );
    getIt.registerSingleton<TenantAdminAccountProfilesRepositoryContract>(
      _FakeTenantAdminAccountProfilesRepository(),
    );

    getIt.registerSingleton<TenantAdminAccountProfilesController>(
      TenantAdminAccountProfilesController(
        profilesRepository:
            getIt.get<TenantAdminAccountProfilesRepositoryContract>(),
        accountsRepository:
            getIt.get<TenantAdminAccountsRepositoryContract>(),
      ),
    );
    getIt.registerSingleton<TenantAdminLocationPickerController>(
      TenantAdminLocationPickerController(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TenantAdminAccountProfileCreateScreen(
            accountSlug: 'account-1',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Select the rich type (shows all capability-driven fields).
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Completo').last);
    await tester.pumpAndSettle();

    expect(find.text('Bio'), findsOneWidget);
    expect(find.text('Taxonomias'), findsOneWidget);
    expect(find.text('genre'), findsOneWidget);
    expect(find.text('Imagens do perfil'), findsOneWidget);
    expect(find.text('Localizacao'), findsOneWidget);

    // Switch to a minimal type (no extra fields).
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Basico').last);
    await tester.pumpAndSettle();

    expect(find.text('Bio'), findsNothing);
    expect(find.text('Taxonomias'), findsNothing);
    expect(find.text('genre'), findsNothing);
    expect(find.text('Imagens do perfil'), findsNothing);
    expect(find.text('Localizacao'), findsNothing);
  });
}

class _FakeTenantAdminAccountsRepository
    implements TenantAdminAccountsRepositoryContract {
  @override
  Future<List<TenantAdminAccount>> fetchAccounts() async => const [];

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
    String? organizationId,
  }) async {
    return TenantAdminAccount(
      id: 'account-1',
      name: name,
      slug: 'account-1',
      document: document,
      ownershipState: TenantAdminOwnershipState.tenantOwned,
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
      document: document ?? const TenantAdminDocument(type: 'cpf', number: '000'),
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

class _FakeTenantAdminAccountProfilesRepository
    implements TenantAdminAccountProfilesRepositoryContract {
  @override
  Future<List<TenantAdminProfileTypeDefinition>> fetchProfileTypes() async {
    return const [
      TenantAdminProfileTypeDefinition(
        type: 'full',
        label: 'Completo',
        allowedTaxonomies: ['genre'],
        capabilities: TenantAdminProfileTypeCapabilities(
          isFavoritable: true,
          isPoiEnabled: true,
          hasBio: true,
          hasTaxonomies: true,
          hasAvatar: true,
          hasCover: true,
          hasEvents: false,
        ),
      ),
      TenantAdminProfileTypeDefinition(
        type: 'basic',
        label: 'Basico',
        allowedTaxonomies: [],
        capabilities: TenantAdminProfileTypeCapabilities(
          isFavoritable: false,
          isPoiEnabled: false,
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
  Future<List<TenantAdminAccountProfile>> fetchAccountProfiles({
    String? accountId,
  }) async => const [];

  @override
  Future<TenantAdminAccountProfile> fetchAccountProfile(
    String accountProfileId,
  ) async {
    return const TenantAdminAccountProfile(
      id: 'profile-1',
      accountId: 'account-1',
      profileType: 'basic',
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
    return TenantAdminAccountProfile(
      id: 'profile-1',
      accountId: accountId,
      profileType: profileType,
      displayName: displayName,
      location: location,
      taxonomyTerms: taxonomyTerms,
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
      profileType: profileType ?? 'basic',
      displayName: displayName ?? 'Perfil',
      location: location,
      taxonomyTerms: taxonomyTerms ?? const [],
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
      profileType: 'basic',
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
      label: label ?? 'Basico',
      allowedTaxonomies: allowedTaxonomies ?? const [],
      capabilities: capabilities ??
          const TenantAdminProfileTypeCapabilities(
            isFavoritable: false,
            isPoiEnabled: false,
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
