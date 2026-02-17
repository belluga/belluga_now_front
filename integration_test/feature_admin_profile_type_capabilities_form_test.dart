import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_accounts_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/domain/services/tenant_admin_location_selection_contract.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_location_selection_service.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profiles_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/screens/tenant_admin_account_profile_create_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'support/integration_test_bootstrap.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  IntegrationTestBootstrap.ensureNonProductionLandlordDomain();

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
    if (getIt.isRegistered<TenantAdminLocationSelectionContract>()) {
      getIt.unregister<TenantAdminLocationSelectionContract>();
    }
    if (getIt.isRegistered<TenantAdminTaxonomiesRepositoryContract>()) {
      getIt.unregister<TenantAdminTaxonomiesRepositoryContract>();
    }

    getIt.registerSingleton<TenantAdminAccountsRepositoryContract>(
      _FakeTenantAdminAccountsRepository(),
    );
    getIt.registerSingleton<TenantAdminAccountProfilesRepositoryContract>(
      _FakeTenantAdminAccountProfilesRepository(),
    );
    getIt.registerSingleton<TenantAdminTaxonomiesRepositoryContract>(
      _FakeTenantAdminTaxonomiesRepository(),
    );

    getIt.registerSingleton<TenantAdminLocationSelectionContract>(
      TenantAdminLocationSelectionService(),
    );
    getIt.registerSingleton<TenantAdminAccountProfilesController>(
      TenantAdminAccountProfilesController(
        profilesRepository:
            getIt.get<TenantAdminAccountProfilesRepositoryContract>(),
        accountsRepository: getIt.get<TenantAdminAccountsRepositoryContract>(),
        taxonomiesRepository:
            getIt.get<TenantAdminTaxonomiesRepositoryContract>(),
      ),
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
    with TenantAdminAccountsRepositoryPaginationMixin
    implements TenantAdminAccountsRepositoryContract {
  @override
  Future<List<TenantAdminAccount>> fetchAccounts() async => const [];

  @override
  Future<TenantAdminPagedAccountsResult> fetchAccountsPage({
    required int page,
    required int pageSize,
    TenantAdminOwnershipState? ownershipState,
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
    TenantAdminDocument? document,
    required TenantAdminOwnershipState ownershipState,
    String? organizationId,
  }) async {
    return TenantAdminAccount(
      id: 'account-1',
      name: name,
      slug: 'account-1',
      document:
          document ?? const TenantAdminDocument(type: 'cpf', number: '000'),
      ownershipState: ownershipState,
      organizationId: organizationId,
    );
  }

  @override
  Future<TenantAdminAccount> updateAccount({
    required String accountSlug,
    String? name,
    String? slug,
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

class _FakeTenantAdminAccountProfilesRepository
    with TenantAdminProfileTypesPaginationMixin
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
          hasContent: false,
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
          hasContent: false,
          hasTaxonomies: false,
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
    String? content,
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
    String? slug,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm>? taxonomyTerms,
    String? bio,
    String? content,
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
    String? newType,
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
            hasContent: false,
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

class _FakeTenantAdminTaxonomiesRepository
    with TenantAdminTaxonomiesPaginationMixin
    implements TenantAdminTaxonomiesRepositoryContract {
  @override
  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomies() async {
    return const [
      TenantAdminTaxonomyDefinition(
        id: 'tax-1',
        slug: 'genre',
        name: 'genre',
        appliesTo: ['account_profile'],
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
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required String taxonomyId,
  }) async {
    return const [
      TenantAdminTaxonomyTermDefinition(
        id: 'term-1',
        taxonomyId: 'tax-1',
        slug: 'samba',
        name: 'Samba',
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
  Future<TenantAdminTaxonomyDefinition> createTaxonomy({
    required String slug,
    required String name,
    required List<String> appliesTo,
    String? icon,
    String? color,
  }) async {
    return TenantAdminTaxonomyDefinition(
      id: 'tax-new',
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
      slug: slug ?? 'genre',
      name: name ?? 'genre',
      appliesTo: appliesTo ?? const [],
      icon: icon,
      color: color,
    );
  }

  @override
  Future<void> deleteTaxonomy(String taxonomyId) async {}

  @override
  Future<TenantAdminTaxonomyTermDefinition> createTerm({
    required String taxonomyId,
    required String slug,
    required String name,
  }) async {
    return TenantAdminTaxonomyTermDefinition(
      id: 'term-new',
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
      slug: slug ?? 'term',
      name: name ?? 'Term',
    );
  }

  @override
  Future<void> deleteTerm({
    required String taxonomyId,
    required String termId,
  }) async {}
}
