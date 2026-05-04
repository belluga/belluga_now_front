import 'dart:typed_data';

import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_external_image_proxy_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_onboarding_result.dart';
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
import 'package:belluga_now/domain/services/tenant_admin_location_selection_contract.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_location_selection_service.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profiles_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/screens/tenant_admin_account_profile_create_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
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
    if (getIt.isRegistered<TenantAdminExternalImageProxyContract>()) {
      getIt.unregister<TenantAdminExternalImageProxyContract>();
    }
    if (getIt.isRegistered<TenantAdminImageIngestionService>()) {
      getIt.unregister<TenantAdminImageIngestionService>();
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
    getIt.registerSingleton<TenantAdminExternalImageProxyContract>(
      _FakeExternalImageProxy(),
    );
    getIt.registerSingleton<TenantAdminImageIngestionService>(
      TenantAdminImageIngestionService(),
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

class _FakeExternalImageProxy implements TenantAdminExternalImageProxyContract {
  @override
  Future<Uint8List> fetchExternalImageBytes({required Object imageUrl}) async {
    throw UnimplementedError();
  }
}

class _FakeTenantAdminAccountsRepository
    with TenantAdminAccountsRepositoryPaginationMixin
    implements TenantAdminAccountsRepositoryContract {
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

class _FakeTenantAdminAccountProfilesRepository
    with TenantAdminProfileTypesPaginationMixin
    implements TenantAdminAccountProfilesRepositoryContract {
  @override
  Future<List<TenantAdminProfileTypeDefinition>> fetchProfileTypes() async {
    return [
      tenantAdminProfileTypeDefinitionFromRaw(
        type: 'full',
        label: 'Completo',
        allowedTaxonomies: ['genre'],
        capabilities: TenantAdminProfileTypeCapabilities(
          isFavoritable: TenantAdminFlagValue(true),
          isPoiEnabled: TenantAdminFlagValue(true),
          hasBio: TenantAdminFlagValue(true),
          hasContent: TenantAdminFlagValue(false),
          hasTaxonomies: TenantAdminFlagValue(true),
          hasAvatar: TenantAdminFlagValue(true),
          hasCover: TenantAdminFlagValue(true),
          hasEvents: TenantAdminFlagValue(false),
        ),
      ),
      tenantAdminProfileTypeDefinitionFromRaw(
        type: 'basic',
        label: 'Basico',
        allowedTaxonomies: [],
        capabilities: TenantAdminProfileTypeCapabilities(
          isFavoritable: TenantAdminFlagValue(false),
          isPoiEnabled: TenantAdminFlagValue(false),
          hasBio: TenantAdminFlagValue(false),
          hasContent: TenantAdminFlagValue(false),
          hasTaxonomies: TenantAdminFlagValue(false),
          hasAvatar: TenantAdminFlagValue(false),
          hasCover: TenantAdminFlagValue(false),
          hasEvents: TenantAdminFlagValue(false),
        ),
      ),
    ];
  }

  @override
  Future<TenantAdminProfileTypeDefinition> fetchProfileType(
    TenantAdminAccountProfilesRepoString profileType,
  ) async {
    return (await fetchProfileTypes()).firstWhere(
      (definition) => definition.type == profileType.value,
    );
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
      profileType: 'basic',
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
    return tenantAdminAccountProfileFromRaw(
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
      profileType: profileType ?? 'basic',
      displayName: displayName ?? 'Perfil',
      location: location,
      taxonomyTerms: taxonomyTerms ?? const TenantAdminTaxonomyTerms.empty(),
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
      profileType: 'basic',
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
    TenantAdminAccountProfilesRepoString? pluralLabel,
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
    TenantAdminAccountProfilesRepoString? pluralLabel,
    List<TenantAdminAccountProfilesRepoString>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
  }) async {
    return tenantAdminProfileTypeDefinitionFromRaw(
      type: type,
      label: label ?? 'Basico',
      allowedTaxonomies: allowedTaxonomies ?? [],
      capabilities: capabilities ??
          TenantAdminProfileTypeCapabilities(
            isFavoritable: TenantAdminFlagValue(false),
            isPoiEnabled: TenantAdminFlagValue(false),
            hasBio: TenantAdminFlagValue(false),
            hasContent: TenantAdminFlagValue(false),
            hasTaxonomies: TenantAdminFlagValue(false),
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

class _FakeTenantAdminTaxonomiesRepository
    with TenantAdminTaxonomiesPaginationMixin
    implements TenantAdminTaxonomiesRepositoryContract {
  @override
  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomies() async {
    return [
      tenantAdminTaxonomyDefinitionFromRaw(
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
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required TenantAdminTaxRepoString taxonomyId,
  }) async {
    return [
      tenantAdminTaxonomyTermDefinitionFromRaw(
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
  Future<TenantAdminTaxonomyDefinition> createTaxonomy({
    required TenantAdminTaxRepoString slug,
    required TenantAdminTaxRepoString name,
    required List<TenantAdminTaxRepoString> appliesTo,
    TenantAdminTaxRepoString? icon,
    TenantAdminTaxRepoString? color,
  }) async {
    return tenantAdminTaxonomyDefinitionFromRaw(
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
    required TenantAdminTaxRepoString taxonomyId,
    TenantAdminTaxRepoString? slug,
    TenantAdminTaxRepoString? name,
    List<TenantAdminTaxRepoString>? appliesTo,
    TenantAdminTaxRepoString? icon,
    TenantAdminTaxRepoString? color,
  }) async {
    return tenantAdminTaxonomyDefinitionFromRaw(
      id: taxonomyId,
      slug: slug ?? 'genre',
      name: name ?? 'genre',
      appliesTo: appliesTo ?? [],
      icon: icon,
      color: color,
    );
  }

  @override
  Future<void> deleteTaxonomy(TenantAdminTaxRepoString taxonomyId) async {}

  @override
  Future<TenantAdminTaxonomyTermDefinition> createTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString slug,
    required TenantAdminTaxRepoString name,
  }) async {
    return tenantAdminTaxonomyTermDefinitionFromRaw(
      id: 'term-new',
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
      slug: slug ?? 'term',
      name: name ?? 'Term',
    );
  }

  @override
  Future<void> deleteTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString termId,
  }) async {}
}
