import 'package:belluga_contact_channels/belluga_contact_channels.dart';
import 'dart:async';
import 'dart:io';

import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_onboarding_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_gallery_group.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_accounts_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/services/tenant_admin_location_selection_contract.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_location_selection_service.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profiles_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';

class _FakeAccountsRepository
    with TenantAdminAccountsRepositoryPaginationMixin
    implements TenantAdminAccountsRepositoryContract {
  @override
  final StreamValue<List<TenantAdminAccount>?> accountsStreamValue =
      StreamValue<List<TenantAdminAccount>?>(defaultValue: []);

  @override
  final StreamValue<TenantAdminAccountsRepositoryContractPrimBool>
  hasMoreAccountsStreamValue =
      StreamValue<TenantAdminAccountsRepositoryContractPrimBool>(
        defaultValue: TenantAdminAccountsRepositoryContractPrimBool.fromRaw(
          false,
          defaultValue: false,
        ),
      );

  @override
  final StreamValue<TenantAdminAccountsRepositoryContractPrimBool>
  isAccountsPageLoadingStreamValue =
      StreamValue<TenantAdminAccountsRepositoryContractPrimBool>(
        defaultValue: TenantAdminAccountsRepositoryContractPrimBool.fromRaw(
          false,
          defaultValue: false,
        ),
      );

  @override
  final StreamValue<TenantAdminAccountsRepositoryContractPrimString?>
  accountsErrorStreamValue =
      StreamValue<TenantAdminAccountsRepositoryContractPrimString?>();
  TenantAdminOwnershipState? lastUpdatedOwnershipState;

  @override
  Future<void> loadAccounts({
    TenantAdminAccountsRepositoryContractPrimInt? pageSize,
    TenantAdminOwnershipState? ownershipState,
    TenantAdminAccountsRepositoryContractPrimString? searchQuery,
  }) async {}

  @override
  Future<void> loadNextAccountsPage({
    TenantAdminAccountsRepositoryContractPrimInt? pageSize,
    TenantAdminOwnershipState? ownershipState,
    TenantAdminAccountsRepositoryContractPrimString? searchQuery,
  }) async {}

  @override
  void resetAccountsState() {}

  void _upsertAccount(TenantAdminAccount account) {
    final current = List<TenantAdminAccount>.from(
      accountsStreamValue.value ?? <TenantAdminAccount>[],
    );
    final index = current.indexWhere((entry) => entry.id == account.id);
    if (index >= 0) {
      current[index] = account;
    } else {
      current.add(account);
    }
    accountsStreamValue.addValue(
      List<TenantAdminAccount>.unmodifiable(current),
    );
  }

  @override
  Future<TenantAdminAccount> fetchAccountBySlug(
    TenantAdminAccountsRepositoryContractPrimString accountSlug,
  ) async {
    final account = tenantAdminAccountFromRaw(
      id: 'acc-1',
      name: 'Conta',
      slug: accountSlug.value,
      document: tenantAdminDocumentFromRaw(type: 'cpf', number: '000'),
      ownershipState: TenantAdminOwnershipState.tenantOwned,
    );
    _upsertAccount(account);
    return account;
  }

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
  Future<TenantAdminAccount> createAccount({
    required TenantAdminAccountsRepositoryContractPrimString name,
    TenantAdminDocument? document,
    required TenantAdminOwnershipState ownershipState,
    TenantAdminAccountsRepositoryContractPrimString? organizationId,
  }) async {
    final account = tenantAdminAccountFromRaw(
      id: 'acc-1',
      name: name.value,
      slug: 'acc-1',
      document:
          document ?? tenantAdminDocumentFromRaw(type: 'cpf', number: '000'),
      ownershipState: ownershipState,
    );
    _upsertAccount(account);
    return account;
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
    List<TenantAdminNestedProfileGroup> nestedProfileGroups =
        const <TenantAdminNestedProfileGroup>[],
    BellugaContactSourceMode contactMode = BellugaContactSourceMode.own,
    TenantAdminAccountProfilesRepoString? contactSourceAccountProfileId,
    List<BellugaContactChannelDraft> contactChannelDrafts =
        const <BellugaContactChannelDraft>[],
    BellugaContactBubbleSelectionMutation bubbleSelection =
        const BellugaContactBubbleSelectionMutation.omit(),
  }) async {
    final account = await createAccount(
      name: name,
      ownershipState: ownershipState,
    );
    return TenantAdminAccountOnboardingResult(
      account: account,
      accountProfile: tenantAdminAccountProfileFromRaw(
        id: 'profile-onboarding',
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
    lastUpdatedOwnershipState = ownershipState;
    final account = tenantAdminAccountFromRaw(
      id: 'acc-1',
      name: name?.value ?? 'Conta',
      slug: slug?.value ?? accountSlug.value,
      document:
          document ?? tenantAdminDocumentFromRaw(type: 'cpf', number: '000'),
      ownershipState: ownershipState ?? TenantAdminOwnershipState.tenantOwned,
    );
    _upsertAccount(account);
    return account;
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
    extends TenantAdminAccountProfilesRepositoryContract
    with TenantAdminProfileTypesPaginationMixin {
  _FakeAccountProfilesRepository(this._profiles, this._types);

  List<TenantAdminAccountProfile> _profiles;
  final List<TenantAdminProfileTypeDefinition> _types;
  int createProfileCalls = 0;
  String? lastUpdateSlug;
  String? lastUpdateProfileType;
  String? lastUpdateDisplayName;
  String? lastUpdateBio;
  String? lastUpdateContent;
  int fetchAccountProfileCalls = 0;
  String? lastFetchedProfileId;
  bool? lastFetchQueryableOnly;
  String? lastFetchExcludeAccountProfileId;
  int? lastFetchPage;
  int? lastFetchPageSize;
  String? lastFetchSearch;
  int fetchAccountProfilesPageCalls = 0;
  int fetchAccountProfilesCalls = 0;
  int fetchContactSourceCandidatesPageCalls = 0;
  final List<String?> contactSourceCandidateExclusions = [];
  Completer<void>? contactSourceCandidatesGate;
  final Set<int> contactSourceCandidateFailingPages = <int>{};
  final Map<int, TenantAdminPagedResult<TenantAdminAccountProfile>>
  contactSourceCandidatePageOverrides =
      <int, TenantAdminPagedResult<TenantAdminAccountProfile>>{};
  List<TenantAdminNestedProfileGroup>? lastCreateNestedProfileGroups;
  List<TenantAdminNestedProfileGroup>? lastUpdateNestedProfileGroups;
  List<TenantAdminAccountProfileGalleryUpdateGroup>? lastGalleryGroups;
  int updateProfileCalls = 0;
  Completer<void>? createProfileGate;
  Completer<void>? updateProfileGate;

  @override
  Future<List<TenantAdminAccountProfile>> fetchAccountProfiles({
    TenantAdminAccountProfilesRepoString? accountId,
    TenantAdminAccountProfilesRepoBool? queryableOnly,
    TenantAdminAccountProfilesRepoString? excludeAccountProfileId,
  }) async => () {
    fetchAccountProfilesCalls += 1;
    lastFetchQueryableOnly = queryableOnly?.value;
    lastFetchExcludeAccountProfileId = excludeAccountProfileId?.value;
    return _filterProfiles(
      excludeAccountProfileId: excludeAccountProfileId?.value,
    );
  }();

  @override
  Future<TenantAdminPagedResult<TenantAdminAccountProfile>>
  fetchAccountProfilesPage({
    required TenantAdminAccountProfilesRepoInt page,
    required TenantAdminAccountProfilesRepoInt pageSize,
    TenantAdminAccountProfilesRepoString? search,
    TenantAdminAccountProfilesRepoString? accountId,
    TenantAdminAccountProfilesRepoBool? queryableOnly,
    TenantAdminAccountProfilesRepoString? excludeAccountProfileId,
  }) async {
    fetchAccountProfilesPageCalls += 1;
    lastFetchPage = page.value;
    lastFetchPageSize = pageSize.value;
    lastFetchSearch = search?.value;
    lastFetchQueryableOnly = queryableOnly?.value;
    lastFetchExcludeAccountProfileId = excludeAccountProfileId?.value;
    final filtered = _filterProfiles(
      search: search?.value,
      excludeAccountProfileId: excludeAccountProfileId?.value,
    );
    final start = (page.value - 1) * pageSize.value;
    if (page.value <= 0 || pageSize.value <= 0 || start >= filtered.length) {
      return tenantAdminPagedResultFromRaw(
        items: const <TenantAdminAccountProfile>[],
        hasMore: false,
        currentPage: page.value,
        pageSize: pageSize.value,
      );
    }
    final end = start + pageSize.value < filtered.length
        ? start + pageSize.value
        : filtered.length;
    return tenantAdminPagedResultFromRaw(
      items: filtered.sublist(start, end),
      hasMore: end < filtered.length,
      currentPage: page.value,
      pageSize: pageSize.value,
    );
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminAccountProfile>>
  fetchContactSourceCandidatesPage({
    required TenantAdminAccountProfilesRepoInt page,
    required TenantAdminAccountProfilesRepoInt pageSize,
    TenantAdminAccountProfilesRepoString? excludeAccountProfileId,
  }) async {
    fetchContactSourceCandidatesPageCalls += 1;
    contactSourceCandidateExclusions.add(excludeAccountProfileId?.value);
    final gate = contactSourceCandidatesGate;
    if (gate != null) {
      await gate.future;
    }
    if (contactSourceCandidateFailingPages.contains(page.value)) {
      throw StateError('contact-source page ${page.value} failed');
    }
    final overriddenPage = contactSourceCandidatePageOverrides[page.value];
    if (overriddenPage != null) {
      return overriddenPage;
    }
    final filtered = _filterProfiles(
      excludeAccountProfileId: excludeAccountProfileId?.value,
    );
    final start = (page.value - 1) * pageSize.value;
    if (page.value <= 0 || pageSize.value <= 0 || start >= filtered.length) {
      return tenantAdminPagedResultFromRaw(
        items: const <TenantAdminAccountProfile>[],
        hasMore: false,
        currentPage: page.value,
        pageSize: pageSize.value,
      );
    }
    final end = start + pageSize.value < filtered.length
        ? start + pageSize.value
        : filtered.length;
    return tenantAdminPagedResultFromRaw(
      items: filtered.sublist(start, end),
      hasMore: end < filtered.length,
      currentPage: page.value,
      pageSize: pageSize.value,
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
    List<TenantAdminNestedProfileGroup> nestedProfileGroups =
        const <TenantAdminNestedProfileGroup>[],
    BellugaContactSourceMode contactMode = BellugaContactSourceMode.own,
    TenantAdminAccountProfilesRepoString? contactSourceAccountProfileId,
    List<BellugaContactChannelDraft> contactChannelDrafts =
        const <BellugaContactChannelDraft>[],
    BellugaContactBubbleSelectionMutation bubbleSelection =
        const BellugaContactBubbleSelectionMutation.omit(),
  }) async {
    createProfileCalls += 1;
    final gate = createProfileGate;
    if (gate != null) await gate.future;
    lastCreateNestedProfileGroups = nestedProfileGroups;
    final created = tenantAdminAccountProfileFromRaw(
      id: 'profile-$createProfileCalls',
      accountId: accountId.value,
      profileType: profileType.value,
      displayName: displayName.value,
      location: location,
      taxonomyTerms: taxonomyTerms,
    );
    _profiles = [..._profiles, created];
    return created;
  }

  @override
  Future<List<TenantAdminProfileTypeDefinition>> fetchProfileTypes() async =>
      _types;

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
  Future<TenantAdminAccountProfile> fetchAccountProfile(
    TenantAdminAccountProfilesRepoString accountProfileId,
  ) async {
    fetchAccountProfileCalls += 1;
    lastFetchedProfileId = accountProfileId.value;
    return _profiles.firstWhere(
      (profile) => profile.id == accountProfileId.value,
      orElse: () => _profiles.first,
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
    List<TenantAdminNestedProfileGroup>? nestedProfileGroups,
    BellugaContactSourceMode? contactMode,
    TenantAdminAccountProfilesRepoString? contactSourceAccountProfileId,
    List<BellugaContactChannelDraft>? contactChannelDrafts,
    BellugaContactBubbleSelectionMutation bubbleSelection =
        const BellugaContactBubbleSelectionMutation.omit(),
  }) async {
    updateProfileCalls += 1;
    final gate = updateProfileGate;
    if (gate != null) await gate.future;
    lastUpdateSlug = slug?.value;
    lastUpdateProfileType = profileType?.value;
    lastUpdateDisplayName = displayName?.value;
    lastUpdateBio = bio?.value;
    lastUpdateContent = content?.value;
    lastUpdateNestedProfileGroups = nestedProfileGroups;
    return _profiles.first;
  }

  @override
  Future<TenantAdminAccountProfile> updateAccountProfileGallery({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    List<TenantAdminAccountProfileGalleryUpdateGroup> galleryGroups =
        const <TenantAdminAccountProfileGalleryUpdateGroup>[],
  }) async {
    lastGalleryGroups = galleryGroups;
    return _profiles.first;
  }

  @override
  Future<void> deleteAccountProfile(
    TenantAdminAccountProfilesRepoString accountProfileId,
  ) async {}

  @override
  Future<TenantAdminAccountProfile> restoreAccountProfile(
    TenantAdminAccountProfilesRepoString accountProfileId,
  ) async {
    return _profiles.first;
  }

  @override
  Future<void> forceDeleteAccountProfile(
    TenantAdminAccountProfilesRepoString accountProfileId,
  ) async {}

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
    return _types.first;
  }

  @override
  Future<void> deleteProfileType(
    TenantAdminAccountProfilesRepoString type,
  ) async {}

  List<TenantAdminAccountProfile> _filterProfiles({
    String? search,
    String? excludeAccountProfileId,
  }) {
    final normalizedSearch = search?.trim().toLowerCase() ?? '';
    return _profiles
        .where((profile) {
          if (excludeAccountProfileId != null &&
              excludeAccountProfileId.isNotEmpty &&
              profile.id == excludeAccountProfileId) {
            return false;
          }
          if (normalizedSearch.isEmpty) {
            return true;
          }
          final normalizedSlug = profile.slug?.toLowerCase() ?? '';
          return profile.displayName.toLowerCase().contains(normalizedSearch) ||
              profile.profileType.toLowerCase().contains(normalizedSearch) ||
              normalizedSlug.contains(normalizedSearch);
        })
        .toList(growable: false);
  }
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
      id: 'taxonomy-1',
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
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required TenantAdminTaxRepoString taxonomyId,
  }) async => [];

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

void main() {
  test('loads profiles and profile types', () async {
    final profilesRepository = _FakeAccountProfilesRepository(
      [
        tenantAdminAccountProfileFromRaw(
          id: 'profile-1',
          accountId: 'acc-1',
          profileType: 'venue',
          displayName: 'Perfil',
        ),
      ],
      [
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
      ],
    );
    final accountsRepository = _FakeAccountsRepository();
    final TenantAdminLocationSelectionContract locationSelectionService =
        TenantAdminLocationSelectionService();
    final taxonomiesRepository = _FakeTaxonomiesRepository();

    final controller = TenantAdminAccountProfilesController(
      profilesRepository: profilesRepository,
      accountsRepository: accountsRepository,
      taxonomiesRepository: taxonomiesRepository,
      locationSelectionService: locationSelectionService,
    );

    await controller.loadProfiles('acc-1');
    await controller.loadProfileTypes();

    expect(controller.profilesStreamValue.value.length, 1);
    expect(controller.profileTypesStreamValue.value.length, 1);
  });

  test('createProfile refreshes list', () async {
    final profilesRepository = _FakeAccountProfilesRepository([], [
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
    final accountsRepository = _FakeAccountsRepository();
    final TenantAdminLocationSelectionContract locationSelectionService =
        TenantAdminLocationSelectionService();
    final taxonomiesRepository = _FakeTaxonomiesRepository();

    final controller = TenantAdminAccountProfilesController(
      profilesRepository: profilesRepository,
      accountsRepository: accountsRepository,
      taxonomiesRepository: taxonomiesRepository,
      locationSelectionService: locationSelectionService,
    );

    await controller.createProfile(
      accountId: 'acc-1',
      profileType: 'venue',
      displayName: 'Perfil',
      location: tenantAdminLocationFromRaw(latitude: -20, longitude: -40),
    );

    expect(profilesRepository.createProfileCalls, 1);
    expect(controller.profilesStreamValue.value.length, 1);
  });

  test(
    'submit profile drops duplicate contact saves while the first request is in flight',
    () async {
      final burstLevel =
          int.tryParse(Platform.environment['DELPHI_RACE_BURST_LEVEL'] ?? '') ??
          2;
      final profilesRepository = _FakeAccountProfilesRepository([
        tenantAdminAccountProfileFromRaw(
          id: 'profile-1',
          accountId: 'acc-1',
          profileType: 'venue',
          displayName: 'Perfil',
        ),
      ], const <TenantAdminProfileTypeDefinition>[]);
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );
      final createGate = Completer<void>();
      profilesRepository.createProfileGate = createGate;

      final createAttempts = List<Future<void>>.generate(
        burstLevel,
        (_) => controller.submitCreateProfile(
          accountId: 'acc-1',
          profileType: 'venue',
          displayName: 'Novo perfil',
          location: null,
          bio: null,
          content: null,
          taxonomyTerms: const TenantAdminTaxonomyTerms.empty(),
          avatarUpload: null,
          coverUpload: null,
          contactMode: BellugaContactSourceMode.own,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(profilesRepository.createProfileCalls, 1);
      createGate.complete();
      await Future.wait(createAttempts);
      expect(controller.createSuccessMessageStreamValue.value, 'Perfil salvo.');

      final updateGate = Completer<void>();
      profilesRepository.updateProfileGate = updateGate;
      final updateAttempts = List<Future<void>>.generate(
        burstLevel,
        (_) => controller.submitUpdateProfile(
          accountProfileId: 'profile-1',
          profileType: 'venue',
          displayName: 'Perfil atualizado',
          location: null,
          bio: null,
          content: null,
          taxonomyTerms: const TenantAdminTaxonomyTerms.empty(),
          avatarUpload: null,
          coverUpload: null,
          contactMode: BellugaContactSourceMode.own,
          contactChannelDrafts: const <BellugaContactChannelDraft>[],
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(profilesRepository.updateProfileCalls, 1);
      updateGate.complete();
      await Future.wait(updateAttempts);
      expect(
        controller.editSuccessMessageStreamValue.value,
        'Perfil atualizado.',
      );
      controller.dispose();
    },
  );

  test('submitUpdateProfile forwards slug to repository update', () async {
    final profilesRepository = _FakeAccountProfilesRepository(
      [
        tenantAdminAccountProfileFromRaw(
          id: 'profile-1',
          accountId: 'acc-1',
          profileType: 'venue',
          displayName: 'Perfil',
          slug: 'perfil-original',
        ),
      ],
      [
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
      ],
    );
    final accountsRepository = _FakeAccountsRepository();
    final TenantAdminLocationSelectionContract locationSelectionService =
        TenantAdminLocationSelectionService();
    final taxonomiesRepository = _FakeTaxonomiesRepository();

    final controller = TenantAdminAccountProfilesController(
      profilesRepository: profilesRepository,
      accountsRepository: accountsRepository,
      taxonomiesRepository: taxonomiesRepository,
      locationSelectionService: locationSelectionService,
    );

    await controller.submitUpdateProfile(
      accountProfileId: 'profile-1',
      profileType: 'venue',
      displayName: 'Perfil atualizado',
      contactMode: BellugaContactSourceMode.own,
      slug: 'perfil-atualizado',
      location: null,
      bio: null,
      content: null,
      taxonomyTerms: const TenantAdminTaxonomyTerms.empty(),
      avatarUpload: null,
      coverUpload: null,
    );

    expect(profilesRepository.lastUpdateSlug, 'perfil-atualizado');
    expect(profilesRepository.lastUpdateProfileType, 'venue');
    expect(profilesRepository.lastUpdateDisplayName, 'Perfil atualizado');
  });

  test(
    'submitUpdateProfile forwards nested profile groups to repository update',
    () async {
      final profilesRepository = _FakeAccountProfilesRepository(
        [
          tenantAdminAccountProfileFromRaw(
            id: 'profile-1',
            accountId: 'acc-1',
            profileType: 'venue',
            displayName: 'Perfil',
            slug: 'perfil-original',
          ),
        ],
        [
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
        ],
      );
      final accountsRepository = _FakeAccountsRepository();
      final TenantAdminLocationSelectionContract locationSelectionService =
          TenantAdminLocationSelectionService();
      final taxonomiesRepository = _FakeTaxonomiesRepository();

      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: accountsRepository,
        taxonomiesRepository: taxonomiesRepository,
        locationSelectionService: locationSelectionService,
      );

      final groups = <TenantAdminNestedProfileGroup>[
        TenantAdminNestedProfileGroup(
          idValue: TenantAdminNestedProfileGroupTextValue('parceiros'),
          labelValue: TenantAdminNestedProfileGroupTextValue('Parceiros'),
          orderValue: TenantAdminNestedProfileGroupOrderValue(0),
          accountProfileIdValues: <TenantAdminNestedProfileGroupTextValue>[
            TenantAdminNestedProfileGroupTextValue('profile-2'),
          ],
        ),
      ];

      await controller.submitUpdateProfile(
        accountProfileId: 'profile-1',
        profileType: 'venue',
        displayName: 'Perfil atualizado',
        contactMode: BellugaContactSourceMode.own,
        slug: 'perfil-atualizado',
        location: null,
        bio: null,
        content: null,
        taxonomyTerms: const TenantAdminTaxonomyTerms.empty(),
        avatarUpload: null,
        coverUpload: null,
        nestedProfileGroups: groups,
      );

      expect(profilesRepository.lastUpdateNestedProfileGroups, groups);
    },
  );

  test(
    'submitUpdateProfile forwards gallery groups to gallery update',
    () async {
      final profilesRepository = _FakeAccountProfilesRepository(
        [
          tenantAdminAccountProfileFromRaw(
            id: 'profile-1',
            accountId: 'acc-1',
            profileType: 'venue',
            displayName: 'Perfil',
          ),
        ],
        [
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
        ],
      );
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );

      await controller.submitUpdateProfile(
        accountProfileId: 'profile-1',
        profileType: 'venue',
        displayName: 'Perfil atualizado',
        contactMode: BellugaContactSourceMode.own,
        location: null,
        bio: null,
        content: null,
        taxonomyTerms: const TenantAdminTaxonomyTerms.empty(),
        avatarUpload: null,
        coverUpload: null,
        galleryGroups: <TenantAdminAccountProfileGalleryUpdateGroup>[
          TenantAdminAccountProfileGalleryUpdateGroup(
            groupIdValue: TenantAdminNestedProfileGroupTextValue('group-1'),
            subtitleValue: TenantAdminNestedProfileGroupTextValue('Ambiente'),
            orderValue: TenantAdminNestedProfileGroupOrderValue(0),
            items: <TenantAdminAccountProfileGalleryUpdateItem>[
              TenantAdminAccountProfileGalleryUpdateItem(
                itemIdValue: TenantAdminNestedProfileGroupTextValue(
                  'gallery-item-1',
                ),
                descriptionValue: TenantAdminOptionalTextValue()
                  ..parse('Vista para o palco'),
                orderValue: TenantAdminNestedProfileGroupOrderValue(0),
              ),
            ],
          ),
        ],
      );

      expect(profilesRepository.lastGalleryGroups, hasLength(1));
      expect(profilesRepository.lastGalleryGroups!.first.subtitle, 'Ambiente');
      expect(
        profilesRepository.lastGalleryGroups!.first.items.first.description,
        'Vista para o palco',
      );
    },
  );

  test(
    'submitUpdateProfile skips gallery update when loaded persisted gallery is already empty',
    () async {
      final profilesRepository = _FakeAccountProfilesRepository(
        [
          tenantAdminAccountProfileFromRaw(
            id: 'profile-1',
            accountId: 'acc-1',
            profileType: 'venue',
            displayName: 'Perfil',
            galleryGroups: const <TenantAdminAccountProfileGalleryGroup>[],
          ),
        ],
        [
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
        ],
      );
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );

      await controller.loadEditProfile('profile-1');
      await controller.submitUpdateProfile(
        accountProfileId: 'profile-1',
        profileType: 'venue',
        displayName: 'Perfil atualizado',
        contactMode: BellugaContactSourceMode.own,
        location: null,
        bio: null,
        content: null,
        taxonomyTerms: const TenantAdminTaxonomyTerms.empty(),
        avatarUpload: null,
        coverUpload: null,
        galleryGroups: const <TenantAdminAccountProfileGalleryUpdateGroup>[],
      );

      expect(profilesRepository.lastGalleryGroups, isNull);
    },
  );

  test(
    'submitUpdateProfile still forwards empty gallery groups when loaded persisted gallery had content',
    () async {
      final profilesRepository = _FakeAccountProfilesRepository(
        [
          tenantAdminAccountProfileFromRaw(
            id: 'profile-1',
            accountId: 'acc-1',
            profileType: 'venue',
            displayName: 'Perfil',
            galleryGroups: <TenantAdminAccountProfileGalleryGroup>[
              _galleryGroup(),
            ],
          ),
        ],
        [
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
        ],
      );
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );

      await controller.loadEditProfile('profile-1');
      await controller.submitUpdateProfile(
        accountProfileId: 'profile-1',
        profileType: 'venue',
        displayName: 'Perfil atualizado',
        contactMode: BellugaContactSourceMode.own,
        location: null,
        bio: null,
        content: null,
        taxonomyTerms: const TenantAdminTaxonomyTerms.empty(),
        avatarUpload: null,
        coverUpload: null,
        galleryGroups: const <TenantAdminAccountProfileGalleryUpdateGroup>[],
      );

      expect(profilesRepository.lastGalleryGroups, isEmpty);
    },
  );

  test(
    'loadEditProfile reuses the route-resolved profile when provided',
    () async {
      final prefetchedProfile = tenantAdminAccountProfileFromRaw(
        id: 'profile-1',
        accountId: 'acc-1',
        profileType: 'venue',
        displayName: 'Perfil resolvido',
        galleryGroups: <TenantAdminAccountProfileGalleryGroup>[_galleryGroup()],
      );
      final profilesRepository = _FakeAccountProfilesRepository(
        [
          tenantAdminAccountProfileFromRaw(
            id: 'profile-1',
            accountId: 'acc-1',
            profileType: 'venue',
            displayName: 'Perfil remoto',
          ),
        ],
        [
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
              hasGallery: TenantAdminFlagValue(true),
            ),
          ),
        ],
      );
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );

      await controller.loadEditProfile(
        'profile-1',
        prefetchedProfile: prefetchedProfile,
      );

      expect(profilesRepository.fetchAccountProfileCalls, 0);
      expect(
        controller.accountProfileStreamValue.value?.displayName,
        'Perfil resolvido',
      );
      expect(controller.editStateStreamValue.value.galleryGroups, hasLength(1));
    },
  );

  test(
    'loadEditProfile expands the first persisted WhatsApp CTA editor',
    () async {
      final whatsappChannel = BellugaContactChannel(
        id: 'whatsapp-primary',
        type: BellugaContactChannelType.whatsapp,
        value: '+55 (27) 99999-1111',
        initialMessages: const <BellugaContactInitialMessage>[
          BellugaContactInitialMessage(
            id: 'whatsapp-cta-1',
            cta: 'Falar com a Ananda',
            message: 'Olá, gostaria de saber mais.',
          ),
        ],
      );
      final profile = tenantAdminAccountProfileFromRaw(
        id: 'profile-ananda',
        accountId: 'account-ananda',
        profileType: 'artist',
        displayName: 'Ananda',
        contactChannels: <BellugaContactChannel>[whatsappChannel],
      );
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: _FakeAccountProfilesRepository(
          <TenantAdminAccountProfile>[profile],
          const <TenantAdminProfileTypeDefinition>[],
        ),
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );

      await controller.loadEditProfile('profile-ananda');

      expect(
        controller.editStateStreamValue.value.expandedContactCtaDraftKey,
        'persisted:whatsapp-primary',
      );
      expect(
        controller
            .editStateStreamValue
            .value
            .contactChannelDrafts
            .single
            .initialMessages
            .single
            .cta,
        'Falar com a Ananda',
      );
      controller.dispose();
    },
  );

  test(
    'loadNestedProfileCandidates requests backend queryable-only candidates and excludes current profile',
    () async {
      final profilesRepository = _FakeAccountProfilesRepository([
        tenantAdminAccountProfileFromRaw(
          id: 'profile-1',
          accountId: 'acc-1',
          profileType: 'venue',
          displayName: 'Perfil atual',
          slug: 'perfil-atual',
        ),
        tenantAdminAccountProfileFromRaw(
          id: 'profile-2',
          accountId: 'acc-2',
          profileType: 'artist',
          displayName: 'Perfil candidato',
          slug: 'perfil-candidato',
        ),
      ], const []);
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );

      await controller.loadNestedProfileCandidates(
        excludeProfileId: 'profile-1',
      );

      expect(profilesRepository.fetchAccountProfilesPageCalls, 1);
      expect(profilesRepository.lastFetchPage, 1);
      expect(profilesRepository.lastFetchPageSize, 20);
      expect(profilesRepository.lastFetchQueryableOnly, isTrue);
      expect(profilesRepository.lastFetchExcludeAccountProfileId, 'profile-1');
      expect(
        controller.nestedProfileCandidatesStreamValue.value
            .map((profile) => profile.id)
            .toList(growable: false),
        ['profile-2'],
      );
    },
  );

  test(
    'loadContactSourceCandidates uses only the dedicated server candidate query',
    () async {
      final profilesRepository = _FakeAccountProfilesRepository([
        tenantAdminAccountProfileFromRaw(
          id: 'profile-current',
          accountId: 'acc-1',
          profileType: 'venue',
          displayName: 'Perfil atual',
        ),
        tenantAdminAccountProfileFromRaw(
          id: 'profile-source',
          accountId: 'acc-2',
          profileType: 'contact_source',
          displayName: 'Perfil de origem',
        ),
      ], const []);
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );

      await controller.loadContactSourceCandidates(
        excludeProfileId: 'profile-current',
      );

      expect(profilesRepository.fetchContactSourceCandidatesPageCalls, 1);
      expect(profilesRepository.fetchAccountProfilesCalls, 0);
      expect(profilesRepository.fetchAccountProfilesPageCalls, 0);
      expect(
        controller.contactSourceCandidatesStreamValue.value
            .map((profile) => profile.id)
            .toList(growable: false),
        ['profile-source'],
      );
    },
  );

  test(
    'loadContactSourceCandidates reruns the latest initial request after an in-flight request',
    () async {
      final burstLevel =
          int.tryParse(Platform.environment['DELPHI_RACE_BURST_LEVEL'] ?? '') ??
          2;
      final profilesRepository = _FakeAccountProfilesRepository([
        tenantAdminAccountProfileFromRaw(
          id: 'profile-a',
          accountId: 'acc-1',
          profileType: 'contact_source',
          displayName: 'Perfil A',
        ),
        tenantAdminAccountProfileFromRaw(
          id: 'profile-b',
          accountId: 'acc-2',
          profileType: 'contact_source',
          displayName: 'Perfil B',
        ),
        tenantAdminAccountProfileFromRaw(
          id: 'profile-c',
          accountId: 'acc-3',
          profileType: 'contact_source',
          displayName: 'Perfil C',
        ),
      ], const []);
      final gate = Completer<void>();
      profilesRepository.contactSourceCandidatesGate = gate;
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );

      final first = controller.loadContactSourceCandidates(
        excludeProfileId: 'profile-a',
      );
      await Future<void>.delayed(Duration.zero);
      final pendingExclusions = List<String>.generate(
        burstLevel - 1,
        (index) => index.isEven ? 'profile-b' : 'profile-c',
      );
      for (final exclusion in pendingExclusions) {
        await controller.loadContactSourceCandidates(
          excludeProfileId: exclusion,
        );
      }
      final latestExclusion = pendingExclusions.last;
      gate.complete();
      await first;
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(profilesRepository.fetchContactSourceCandidatesPageCalls, 2);
      expect(profilesRepository.contactSourceCandidateExclusions, [
        'profile-a',
        latestExclusion,
      ]);
      expect(
        controller.contactSourceCandidatesStreamValue.value
            .map((profile) => profile.id)
            .toList(growable: false),
        latestExclusion == 'profile-b'
            ? ['profile-a', 'profile-c']
            : ['profile-a', 'profile-b'],
      );
    },
  );

  test(
    'loadContactSourceCandidates preserves loaded candidates when a later page fails',
    () async {
      final profilesRepository = _FakeAccountProfilesRepository(
        const <TenantAdminAccountProfile>[],
        const <TenantAdminProfileTypeDefinition>[],
      );
      final source = tenantAdminAccountProfileFromRaw(
        id: 'profile-source',
        accountId: 'acc-source',
        profileType: 'contact_source',
        displayName: 'Perfil de origem',
      );
      profilesRepository.contactSourceCandidatePageOverrides[1] =
          tenantAdminPagedResultFromRaw(
            items: [source],
            hasMore: true,
            currentPage: 1,
            pageSize: 50,
          );
      profilesRepository.contactSourceCandidateFailingPages.add(2);
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );

      await controller.loadContactSourceCandidates();
      await controller.loadNextContactSourceCandidatesPage();

      expect(controller.contactSourceCandidatesStreamValue.value, [source]);
      expect(
        controller.contactSourceCandidatesHasMoreStreamValue.value,
        isFalse,
      );
      expect(
        controller.contactSourceCandidatesErrorStreamValue.value,
        contains('contact-source page 2 failed'),
      );
    },
  );

  test(
    'caps create and edit WhatsApp CTAs at the definition-owned limit and keeps one controller-selected editor',
    () {
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: _FakeAccountProfilesRepository([], []),
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );
      final maxInitialMessages = BellugaContactChannelRegistry.canonical
          .require(BellugaContactChannelType.whatsapp)
          .capabilities
          .maxInitialMessages;

      controller.addCreateContactChannel(BellugaContactChannelType.whatsapp);
      final createDraftKey = controller
          .createStateStreamValue
          .value
          .contactChannelDrafts
          .single
          .draftKey;
      controller.toggleCreateContactCtaEditor(createDraftKey);
      for (var index = 0; index < maxInitialMessages + 1; index += 1) {
        controller.addCreateContactInitialMessage(createDraftKey);
      }

      expect(
        controller.createStateStreamValue.value.expandedContactCtaDraftKey,
        createDraftKey,
      );
      expect(
        controller
            .createStateStreamValue
            .value
            .contactChannelDrafts
            .single
            .initialMessages,
        hasLength(maxInitialMessages),
      );
      expect(
        controller.createErrorMessageStreamValue.value,
        'Limite de CTAs do WhatsApp atingido.',
      );

      controller.addEditContactChannel(BellugaContactChannelType.whatsapp);
      final editDraftKey = controller
          .editStateStreamValue
          .value
          .contactChannelDrafts
          .single
          .draftKey;
      controller.toggleEditContactCtaEditor(editDraftKey);
      for (var index = 0; index < maxInitialMessages + 1; index += 1) {
        controller.addEditContactInitialMessage(editDraftKey);
      }

      expect(
        controller.editStateStreamValue.value.expandedContactCtaDraftKey,
        editDraftKey,
      );
      expect(
        controller
            .editStateStreamValue
            .value
            .contactChannelDrafts
            .single
            .initialMessages,
        hasLength(maxInitialMessages),
      );
      expect(
        controller.editErrorMessageStreamValue.value,
        'Limite de CTAs do WhatsApp atingido.',
      );
      controller.dispose();
    },
  );

  test(
    'searchNestedProfileCandidates keeps selected profiles published across query windows',
    () async {
      final profilesRepository = _FakeAccountProfilesRepository([
        tenantAdminAccountProfileFromRaw(
          id: 'profile-selected',
          accountId: 'acc-1',
          profileType: 'venue',
          displayName: 'Conta Parceira',
          slug: 'conta-parceira',
        ),
        tenantAdminAccountProfileFromRaw(
          id: 'profile-runtime',
          accountId: 'acc-2',
          profileType: 'artist',
          displayName: 'Runtime Sender',
          slug: 'runtime-sender',
        ),
        tenantAdminAccountProfileFromRaw(
          id: 'profile-other',
          accountId: 'acc-3',
          profileType: 'publisher',
          displayName: 'Outra Conta',
          slug: 'outra-conta',
        ),
      ], const []);
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );

      controller.addCreateNestedProfileGroup();
      final groupId =
          controller.createStateStreamValue.value.nestedProfileGroups.single.id;

      await controller.loadNestedProfileCandidates();
      controller.toggleCreateNestedProfileGroupMember(
        groupId: groupId,
        profileId: 'profile-selected',
        selected: true,
      );

      controller.searchNestedProfileCandidates('runtime');
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await Future<void>.delayed(Duration.zero);

      expect(profilesRepository.lastFetchSearch, 'runtime');
      expect(
        controller.nestedProfileCandidatesStreamValue.value
            .map((profile) => profile.id)
            .toList(growable: false),
        containsAll(<String>['profile-selected', 'profile-runtime']),
      );
      expect(
        controller.nestedProfileCandidatesStreamValue.value.map(
          (profile) => profile.id,
        ),
        isNot(contains('profile-other')),
      );
    },
  );

  test(
    'submitTaxonomySelectionUpdate resolves profileType and sends string bio/content',
    () async {
      final profilesRepository = _FakeAccountProfilesRepository(
        [
          tenantAdminAccountProfileFromRaw(
            id: 'profile-1',
            accountId: 'acc-1',
            profileType: 'artist',
            displayName: 'Perfil',
            slug: 'perfil',
            bio: null,
            content: null,
          ),
        ],
        [
          tenantAdminProfileTypeDefinitionFromRaw(
            type: 'artist',
            label: 'Artist',
            allowedTaxonomies: ['music-style'],
            capabilities: TenantAdminProfileTypeCapabilities(
              isFavoritable: TenantAdminFlagValue(true),
              isPoiEnabled: TenantAdminFlagValue(false),
              hasBio: TenantAdminFlagValue(true),
              hasContent: TenantAdminFlagValue(true),
              hasTaxonomies: TenantAdminFlagValue(true),
              hasAvatar: TenantAdminFlagValue(true),
              hasCover: TenantAdminFlagValue(true),
              hasEvents: TenantAdminFlagValue(true),
            ),
          ),
        ],
      );
      final accountsRepository = _FakeAccountsRepository();
      final TenantAdminLocationSelectionContract locationSelectionService =
          TenantAdminLocationSelectionService();
      final taxonomiesRepository = _FakeTaxonomiesRepository();

      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: accountsRepository,
        taxonomiesRepository: taxonomiesRepository,
        locationSelectionService: locationSelectionService,
      );

      controller.accountProfileStreamValue.addValue(
        tenantAdminAccountProfileFromRaw(
          id: 'profile-1',
          accountId: 'acc-1',
          profileType: 'artist',
          displayName: 'Perfil',
        ),
      );
      controller.profileTypesStreamValue.addValue([
        tenantAdminProfileTypeDefinitionFromRaw(
          type: 'artist',
          label: 'Artist',
          allowedTaxonomies: ['music-style'],
          capabilities: TenantAdminProfileTypeCapabilities(
            isFavoritable: TenantAdminFlagValue(true),
            isPoiEnabled: TenantAdminFlagValue(false),
            hasBio: TenantAdminFlagValue(true),
            hasContent: TenantAdminFlagValue(true),
            hasTaxonomies: TenantAdminFlagValue(true),
            hasAvatar: TenantAdminFlagValue(true),
            hasCover: TenantAdminFlagValue(true),
            hasEvents: TenantAdminFlagValue(true),
          ),
        ),
      ]);

      final saved = await controller.submitTaxonomySelectionUpdate(
        accountProfileId: 'profile-1',
        profileType: null,
        taxonomyTerms: (() {
          final terms = TenantAdminTaxonomyTerms();
          terms.add(
            tenantAdminTaxonomyTermFromRaw(type: 'music-style', value: 'rock'),
          );
          return terms;
        })(),
        bio: null,
        content: null,
      );

      expect(saved, isTrue);
      expect(profilesRepository.lastUpdateProfileType, 'artist');
      expect(profilesRepository.lastUpdateBio, '');
      expect(profilesRepository.lastUpdateContent, '');
    },
  );

  test('loadAccountForCreate stores resolved account slug in stream', () async {
    final profilesRepository = _FakeAccountProfilesRepository([], []);
    final accountsRepository = _FakeAccountsRepository();
    final TenantAdminLocationSelectionContract locationSelectionService =
        TenantAdminLocationSelectionService();
    final taxonomiesRepository = _FakeTaxonomiesRepository();

    final controller = TenantAdminAccountProfilesController(
      profilesRepository: profilesRepository,
      accountsRepository: accountsRepository,
      taxonomiesRepository: taxonomiesRepository,
      locationSelectionService: locationSelectionService,
    );

    await controller.loadAccountForCreate('yuri-dias');

    expect(controller.accountStreamValue.value, isNotNull);
    expect(controller.accountStreamValue.value!.slug, 'yuri-dias');
    expect(controller.createAccountIdStreamValue.value, 'acc-1');
  });

  test(
    'updateAccount syncs canonical account stream without manual reload',
    () async {
      final profilesRepository = _FakeAccountProfilesRepository([], []);
      final accountsRepository = _FakeAccountsRepository();
      final TenantAdminLocationSelectionContract locationSelectionService =
          TenantAdminLocationSelectionService();
      final taxonomiesRepository = _FakeTaxonomiesRepository();

      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: accountsRepository,
        taxonomiesRepository: taxonomiesRepository,
        locationSelectionService: locationSelectionService,
      );

      await controller.loadAccountDetail('yuri-dias');
      final updated = await controller.updateAccount(
        accountSlug: 'yuri-dias',
        name: 'Conta atualizada',
        slug: 'yuri-atualizado',
        ownershipState: TenantAdminOwnershipState.unmanaged,
      );

      expect(updated, isNotNull);
      expect(controller.accountStreamValue.value, isNotNull);
      expect(controller.accountStreamValue.value!.name, 'Conta atualizada');
      expect(controller.accountStreamValue.value!.slug, 'yuri-atualizado');
      expect(
        controller.accountStreamValue.value!.ownershipState,
        TenantAdminOwnershipState.unmanaged,
      );
      expect(
        accountsRepository.lastUpdatedOwnershipState,
        TenantAdminOwnershipState.unmanaged,
      );
    },
  );
}

TenantAdminAccountProfileGalleryGroup _galleryGroup() {
  return TenantAdminAccountProfileGalleryGroup(
    groupIdValue: TenantAdminNestedProfileGroupTextValue('group-1'),
    subtitleValue: TenantAdminNestedProfileGroupTextValue('Ambiente'),
    orderValue: TenantAdminNestedProfileGroupOrderValue(0),
    items: <TenantAdminAccountProfileGalleryItem>[
      TenantAdminAccountProfileGalleryItem(
        itemIdValue: TenantAdminNestedProfileGroupTextValue('item-1'),
        descriptionValue: TenantAdminOptionalTextValue()
          ..parse('Vista para o palco'),
        orderValue: TenantAdminNestedProfileGroupOrderValue(0),
        imageUrlValue: TenantAdminOptionalUrlValue()
          ..parse('https://tenant.test/gallery/image.png'),
        thumbUrlValue: TenantAdminOptionalUrlValue()
          ..parse('https://tenant.test/gallery/thumb.png'),
        cardUrlValue: TenantAdminOptionalUrlValue()
          ..parse('https://tenant.test/gallery/card.png'),
        modalUrlValue: TenantAdminOptionalUrlValue()
          ..parse('https://tenant.test/gallery/modal.png'),
      ),
    ],
  );
}
