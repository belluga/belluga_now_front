import 'dart:async';
import 'dart:typed_data';

import 'package:belluga_form_validation/belluga_form_validation.dart'
    show FormValidationFailure;
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
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/domain/services/tenant_admin_location_selection_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_location_selection_service.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/controllers/tenant_admin_account_create_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/controllers/tenant_admin_accounts_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms.dart';

class _FakeAccountsRepository
    with TenantAdminAccountsRepositoryPaginationMixin
    implements TenantAdminAccountsRepositoryContract {
  _FakeAccountsRepository(this._accounts);

  List<TenantAdminAccount> _accounts;
  Completer<void>? fetchAccountsGate;
  bool failNextLoadAccounts = false;
  int fetchAccountsCalls = 0;
  int createCalls = 0;
  int createOnboardingCalls = 0;
  Object? createAccountError;
  String? lastOnboardingBio;
  String? lastOnboardingContent;
  List<TenantAdminTaxonomyTerm> lastOnboardingTaxonomyTerms =
      <TenantAdminTaxonomyTerm>[];
  TenantAdminMediaUpload? lastOnboardingAvatarUpload;
  TenantAdminMediaUpload? lastOnboardingCoverUpload;
  final List<TenantAdminOwnershipState?> loadAccountsOwnershipCalls =
      <TenantAdminOwnershipState?>[];
  final List<TenantAdminOwnershipState?> loadNextAccountsOwnershipCalls =
      <TenantAdminOwnershipState?>[];
  final List<String?> loadAccountsSearchCalls = <String?>[];
  final List<String?> loadNextAccountsSearchCalls = <String?>[];

  @override
  Future<void> loadAccounts({
    TenantAdminAccountsRepositoryContractPrimInt? pageSize,
    TenantAdminOwnershipState? ownershipState,
    TenantAdminAccountsRepositoryContractPrimString? searchQuery,
  }) async {
    final effectivePageSize = pageSize ??
        TenantAdminAccountsRepositoryContractPrimInt.fromRaw(
          20,
          defaultValue: 20,
        );
    loadAccountsOwnershipCalls.add(ownershipState);
    loadAccountsSearchCalls.add(searchQuery?.value);
    if (failNextLoadAccounts) {
      failNextLoadAccounts = false;
      accountsErrorStreamValue.addValue(
        TenantAdminAccountsRepositoryContractPrimString.fromRaw(
          'backend error',
          defaultValue: 'backend error',
        ),
      );
      throw Exception('backend error');
    }
    final result = await fetchAccountsPage(
      page: TenantAdminAccountsRepositoryContractPrimInt.fromRaw(
        1,
        defaultValue: 1,
      ),
      pageSize: effectivePageSize,
      ownershipState: ownershipState,
      searchQuery: searchQuery,
    );
    accountsStreamValue.addValue(result.accounts);
    hasMoreAccountsStreamValue.addValue(
      TenantAdminAccountsRepositoryContractPrimBool.fromRaw(
        result.hasMore,
        defaultValue: result.hasMore,
      ),
    );
    accountsErrorStreamValue.addValue(null);
  }

  @override
  Future<void> loadNextAccountsPage({
    TenantAdminAccountsRepositoryContractPrimInt? pageSize,
    TenantAdminOwnershipState? ownershipState,
    TenantAdminAccountsRepositoryContractPrimString? searchQuery,
  }) async {
    final effectivePageSize = pageSize ??
        TenantAdminAccountsRepositoryContractPrimInt.fromRaw(
          20,
          defaultValue: 20,
        );
    loadNextAccountsOwnershipCalls.add(ownershipState);
    loadNextAccountsSearchCalls.add(searchQuery?.value);
    if (!hasMoreAccountsStreamValue.value.value) {
      return;
    }
    final loaded = accountsStreamValue.value ?? <TenantAdminAccount>[];
    final page = (loaded.length ~/ effectivePageSize.value) + 1;
    final result = await fetchAccountsPage(
      page: TenantAdminAccountsRepositoryContractPrimInt.fromRaw(
        page,
        defaultValue: page,
      ),
      pageSize: effectivePageSize,
      ownershipState: ownershipState,
      searchQuery: searchQuery,
    );
    accountsStreamValue.addValue(
      List<TenantAdminAccount>.unmodifiable([...loaded, ...result.accounts]),
    );
    hasMoreAccountsStreamValue.addValue(
      TenantAdminAccountsRepositoryContractPrimBool.fromRaw(
        result.hasMore,
        defaultValue: result.hasMore,
      ),
    );
    accountsErrorStreamValue.addValue(null);
  }

  @override
  void resetAccountsState() {
    accountsStreamValue.addValue(null);
    hasMoreAccountsStreamValue.addValue(
      TenantAdminAccountsRepositoryContractPrimBool.fromRaw(
        true,
        defaultValue: true,
      ),
    );
    isAccountsPageLoadingStreamValue.addValue(
      TenantAdminAccountsRepositoryContractPrimBool.fromRaw(
        false,
        defaultValue: false,
      ),
    );
    accountsErrorStreamValue.addValue(null);
  }

  @override
  Future<List<TenantAdminAccount>> fetchAccounts() async {
    fetchAccountsCalls += 1;
    final gate = fetchAccountsGate;
    if (gate != null) {
      await gate.future;
    }
    return _accounts;
  }

  @override
  Future<TenantAdminPagedAccountsResult> fetchAccountsPage({
    required TenantAdminAccountsRepositoryContractPrimInt page,
    required TenantAdminAccountsRepositoryContractPrimInt pageSize,
    TenantAdminOwnershipState? ownershipState,
    TenantAdminAccountsRepositoryContractPrimString? searchQuery,
  }) async {
    final all = await fetchAccounts();
    final filteredByOwnership = ownershipState == null
        ? all
        : all.where((account) {
            return account.ownershipState == ownershipState;
          }).toList(growable: false);
    final normalizedSearch = searchQuery?.value.trim().toLowerCase() ?? '';
    final filtered = normalizedSearch.isEmpty
        ? filteredByOwnership
        : filteredByOwnership.where((account) {
            return account.name.toLowerCase().contains(normalizedSearch) ||
                account.slug.toLowerCase().contains(normalizedSearch) ||
                account.document.number
                    .toLowerCase()
                    .contains(normalizedSearch);
          }).toList(growable: false);
    final startIndex = (page.value - 1) * pageSize.value;
    if (startIndex >= filtered.length ||
        page.value <= 0 ||
        pageSize.value <= 0) {
      return tenantAdminPagedAccountsResultFromRaw(
        accounts: <TenantAdminAccount>[],
        hasMore: false,
      );
    }
    final endIndex = startIndex + pageSize.value > filtered.length
        ? filtered.length
        : startIndex + pageSize.value;
    return tenantAdminPagedAccountsResultFromRaw(
      accounts: filtered.sublist(startIndex, endIndex),
      hasMore: endIndex < filtered.length,
    );
  }

  @override
  Future<TenantAdminAccount> fetchAccountBySlug(
    TenantAdminAccountsRepositoryContractPrimString accountSlug,
  ) async {
    return _accounts.firstWhere(
      (account) => account.slug == accountSlug.value,
      orElse: () => _accounts.first,
    );
  }

  @override
  Future<TenantAdminAccount> createAccount({
    required TenantAdminAccountsRepositoryContractPrimString name,
    TenantAdminDocument? document,
    required TenantAdminOwnershipState ownershipState,
    TenantAdminAccountsRepositoryContractPrimString? organizationId,
  }) async {
    final error = createAccountError;
    if (error != null) {
      throw error;
    }
    createCalls += 1;
    final created = tenantAdminAccountFromRaw(
      id: 'acc-$createCalls',
      name: name.value,
      slug: 'acc-$createCalls',
      document:
          document ?? tenantAdminDocumentFromRaw(type: 'cpf', number: '000'),
      ownershipState: ownershipState,
      organizationId: organizationId?.value,
    );
    _accounts = [..._accounts, created];
    final loaded = accountsStreamValue.value;
    if (loaded != null) {
      accountsStreamValue.addValue(
          List<TenantAdminAccount>.unmodifiable([...loaded, created]));
    }
    return created;
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
    final error = createAccountError;
    if (error != null) {
      throw error;
    }
    createOnboardingCalls += 1;
    lastOnboardingBio = bio?.value;
    lastOnboardingContent = content?.value;
    lastOnboardingTaxonomyTerms =
        List<TenantAdminTaxonomyTerm>.from(taxonomyTerms.items);
    lastOnboardingAvatarUpload = avatarUpload;
    lastOnboardingCoverUpload = coverUpload;

    final account = tenantAdminAccountFromRaw(
      id: 'acc-onboarding-$createOnboardingCalls',
      name: name.value,
      slug: 'acc-onboarding-$createOnboardingCalls',
      document: tenantAdminDocumentFromRaw(type: 'cpf', number: '000'),
      ownershipState: ownershipState,
    );
    final profile = tenantAdminAccountProfileFromRaw(
      id: 'profile-onboarding-$createOnboardingCalls',
      accountId: account.id,
      profileType: profileType.value,
      displayName: name.value,
      location: location,
      taxonomyTerms: taxonomyTerms,
      bio: bio?.value,
      content: content?.value,
    );
    _accounts = [..._accounts, account];
    final loaded = accountsStreamValue.value;
    if (loaded != null) {
      accountsStreamValue.addValue(
        List<TenantAdminAccount>.unmodifiable([...loaded, account]),
      );
    }
    return TenantAdminAccountOnboardingResult(
      account: account,
      accountProfile: profile,
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
    return fetchAccountBySlug(accountSlug);
  }

  @override
  Future<void> deleteAccount(
    TenantAdminAccountsRepositoryContractPrimString accountSlug,
  ) async {}

  @override
  Future<TenantAdminAccount> restoreAccount(
    TenantAdminAccountsRepositoryContractPrimString accountSlug,
  ) async {
    return fetchAccountBySlug(accountSlug);
  }

  @override
  Future<void> forceDeleteAccount(
    TenantAdminAccountsRepositoryContractPrimString accountSlug,
  ) async {}
}

class _FakeAccountProfilesRepository
    with TenantAdminProfileTypesPaginationMixin
    implements TenantAdminAccountProfilesRepositoryContract {
  _FakeAccountProfilesRepository(this._types);

  final List<TenantAdminProfileTypeDefinition> _types;
  int createProfileCalls = 0;
  String? lastCreateDisplayName;
  String? lastCreateBio;
  String? lastCreateAvatarUrl;
  String? lastCreateCoverUrl;
  TenantAdminMediaUpload? lastCreateAvatarUpload;
  TenantAdminMediaUpload? lastCreateCoverUpload;
  List<TenantAdminTaxonomyTerm> lastCreateTaxonomyTerms = const [];
  Object? createProfileError;

  @override
  Future<List<TenantAdminProfileTypeDefinition>> fetchProfileTypes() async =>
      _types;

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
    final error = createProfileError;
    if (error != null) {
      throw error;
    }
    createProfileCalls += 1;
    lastCreateDisplayName = displayName.value;
    lastCreateBio = bio?.value;
    lastCreateAvatarUrl = avatarUrl?.value;
    lastCreateCoverUrl = coverUrl?.value;
    lastCreateAvatarUpload = avatarUpload;
    lastCreateCoverUpload = coverUpload;
    lastCreateTaxonomyTerms =
        List<TenantAdminTaxonomyTerm>.from(taxonomyTerms.items);
    return tenantAdminAccountProfileFromRaw(
      id: 'profile-$createProfileCalls',
      accountId: accountId,
      profileType: profileType,
      displayName: displayName,
      location: location,
      taxonomyTerms: taxonomyTerms,
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
      accountId: 'acc-1',
      profileType: 'venue',
      displayName: 'Perfil',
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
      id: 'profile-1',
      accountId: 'acc-1',
      profileType: 'venue',
      displayName: 'Perfil',
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
      accountId: 'acc-1',
      profileType: 'venue',
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
      label: label ?? 'Updated',
      allowedTaxonomies: allowedTaxonomies ?? [],
      capabilities: capabilities ??
          TenantAdminProfileTypeCapabilities(
            isFavoritable: TenantAdminFlagValue(true),
            isPoiEnabled: TenantAdminFlagValue(true),
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

class _FakeTaxonomiesRepository
    with TenantAdminTaxonomiesPaginationMixin
    implements TenantAdminTaxonomiesRepositoryContract {
  @override
  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomies() async => [];

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
  }) async =>
      [];

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
  Future<TenantAdminTaxonomyDefinition> createTaxonomy({
    required TenantAdminTaxRepoString slug,
    required TenantAdminTaxRepoString name,
    required List<TenantAdminTaxRepoString> appliesTo,
    TenantAdminTaxRepoString? icon,
    TenantAdminTaxRepoString? color,
  }) async {
    return tenantAdminTaxonomyDefinitionFromRaw(
      id: 'tax-1',
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
      slug: slug ?? 'taxonomy',
      name: name ?? 'Taxonomy',
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
      id: 'term-1',
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

TenantAdminAccountsController _buildListController({
  required _FakeAccountsRepository accountsRepository,
  TenantAdminTenantScopeContract? tenantScope,
}) {
  return TenantAdminAccountsController(
    accountsRepository: accountsRepository,
    tenantScope: tenantScope,
  );
}

TenantAdminAccountCreateController _buildCreateController({
  _FakeAccountsRepository? accountsRepository,
  _FakeAccountProfilesRepository? profilesRepository,
  _FakeTaxonomiesRepository? taxonomiesRepository,
  TenantAdminLocationSelectionContract? locationSelectionService,
}) {
  return TenantAdminAccountCreateController(
    accountsRepository: accountsRepository ?? _FakeAccountsRepository([]),
    profilesRepository:
        profilesRepository ?? _FakeAccountProfilesRepository([]),
    taxonomiesRepository: taxonomiesRepository ?? _FakeTaxonomiesRepository(),
    locationSelectionService:
        locationSelectionService ?? TenantAdminLocationSelectionService(),
  );
}

void main() {
  group('TenantAdminAccountsController', () {
    test('loads accounts on init', () async {
      final accountsRepository = _FakeAccountsRepository([
        tenantAdminAccountFromRaw(
          id: 'acc-1',
          name: 'Conta',
          slug: 'conta',
          document: tenantAdminDocumentFromRaw(type: 'cpf', number: '000'),
          ownershipState: TenantAdminOwnershipState.tenantOwned,
        ),
      ]);
      final controller = _buildListController(
        accountsRepository: accountsRepository,
      );

      await controller.init();

      expect(controller.accountsStreamValue.value?.length, 1);
      expect(
        controller.accountsStreamValue.value?.first.slug,
        'conta',
      );
    });

    test('switching segment reloads accounts with ownership filter', () async {
      final accountsRepository = _FakeAccountsRepository([
        tenantAdminAccountFromRaw(
          id: 'acc-tenant',
          name: 'Conta tenant',
          slug: 'conta-tenant',
          document: tenantAdminDocumentFromRaw(type: 'cpf', number: '000'),
          ownershipState: TenantAdminOwnershipState.tenantOwned,
        ),
        tenantAdminAccountFromRaw(
          id: 'acc-unmanaged',
          name: 'Conta unmanaged',
          slug: 'conta-unmanaged',
          document: tenantAdminDocumentFromRaw(type: 'cpf', number: '111'),
          ownershipState: TenantAdminOwnershipState.unmanaged,
        ),
      ]);
      final controller = _buildListController(
        accountsRepository: accountsRepository,
      );

      await controller.init();
      expect(
        accountsRepository.loadAccountsOwnershipCalls.last,
        TenantAdminOwnershipState.tenantOwned,
      );
      expect(
        controller.accountsStreamValue.value?.map((it) => it.slug).toList(),
        ['conta-tenant'],
      );

      controller.updateSelectedOwnership(TenantAdminOwnershipState.unmanaged);
      await Future<void>.delayed(Duration.zero);

      expect(
        accountsRepository.loadAccountsOwnershipCalls.last,
        TenantAdminOwnershipState.unmanaged,
      );
      expect(
        controller.accountsStreamValue.value?.map((it) => it.slug).toList(),
        ['conta-unmanaged'],
      );
    });

    test('search query triggers backend-first reload after debounce', () async {
      final accountsRepository = _FakeAccountsRepository([
        tenantAdminAccountFromRaw(
          id: 'acc-tenant',
          name: 'Conta tenant',
          slug: 'conta-tenant',
          document: tenantAdminDocumentFromRaw(type: 'cpf', number: '000'),
          ownershipState: TenantAdminOwnershipState.tenantOwned,
        ),
        tenantAdminAccountFromRaw(
          id: 'acc-target',
          name: 'Conta alvo',
          slug: 'conta-alvo',
          document: tenantAdminDocumentFromRaw(type: 'cpf', number: '9911'),
          ownershipState: TenantAdminOwnershipState.tenantOwned,
        ),
      ]);
      final controller = _buildListController(
        accountsRepository: accountsRepository,
      );

      await controller.init();
      expect(accountsRepository.loadAccountsSearchCalls.last, isNull);

      controller.updateSearchQuery('  alvo  ');
      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(accountsRepository.loadAccountsSearchCalls.last, 'alvo');
      expect(
        controller.accountsStreamValue.value?.map((it) => it.slug).toList(),
        ['conta-alvo'],
      );
    });

    test('init reloads when tenant scope changes', () async {
      final accountsRepository = _FakeAccountsRepository([
        tenantAdminAccountFromRaw(
          id: 'acc-1',
          name: 'Conta A',
          slug: 'conta-a',
          document: tenantAdminDocumentFromRaw(type: 'cpf', number: '000'),
          ownershipState: TenantAdminOwnershipState.tenantOwned,
        ),
      ]);
      final tenantScope = _FakeTenantScope('tenant-a.test');
      final controller = _buildListController(
        accountsRepository: accountsRepository,
        tenantScope: tenantScope,
      );

      await controller.init();
      expect(controller.accountsStreamValue.value?.first.slug, 'conta-a');

      accountsRepository._accounts = [
        tenantAdminAccountFromRaw(
          id: 'acc-2',
          name: 'Conta B',
          slug: 'conta-b',
          document: tenantAdminDocumentFromRaw(type: 'cpf', number: '111'),
          ownershipState: TenantAdminOwnershipState.tenantOwned,
        ),
      ];
      tenantScope.selectTenantDomain('tenant-b.test');

      await controller.init();
      expect(controller.accountsStreamValue.value?.first.slug, 'conta-b');
    });

    test('keeps accounts stream null while first page is loading', () async {
      final accountsRepository = _FakeAccountsRepository([
        tenantAdminAccountFromRaw(
          id: 'acc-1',
          name: 'Conta',
          slug: 'conta',
          document: tenantAdminDocumentFromRaw(type: 'cpf', number: '000'),
          ownershipState: TenantAdminOwnershipState.tenantOwned,
        ),
      ])
        ..fetchAccountsGate = Completer<void>();
      final controller = _buildListController(
        accountsRepository: accountsRepository,
      );

      final loadFuture = controller.loadAccounts();
      await Future<void>.delayed(Duration.zero);
      expect(controller.accountsStreamValue.value, isNull);

      accountsRepository.fetchAccountsGate?.complete();
      await loadFuture;
      expect(controller.accountsStreamValue.value?.length, 1);
    });

    test('appends pages and stops when hasMore becomes false', () async {
      final accounts = List<TenantAdminAccount>.generate(
        45,
        (index) => tenantAdminAccountFromRaw(
          id: 'acc-$index',
          name: 'Conta $index',
          slug: 'conta-$index',
          document: tenantAdminDocumentFromRaw(type: 'cpf', number: '$index'),
          ownershipState: TenantAdminOwnershipState.tenantOwned,
        ),
      );
      final accountsRepository = _FakeAccountsRepository(accounts);
      final controller = _buildListController(
        accountsRepository: accountsRepository,
      );

      await controller.loadAccounts();
      expect(controller.accountsStreamValue.value?.length, 20);
      expect(controller.hasMoreAccountsStreamValue.value, isTrue);

      await controller.loadNextAccountsPage();
      expect(controller.accountsStreamValue.value?.length, 40);
      expect(controller.hasMoreAccountsStreamValue.value, isTrue);

      await controller.loadNextAccountsPage();
      expect(controller.accountsStreamValue.value?.length, 45);
      expect(controller.hasMoreAccountsStreamValue.value, isFalse);

      await controller.loadNextAccountsPage();
      expect(controller.accountsStreamValue.value?.length, 45);
      expect(accountsRepository.fetchAccountsCalls, 3);
    });

    test('keeps last successful list when reload fails', () async {
      final accountsRepository = _FakeAccountsRepository([
        tenantAdminAccountFromRaw(
          id: 'acc-1',
          name: 'Conta',
          slug: 'conta',
          document: tenantAdminDocumentFromRaw(type: 'cpf', number: '000'),
          ownershipState: TenantAdminOwnershipState.tenantOwned,
        ),
      ]);
      final controller = _buildListController(
        accountsRepository: accountsRepository,
      );

      await controller.loadAccounts();
      expect(controller.accountsStreamValue.value, hasLength(1));
      expect(controller.errorStreamValue.value, isNull);

      accountsRepository.failNextLoadAccounts = true;
      await expectLater(controller.loadAccounts(), throwsException);
      await Future<void>.microtask(() {});

      expect(controller.accountsStreamValue.value, hasLength(1));
      expect(controller.accountsStreamValue.value!.first.slug, 'conta');
      expect(controller.errorStreamValue.value, contains('backend error'));
    });
  });

  group('TenantAdminAccountCreateController', () {
    test('createAccountOnboarding creates account and profile', () async {
      final accountsRepository = _FakeAccountsRepository([]);
      final profilesRepository = _FakeAccountProfilesRepository([
        tenantAdminProfileTypeDefinitionFromRaw(
          type: 'venue',
          label: 'Venue',
          allowedTaxonomies: [],
          capabilities: TenantAdminProfileTypeCapabilities(
            isFavoritable: TenantAdminFlagValue(true),
            isPoiEnabled: TenantAdminFlagValue(true),
            hasBio: TenantAdminFlagValue(false),
            hasContent: TenantAdminFlagValue(false),
            hasTaxonomies: TenantAdminFlagValue(false),
            hasAvatar: TenantAdminFlagValue(false),
            hasCover: TenantAdminFlagValue(false),
            hasEvents: TenantAdminFlagValue(false),
          ),
        ),
      ]);
      final controller = _buildCreateController(
        accountsRepository: accountsRepository,
        profilesRepository: profilesRepository,
      );

      final onboarding = await controller.createAccountOnboarding(
        name: 'Nova Conta',
        ownershipState: TenantAdminOwnershipState.tenantOwned,
        profileType: 'venue',
        location: tenantAdminLocationFromRaw(latitude: -20.0, longitude: -40.0),
      );

      expect(onboarding.account.name, 'Nova Conta');
      expect(onboarding.accountProfile.displayName, 'Nova Conta');
      expect(accountsRepository.createOnboardingCalls, 1);
      expect(profilesRepository.createProfileCalls, 0);
    });

    test('createAccountOnboarding forwards bio and taxonomy terms', () async {
      final accountsRepository = _FakeAccountsRepository([]);
      final profilesRepository = _FakeAccountProfilesRepository([
        tenantAdminProfileTypeDefinitionFromRaw(
          type: 'venue',
          label: 'Venue',
          allowedTaxonomies: ['genre'],
          capabilities: TenantAdminProfileTypeCapabilities(
            isFavoritable: TenantAdminFlagValue(true),
            isPoiEnabled: TenantAdminFlagValue(false),
            hasBio: TenantAdminFlagValue(true),
            hasContent: TenantAdminFlagValue(false),
            hasTaxonomies: TenantAdminFlagValue(true),
            hasAvatar: TenantAdminFlagValue(false),
            hasCover: TenantAdminFlagValue(false),
            hasEvents: TenantAdminFlagValue(false),
          ),
        ),
      ]);
      final controller = _buildCreateController(
        accountsRepository: accountsRepository,
        profilesRepository: profilesRepository,
      );

      await controller.createAccountOnboarding(
        name: 'Nova Conta',
        ownershipState: TenantAdminOwnershipState.tenantOwned,
        profileType: 'venue',
        bio: '<p>Bio teste</p>',
        content: null,
        taxonomyTerms: (() {
          final terms = TenantAdminTaxonomyTerms();
          terms.add(
            tenantAdminTaxonomyTermFromRaw(type: 'genre', value: 'urbana'),
          );
          return terms;
        })(),
      );

      expect(accountsRepository.lastOnboardingBio, '<p>Bio teste</p>');
      expect(accountsRepository.lastOnboardingTaxonomyTerms.length, 1);
      expect(
          accountsRepository.lastOnboardingTaxonomyTerms.first.type, 'genre');
      expect(
        accountsRepository.lastOnboardingTaxonomyTerms.first.value,
        'urbana',
      );
    });

    test(
        'createAccountFromForm submits media as upload and never as direct URL',
        () async {
      final accountsRepository = _FakeAccountsRepository([]);
      final profilesRepository = _FakeAccountProfilesRepository([
        tenantAdminProfileTypeDefinitionFromRaw(
          type: 'venue',
          label: 'Venue',
          allowedTaxonomies: [],
          capabilities: TenantAdminProfileTypeCapabilities(
            isFavoritable: TenantAdminFlagValue(true),
            isPoiEnabled: TenantAdminFlagValue(false),
            hasBio: TenantAdminFlagValue(false),
            hasContent: TenantAdminFlagValue(false),
            hasTaxonomies: TenantAdminFlagValue(false),
            hasAvatar: TenantAdminFlagValue(true),
            hasCover: TenantAdminFlagValue(true),
            hasEvents: TenantAdminFlagValue(false),
          ),
        ),
      ]);
      final controller = _buildCreateController(
        accountsRepository: accountsRepository,
        profilesRepository: profilesRepository,
      );

      controller.nameController.text = 'Conta com imagem';
      controller.updateCreateSelectedProfileType('venue');
      controller.updateCreateAvatarFile(_buildImageXFile('avatar.jpg'));
      controller.updateCreateCoverFile(_buildImageXFile('cover.jpg'));

      await controller.createAccountFromForm(location: null);

      expect(accountsRepository.lastOnboardingAvatarUpload, isNotNull);
      expect(accountsRepository.lastOnboardingCoverUpload, isNotNull);
      expect(
        accountsRepository.lastOnboardingAvatarUpload!.mimeType,
        'image/jpeg',
      );
      expect(
        accountsRepository.lastOnboardingCoverUpload!.mimeType,
        'image/jpeg',
      );
    });

    test('validateCreateBeforeSubmit writes local validation into shared state',
        () async {
      final controller = _buildCreateController();

      final isValid = controller.validateCreateBeforeSubmit(location: null);

      expect(isValid, isFalse);
      expect(
        controller.createValidationStreamValue.value
            .errorForField('profile_type'),
        'Tipo de perfil e obrigatorio.',
      );
      expect(
        controller.createValidationStreamValue.value.errorForField('name'),
        'Nome e obrigatorio.',
      );
      expect(
        controller.createValidationStreamValue.value.firstInvalidTargetId,
        'profile_type',
      );
    });

    test(
        'submitCreateAccountFromForm applies backend validation failures without global error text',
        () async {
      final accountsRepository = _FakeAccountsRepository([])
        ..createAccountError = FormValidationFailure(
          statusCode: 422,
          message: 'The given data was invalid.',
          fieldErrors: <String, List<String>>{
            'location.lat': <String>['Latitude obrigatoria.'],
          },
        );
      final profilesRepository = _FakeAccountProfilesRepository([
        tenantAdminProfileTypeDefinitionFromRaw(
          type: 'venue',
          label: 'Venue',
          allowedTaxonomies: [],
          capabilities: TenantAdminProfileTypeCapabilities(
            isFavoritable: TenantAdminFlagValue(true),
            isPoiEnabled: TenantAdminFlagValue(false),
            hasBio: TenantAdminFlagValue(false),
            hasContent: TenantAdminFlagValue(false),
            hasTaxonomies: TenantAdminFlagValue(false),
            hasAvatar: TenantAdminFlagValue(false),
            hasCover: TenantAdminFlagValue(false),
            hasEvents: TenantAdminFlagValue(false),
          ),
        ),
      ]);
      final controller = _buildCreateController(
        accountsRepository: accountsRepository,
        profilesRepository: profilesRepository,
      );

      controller.nameController.text = 'Conta validada';
      controller.updateCreateSelectedProfileType('venue');

      final created = await controller.submitCreateAccountFromForm(
        location: null,
      );

      expect(created, isFalse);
      expect(
        controller.createValidationStreamValue.value.errorsForGroup('location'),
        <String>['Latitude obrigatoria.'],
      );
      expect(controller.createErrorMessageStreamValue.value, isNull);
      expect(controller.createSuccessAccountStreamValue.value, isNull);
    });

    test(
        'submitCreateAccountFromForm keeps operational failures separate from validation state',
        () async {
      final accountsRepository = _FakeAccountsRepository([])
        ..createAccountError = Exception('backend exploded');
      final profilesRepository = _FakeAccountProfilesRepository([
        tenantAdminProfileTypeDefinitionFromRaw(
          type: 'venue',
          label: 'Venue',
          allowedTaxonomies: [],
          capabilities: TenantAdminProfileTypeCapabilities(
            isFavoritable: TenantAdminFlagValue(true),
            isPoiEnabled: TenantAdminFlagValue(false),
            hasBio: TenantAdminFlagValue(false),
            hasContent: TenantAdminFlagValue(false),
            hasTaxonomies: TenantAdminFlagValue(false),
            hasAvatar: TenantAdminFlagValue(false),
            hasCover: TenantAdminFlagValue(false),
            hasEvents: TenantAdminFlagValue(false),
          ),
        ),
      ]);
      final controller = _buildCreateController(
        accountsRepository: accountsRepository,
        profilesRepository: profilesRepository,
      );

      controller.nameController.text = 'Conta falhou';
      controller.updateCreateSelectedProfileType('venue');

      final created = await controller.submitCreateAccountFromForm(
        location: null,
      );

      expect(created, isFalse);
      expect(controller.createValidationStreamValue.value.hasErrors, isFalse);
      expect(
        controller.createErrorMessageStreamValue.value,
        contains('backend exploded'),
      );
    });

    test(
        'submitCreateAccountFromForm emits success account and clears validation',
        () async {
      final controller = _buildCreateController(
        accountsRepository: _FakeAccountsRepository([]),
        profilesRepository: _FakeAccountProfilesRepository([
          tenantAdminProfileTypeDefinitionFromRaw(
            type: 'venue',
            label: 'Venue',
            allowedTaxonomies: [],
            capabilities: TenantAdminProfileTypeCapabilities(
              isFavoritable: TenantAdminFlagValue(true),
              isPoiEnabled: TenantAdminFlagValue(false),
              hasBio: TenantAdminFlagValue(false),
              hasContent: TenantAdminFlagValue(false),
              hasTaxonomies: TenantAdminFlagValue(false),
              hasAvatar: TenantAdminFlagValue(false),
              hasCover: TenantAdminFlagValue(false),
              hasEvents: TenantAdminFlagValue(false),
            ),
          ),
        ]),
      );

      controller.createValidationController.replaceWithResolved(
        fieldErrors: const <String, List<String>>{
          'name': <String>['Nome e obrigatorio.'],
        },
      );
      controller.nameController.text = 'Conta ok';
      controller.updateCreateSelectedProfileType('venue');

      final created = await controller.submitCreateAccountFromForm(
        location: null,
      );

      expect(created, isTrue);
      expect(controller.createValidationStreamValue.value.hasErrors, isFalse);
      expect(controller.createErrorMessageStreamValue.value, isNull);
      expect(
        controller.createSuccessAccountStreamValue.value?.account.name,
        'Conta ok',
      );
    });
  });
}

XFile _buildImageXFile(String name) {
  return XFile.fromData(
    Uint8List.fromList(<int>[1, 2, 3]),
    mimeType: 'image/jpeg',
    name: name,
  );
}

class _FakeTenantScope implements TenantAdminTenantScopeContract {
  _FakeTenantScope(String initialDomain)
      : _selectedTenantDomainStreamValue =
            StreamValue<String?>(defaultValue: initialDomain);

  final StreamValue<String?> _selectedTenantDomainStreamValue;

  @override
  String? get selectedTenantDomain => _selectedTenantDomainStreamValue.value;

  @override
  String get selectedTenantAdminBaseUrl =>
      'https://${selectedTenantDomain ?? ''}/admin/api';

  @override
  StreamValue<String?> get selectedTenantDomainStreamValue =>
      _selectedTenantDomainStreamValue;

  @override
  void clearSelectedTenantDomain() {
    _selectedTenantDomainStreamValue.addValue(null);
  }

  @override
  void selectTenantDomain(Object tenantDomain) {
    _selectedTenantDomainStreamValue.addValue((tenantDomain is String
            ? tenantDomain
            : (tenantDomain as dynamic).value as String)
        .trim());
  }
}
