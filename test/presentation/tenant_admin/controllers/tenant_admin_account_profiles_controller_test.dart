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
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_candidate_selection_summary.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_gallery_group.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_group_head_mutation_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_group_member_mutation_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_group_member_page.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_accounts_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_count_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_account_profile_id_value.dart';
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
  int? lastUpdateAggregateRevision;
  int fetchAccountProfileCalls = 0;
  String? lastFetchedProfileId;
  bool? lastFetchQueryableOnly;
  String? lastFetchExcludeAccountProfileId;
  int? lastFetchPage;
  int? lastFetchPageSize;
  String? lastFetchSearch;
  String? lastFetchProfileType;
  String? lastFetchContactMode;
  bool? lastFetchContactChannelsEnabledOnly;
  int fetchAccountProfilesPageCalls = 0;
  int fetchAccountProfilesCalls = 0;
  final Map<String, TenantAdminAccountProfile> accountProfileFetchOverrides =
      <String, TenantAdminAccountProfile>{};
  TenantAdminAccountProfile? updateAccountProfileOverride;
  final List<String?> fetchAccountProfilesPageExclusions = [];
  final List<String?> fetchAccountProfilesPageProfileTypes = [];
  final List<String?> fetchAccountProfilesPageContactModes = [];
  final List<bool?> fetchAccountProfilesPageContactChannelsEnabledOnly = [];
  Completer<void>? fetchAccountProfilesPageGate;
  final Set<int> fetchAccountProfilesPageFailingPages = <int>{};
  final Map<int, TenantAdminPagedResult<TenantAdminAccountProfile>>
  fetchAccountProfilesPageOverrides =
      <int, TenantAdminPagedResult<TenantAdminAccountProfile>>{};
  List<TenantAdminNestedProfileGroup>? lastCreateNestedProfileGroups;
  List<TenantAdminNestedProfileGroup>? lastUpdateNestedProfileGroups;
  List<TenantAdminAccountProfileGalleryUpdateGroup>? lastGalleryGroups;
  Object? createAccountProfileError;
  int createNestedProfileGroupCalls = 0;
  String? lastCreateNestedProfileGroupProfileId;
  String? lastCreateNestedProfileGroupLabel;
  Completer<void>? createNestedProfileGroupGate;
  Object? createNestedProfileGroupError;
  int deleteNestedProfileGroupCalls = 0;
  String? lastDeleteNestedProfileGroupProfileId;
  String? lastDeleteNestedProfileGroupGroupId;
  Completer<void>? deleteNestedProfileGroupGate;
  Object? deleteNestedProfileGroupError;
  String? lastNestedGroupMembersProfileId;
  String? lastNestedGroupMembersGroupId;
  int? lastNestedGroupMembersPerPage;
  String? lastNestedGroupMembersCursor;
  String? lastPatchNestedGroupMembersProfileId;
  String? lastPatchNestedGroupMembersGroupId;
  int? lastPatchNestedGroupMembersAggregateRevision;
  List<String> lastPatchNestedGroupAddIds = <String>[];
  List<String> lastPatchNestedGroupRemoveIds = <String>[];
  Object? patchNestedGroupMembersError;
  int forceDeleteAccountProfileCalls = 0;
  int deleteAccountProfileCalls = 0;
  final Map<String, List<TenantAdminNestedGroupMemberPage>>
  nestedGroupMemberPagesByGroupId =
      <String, List<TenantAdminNestedGroupMemberPage>>{};
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
    TenantAdminAccountProfilesRepoString? profileType,
    TenantAdminAccountProfilesRepoString? contactMode,
    TenantAdminAccountProfilesRepoBool? contactChannelsEnabledOnly,
    TenantAdminAccountProfilesRepoBool? queryableOnly,
    TenantAdminAccountProfilesRepoString? excludeAccountProfileId,
  }) async {
    fetchAccountProfilesPageCalls += 1;
    lastFetchPage = page.value;
    lastFetchPageSize = pageSize.value;
    lastFetchSearch = search?.value;
    lastFetchProfileType = profileType?.value;
    lastFetchContactMode = contactMode?.value;
    lastFetchContactChannelsEnabledOnly = contactChannelsEnabledOnly?.value;
    lastFetchQueryableOnly = queryableOnly?.value;
    lastFetchExcludeAccountProfileId = excludeAccountProfileId?.value;
    fetchAccountProfilesPageExclusions.add(excludeAccountProfileId?.value);
    fetchAccountProfilesPageProfileTypes.add(profileType?.value);
    fetchAccountProfilesPageContactModes.add(contactMode?.value);
    fetchAccountProfilesPageContactChannelsEnabledOnly.add(
      contactChannelsEnabledOnly?.value,
    );
    final gate = fetchAccountProfilesPageGate;
    if (gate != null) {
      await gate.future;
    }
    if (fetchAccountProfilesPageFailingPages.contains(page.value)) {
      throw StateError('account-profiles page ${page.value} failed');
    }
    final overriddenPage = fetchAccountProfilesPageOverrides[page.value];
    if (overriddenPage != null) {
      return overriddenPage;
    }
    final filtered = _filterProfiles(
      search: search?.value,
      profileType: profileType?.value,
      contactMode: contactMode?.value,
      contactChannelsEnabledOnly: contactChannelsEnabledOnly?.value ?? false,
      queryableOnly: queryableOnly?.value ?? false,
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
    final createError = createAccountProfileError;
    if (createError != null) {
      throw createError;
    }
    lastCreateNestedProfileGroups = nestedProfileGroups;
    final created = tenantAdminAccountProfileFromRaw(
      id: 'profile-$createProfileCalls',
      accountId: accountId.value,
      profileType: profileType.value,
      displayName: displayName.value,
      aggregateRevision: 1,
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
    final override = accountProfileFetchOverrides[accountProfileId.value];
    if (override != null) {
      return override;
    }
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
    TenantAdminAccountProfilesRepoInt? aggregateRevision,
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
    lastUpdateAggregateRevision = aggregateRevision?.value;
    lastUpdateNestedProfileGroups = nestedProfileGroups;
    return updateAccountProfileOverride ?? _profiles.first;
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
  Future<TenantAdminNestedGroupMemberPage> fetchNestedGroupMembersPage({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    required TenantAdminAccountProfilesRepoString groupId,
    TenantAdminAccountProfilesRepoInt? perPage,
    TenantAdminAccountProfilesRepoString? cursor,
  }) async {
    lastNestedGroupMembersProfileId = accountProfileId.value;
    lastNestedGroupMembersGroupId = groupId.value;
    lastNestedGroupMembersPerPage = perPage?.value;
    lastNestedGroupMembersCursor = cursor?.value;
    final pages =
        nestedGroupMemberPagesByGroupId[groupId.value] ??
        <TenantAdminNestedGroupMemberPage>[
          TenantAdminNestedGroupMemberPage(
            items: const <TenantAdminAccountProfileSelectionSummary>[],
            nextCursorValue: TenantAdminOptionalTextValue(),
          ),
        ];
    if (cursor == null || cursor.value.isEmpty) {
      return pages.first;
    }
    final index = pages.indexWhere((page) => page.nextCursor == cursor.value);
    if (index < 0 || index + 1 >= pages.length) {
      return pages.last;
    }
    return pages[index + 1];
  }

  @override
  Future<TenantAdminNestedGroupMemberPage> fetchAllNestedGroupMembers({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    required TenantAdminAccountProfilesRepoString groupId,
  }) async {
    lastNestedGroupMembersProfileId = accountProfileId.value;
    lastNestedGroupMembersGroupId = groupId.value;
    lastNestedGroupMembersPerPage = 50;
    final pages =
        nestedGroupMemberPagesByGroupId[groupId.value] ??
        <TenantAdminNestedGroupMemberPage>[
          TenantAdminNestedGroupMemberPage(
            items: const <TenantAdminAccountProfileSelectionSummary>[],
            nextCursorValue: TenantAdminOptionalTextValue(),
          ),
        ];
    final allItems = pages.expand((page) => page.items).toList(growable: false);
    lastNestedGroupMembersCursor = pages.length > 1
        ? pages.first.nextCursor
        : null;
    return TenantAdminNestedGroupMemberPage(
      items: allItems,
      nextCursorValue: TenantAdminOptionalTextValue(),
    );
  }

  @override
  Future<TenantAdminNestedGroupMemberMutationResult> patchNestedGroupMembers({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    required TenantAdminAccountProfilesRepoString groupId,
    List<TenantAdminAccountProfilesRepoString> addIds = const [],
    List<TenantAdminAccountProfilesRepoString> removeIds = const [],
  }) async {
    final error = patchNestedGroupMembersError;
    if (error != null) {
      throw error;
    }
    lastPatchNestedGroupMembersProfileId = accountProfileId.value;
    lastPatchNestedGroupMembersGroupId = groupId.value;
    lastPatchNestedGroupAddIds = addIds.map((entry) => entry.value).toList();
    lastPatchNestedGroupRemoveIds = removeIds
        .map((entry) => entry.value)
        .toList();
    return TenantAdminNestedGroupMemberMutationResult(
      memberCountValue: TenantAdminCountValue(2),
    );
  }

  @override
  Future<TenantAdminNestedGroupHeadMutationResult> createNestedProfileGroup({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    required TenantAdminAccountProfilesRepoString label,
  }) async {
    createNestedProfileGroupCalls += 1;
    lastCreateNestedProfileGroupProfileId = accountProfileId.value;
    lastCreateNestedProfileGroupLabel = label.value;
    final gate = createNestedProfileGroupGate;
    if (gate != null) {
      await gate.future;
    }
    final error = createNestedProfileGroupError;
    if (error != null) {
      throw error;
    }

    final profile = _profileById(accountProfileId.value);
    final nextGroups = <TenantAdminNestedProfileGroup>[
      ...profile.nestedProfileGroups,
      TenantAdminNestedProfileGroup(
        idValue: TenantAdminNestedProfileGroupTextValue(
          _slugifyGroupId(label.value),
        ),
        labelValue: TenantAdminNestedProfileGroupTextValue(label.value),
        orderValue: TenantAdminNestedProfileGroupOrderValue(
          profile.nestedProfileGroups.length,
        ),
        memberCountValue: TenantAdminCountValue(0),
      ),
    ];
    _replaceProfileWithNestedGroups(accountProfileId.value, nextGroups);

    return TenantAdminNestedGroupHeadMutationResult(groups: nextGroups);
  }

  @override
  Future<TenantAdminNestedGroupHeadMutationResult> deleteNestedProfileGroup({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    required TenantAdminAccountProfilesRepoString groupId,
  }) async {
    deleteNestedProfileGroupCalls += 1;
    lastDeleteNestedProfileGroupProfileId = accountProfileId.value;
    lastDeleteNestedProfileGroupGroupId = groupId.value;
    final gate = deleteNestedProfileGroupGate;
    if (gate != null) {
      await gate.future;
    }
    final error = deleteNestedProfileGroupError;
    if (error != null) {
      throw error;
    }

    final profile = _profileById(accountProfileId.value);
    final nextGroups = profile.nestedProfileGroups
        .where((group) => group.id != groupId.value)
        .toList(growable: false);
    _replaceProfileWithNestedGroups(accountProfileId.value, nextGroups);

    return TenantAdminNestedGroupHeadMutationResult(
      deletedGroupIdValue: TenantAdminOptionalTextValue()..parse(groupId.value),
      groups: nextGroups,
    );
  }

  @override
  Future<void> deleteAccountProfile(
    TenantAdminAccountProfilesRepoString accountProfileId,
  ) async {
    deleteAccountProfileCalls += 1;
  }

  @override
  Future<TenantAdminAccountProfile> restoreAccountProfile(
    TenantAdminAccountProfilesRepoString accountProfileId,
  ) async {
    return _profiles.first;
  }

  @override
  Future<void> forceDeleteAccountProfile(
    TenantAdminAccountProfilesRepoString accountProfileId,
  ) async {
    forceDeleteAccountProfileCalls += 1;
  }

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
    String? profileType,
    String? contactMode,
    bool queryableOnly = false,
    bool contactChannelsEnabledOnly = false,
    String? excludeAccountProfileId,
  }) {
    final normalizedSearch = search?.trim().toLowerCase() ?? '';
    final normalizedProfileType = profileType?.trim();
    final normalizedContactMode = contactMode?.trim();
    final queryableTypes = _types
        .where((profileType) => profileType.capabilities.isQueryable)
        .map((profileType) => profileType.type)
        .toSet();
    final contactEnabledTypes = _types
        .where((profileType) => profileType.capabilities.hasContactChannels)
        .map((profileType) => profileType.type)
        .toSet();
    return _profiles
        .where((profile) {
          if (excludeAccountProfileId != null &&
              excludeAccountProfileId.isNotEmpty &&
              profile.id == excludeAccountProfileId) {
            return false;
          }
          if (normalizedProfileType != null &&
              normalizedProfileType.isNotEmpty &&
              profile.profileType != normalizedProfileType) {
            return false;
          }
          if (normalizedContactMode != null &&
              normalizedContactMode.isNotEmpty &&
              profile.contactMode.rawValue != normalizedContactMode) {
            return false;
          }
          if (queryableOnly &&
              queryableTypes.isNotEmpty &&
              !queryableTypes.contains(profile.profileType)) {
            return false;
          }
          if (contactChannelsEnabledOnly &&
              contactEnabledTypes.isNotEmpty &&
              !contactEnabledTypes.contains(profile.profileType)) {
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

  TenantAdminAccountProfile _profileById(String profileId) {
    return accountProfileFetchOverrides[profileId] ??
        _profiles.firstWhere(
          (profile) => profile.id == profileId,
          orElse: () => _profiles.first,
        );
  }

  void _replaceProfileWithNestedGroups(
    String profileId,
    List<TenantAdminNestedProfileGroup> groups,
  ) {
    final current = _profileById(profileId);
    final updated = tenantAdminAccountProfileFromRaw(
      id: current.id,
      accountId: current.accountId,
      profileType: current.profileType,
      displayName: current.displayName,
      slug: current.slug,
      aggregateRevision: current.aggregateRevision,
      avatarUrl: current.avatarUrl,
      coverUrl: current.coverUrl,
      bio: current.bio,
      content: current.content,
      location: current.location,
      taxonomyTerms: current.taxonomyTerms,
      galleryGroups: current.galleryGroups,
      nestedProfileGroups: groups,
      ownershipState: current.ownershipState,
      contactMode: current.contactMode,
      contactSourceAccountProfileId: current.contactSourceAccountProfileId,
      contactChannels: current.contactChannels,
      contactBubbleChannelId: current.contactBubbleChannelId,
      effectiveContactChannels: current.effectiveContactChannels,
      contactSourceProfile: current.contactSourceProfile,
      effectiveContactSourceProfile: current.effectiveContactSourceProfile,
    );
    _profiles = _profiles
        .map((profile) => profile.id == profileId ? updated : profile)
        .toList(growable: false);
    accountProfileFetchOverrides[profileId] = updated;
  }

  String _slugifyGroupId(String label) {
    final normalized = label
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return normalized.isEmpty
        ? 'grupo-$createNestedProfileGroupCalls'
        : normalized;
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
    'createProfile ignores nested groups on aggregate create and does not call members subresource delta',
    () async {
      final profilesRepository = _FakeAccountProfilesRepository(
        const <TenantAdminAccountProfile>[],
        <TenantAdminProfileTypeDefinition>[
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
      final groups = <TenantAdminNestedProfileGroup>[
        TenantAdminNestedProfileGroup(
          idValue: TenantAdminNestedProfileGroupTextValue('parceiros'),
          labelValue: TenantAdminNestedProfileGroupTextValue('Parceiros'),
          orderValue: TenantAdminNestedProfileGroupOrderValue(0),
          accountProfileIdValues: <TenantAdminNestedProfileGroupTextValue>[
            TenantAdminNestedProfileGroupTextValue('profile-a'),
          ],
        ),
      ];

      final created = await controller.createProfile(
        accountId: 'acc-1',
        profileType: 'venue',
        displayName: 'Perfil',
        nestedProfileGroups: groups,
      );

      expect(profilesRepository.createProfileCalls, 1);
      expect(profilesRepository.lastCreateNestedProfileGroups, isEmpty);
      expect(profilesRepository.lastPatchNestedGroupMembersProfileId, isNull);
      expect(profilesRepository.lastPatchNestedGroupMembersGroupId, isNull);
      expect(
        profilesRepository.lastPatchNestedGroupMembersAggregateRevision,
        isNull,
      );
      expect(profilesRepository.lastPatchNestedGroupAddIds, isEmpty);
      expect(profilesRepository.lastPatchNestedGroupRemoveIds, isEmpty);
      expect(created.aggregateRevision, 1);
      expect(controller.accountProfileStreamValue.value?.aggregateRevision, 1);
    },
  );

  test(
    'createProfile propagates repository create failure without compensating controller delete',
    () async {
      final profilesRepository = _FakeAccountProfilesRepository(
        const <TenantAdminAccountProfile>[],
        <TenantAdminProfileTypeDefinition>[
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
      profilesRepository.createAccountProfileError = StateError(
        'create failed',
      );
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );

      await expectLater(
        controller.createProfile(
          accountId: 'acc-1',
          profileType: 'venue',
          displayName: 'Perfil',
          nestedProfileGroups: <TenantAdminNestedProfileGroup>[
            TenantAdminNestedProfileGroup(
              idValue: TenantAdminNestedProfileGroupTextValue('parceiros'),
              labelValue: TenantAdminNestedProfileGroupTextValue('Parceiros'),
              orderValue: TenantAdminNestedProfileGroupOrderValue(0),
              accountProfileIdValues: <TenantAdminNestedProfileGroupTextValue>[
                TenantAdminNestedProfileGroupTextValue('profile-a'),
              ],
            ),
          ],
        ),
        throwsA(isA<StateError>()),
      );

      expect(profilesRepository.createProfileCalls, 1);
      expect(profilesRepository.lastPatchNestedGroupMembersProfileId, isNull);
      expect(profilesRepository.forceDeleteAccountProfileCalls, 0);
      expect(profilesRepository.deleteAccountProfileCalls, 0);
    },
  );

  test(
    'createEditNestedProfileGroupHead keeps one in-flight command and adopts returned metadata',
    () async {
      final profilesRepository = _FakeAccountProfilesRepository([
        tenantAdminAccountProfileFromRaw(
          id: 'profile-1',
          accountId: 'acc-1',
          profileType: 'venue',
          displayName: 'Perfil',
          aggregateRevision: 4,
        ),
      ], const <TenantAdminProfileTypeDefinition>[]);
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );
      await controller.loadEditProfile('profile-1');

      final gate = Completer<void>();
      profilesRepository.createNestedProfileGroupGate = gate;

      final first = controller.createEditNestedProfileGroupHead(
        accountProfileId: 'profile-1',
        label: 'Parceiros',
      );
      final duplicate = controller.createEditNestedProfileGroupHead(
        accountProfileId: 'profile-1',
        label: 'Ignorado',
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.editNestedGroupMutationBusyStreamValue.value, isTrue);
      expect(profilesRepository.createNestedProfileGroupCalls, 1);
      expect(
        profilesRepository.lastCreateNestedProfileGroupProfileId,
        'profile-1',
      );
      expect(profilesRepository.lastCreateNestedProfileGroupLabel, 'Parceiros');

      gate.complete();
      await Future.wait(<Future<void>>[first, duplicate]);

      expect(controller.editNestedGroupMutationBusyStreamValue.value, isFalse);
      expect(controller.editErrorMessageStreamValue.value, isNull);
      expect(
        controller.editStateStreamValue.value.nestedProfileGroups
            .map((group) => group.label)
            .toList(growable: false),
        <String>['Parceiros'],
      );
      expect(
        controller.accountProfileStreamValue.value?.nestedProfileGroups
            .map((group) => group.id)
            .toList(growable: false),
        <String>['parceiros'],
      );
    },
  );

  test(
    'deleteEditNestedProfileGroupHead reports failure and releases busy state',
    () async {
      final profilesRepository = _FakeAccountProfilesRepository([
        tenantAdminAccountProfileFromRaw(
          id: 'profile-1',
          accountId: 'acc-1',
          profileType: 'venue',
          displayName: 'Perfil',
          aggregateRevision: 4,
          nestedProfileGroups: <TenantAdminNestedProfileGroup>[
            TenantAdminNestedProfileGroup(
              idValue: TenantAdminNestedProfileGroupTextValue('parceiros'),
              labelValue: TenantAdminNestedProfileGroupTextValue('Parceiros'),
              orderValue: TenantAdminNestedProfileGroupOrderValue(0),
              memberCountValue: TenantAdminCountValue(2),
            ),
          ],
        ),
      ], const <TenantAdminProfileTypeDefinition>[]);
      profilesRepository.deleteNestedProfileGroupError = StateError(
        'delete failed',
      );
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );
      await controller.loadEditProfile('profile-1');

      await controller.deleteEditNestedProfileGroupHead(
        accountProfileId: 'profile-1',
        groupId: 'parceiros',
      );

      expect(controller.editNestedGroupMutationBusyStreamValue.value, isFalse);
      expect(profilesRepository.deleteNestedProfileGroupCalls, 1);
      expect(
        profilesRepository.lastDeleteNestedProfileGroupProfileId,
        'profile-1',
      );
      expect(
        profilesRepository.lastDeleteNestedProfileGroupGroupId,
        'parceiros',
      );
      expect(
        controller.editErrorMessageStreamValue.value,
        contains('delete failed'),
      );
      expect(
        controller.editStateStreamValue.value.nestedProfileGroups
            .map((group) => group.id)
            .toList(growable: false),
        <String>['parceiros'],
      );
    },
  );

  test(
    'switching create contact mode to mirrored clears draft bubble selection and omits local drafts from save payload',
    () {
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: _FakeAccountProfilesRepository(
          const <TenantAdminAccountProfile>[],
          const <TenantAdminProfileTypeDefinition>[],
        ),
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );

      controller.addCreateContactChannel(BellugaContactChannelType.whatsapp);
      final draft = controller
          .createStateStreamValue
          .value
          .contactChannelDrafts
          .single
          .copyWith(value: '+55 (27) 99999-0000');
      controller.updateCreateContactChannel(draft);
      controller.selectCreateContactBubble(draft, true);

      expect(
        controller.createBubbleSelection(capabilityEnabled: true),
        isA<BellugaContactBubbleSelectionDraft>(),
      );

      controller.updateCreateContactMode(
        BellugaContactSourceMode.mirroredAccountProfile,
      );

      expect(
        controller.createBubbleSelection(capabilityEnabled: true),
        isA<BellugaContactBubbleSelectionClear>(),
      );
      expect(
        controller.buildCreateContactChannelDrafts(capabilityEnabled: true),
        isEmpty,
      );
    },
  );

  test(
    'switching edit contact mode to mirrored clears draft bubble selection and preserves persisted mirrored selections',
    () async {
      final profile = tenantAdminAccountProfileFromRaw(
        id: 'profile-1',
        accountId: 'acc-1',
        profileType: 'venue',
        displayName: 'Perfil',
        contactMode: BellugaContactSourceMode.own,
        contactChannels: <BellugaContactChannel>[
          BellugaContactChannel(
            id: 'channel-1',
            type: BellugaContactChannelType.whatsapp,
            value: '+55 (27) 99999-1111',
          ),
        ],
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

      await controller.loadEditProfile('profile-1');
      controller.addEditContactChannel(BellugaContactChannelType.whatsapp);
      final draft = controller
          .editStateStreamValue
          .value
          .contactChannelDrafts
          .last
          .copyWith(value: '+55 (27) 99999-2222');
      controller.updateEditContactChannel(draft);
      controller.selectEditContactBubble(draft, true);

      expect(
        controller.editBubbleSelection(capabilityEnabled: true),
        isA<BellugaContactBubbleSelectionDraft>(),
      );

      controller.updateEditContactMode(
        BellugaContactSourceMode.mirroredAccountProfile,
      );

      expect(
        controller.editBubbleSelection(capabilityEnabled: true),
        isA<BellugaContactBubbleSelectionClear>(),
      );
      expect(
        controller.buildEditContactChannelDrafts(capabilityEnabled: true),
        isEmpty,
      );

      controller.updateEditContactBubbleChannelId('mirrored-channel-1');
      controller.updateEditContactMode(BellugaContactSourceMode.own);
      controller.updateEditContactMode(
        BellugaContactSourceMode.mirroredAccountProfile,
      );

      final mirroredSelection = controller.editBubbleSelection(
        capabilityEnabled: true,
      );
      expect(mirroredSelection, isA<BellugaContactBubbleSelectionPersisted>());
      expect(
        (mirroredSelection as BellugaContactBubbleSelectionPersisted).channelId,
        'mirrored-channel-1',
      );
    },
  );

  test(
    'loadEditProfile does not preload mirrored contact candidates when persisted mode is own',
    () async {
      final profilesRepository = _FakeAccountProfilesRepository([
        tenantAdminAccountProfileFromRaw(
          id: 'profile-1',
          accountId: 'acc-1',
          profileType: 'venue',
          displayName: 'Perfil',
          contactMode: BellugaContactSourceMode.own,
        ),
      ], const []);
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );

      await controller.loadEditProfile('profile-1');
      await Future<void>.delayed(Duration.zero);

      expect(
        profilesRepository.fetchAccountProfilesPageContactModes,
        isNot(contains('own')),
      );
      expect(
        profilesRepository.fetchAccountProfilesPageContactChannelsEnabledOnly,
        isNot(contains(isTrue)),
      );
    },
  );

  test(
    'loadEditProfile preloads mirrored contact candidates only when persisted mode is mirrored',
    () async {
      final profilesRepository = _FakeAccountProfilesRepository([
        tenantAdminAccountProfileFromRaw(
          id: 'profile-1',
          accountId: 'acc-1',
          profileType: 'venue',
          displayName: 'Perfil',
          contactMode: BellugaContactSourceMode.mirroredAccountProfile,
        ),
      ], const []);
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );

      await controller.loadEditProfile('profile-1');
      await Future<void>.delayed(Duration.zero);

      expect(
        profilesRepository.fetchAccountProfilesPageContactModes,
        contains('own'),
      );
      expect(
        profilesRepository.fetchAccountProfilesPageContactChannelsEnabledOnly,
        contains(isTrue),
      );
    },
  );

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
    'submitUpdateProfile omits nested profile groups from aggregate update',
    () async {
      final refreshedProfile = tenantAdminAccountProfileFromRaw(
        id: 'profile-1',
        accountId: 'acc-1',
        profileType: 'venue',
        displayName: 'Perfil atualizado',
        aggregateRevision: 5,
        nestedProfileGroups: <TenantAdminNestedProfileGroup>[
          TenantAdminNestedProfileGroup(
            idValue: TenantAdminNestedProfileGroupTextValue('parceiros'),
            labelValue: TenantAdminNestedProfileGroupTextValue('Parceiros'),
            orderValue: TenantAdminNestedProfileGroupOrderValue(0),
            memberCountValue: TenantAdminCountValue(1),
          ),
        ],
      );
      final profilesRepository = _FakeAccountProfilesRepository(
        [
          tenantAdminAccountProfileFromRaw(
            id: 'profile-1',
            accountId: 'acc-1',
            profileType: 'venue',
            displayName: 'Perfil',
            slug: 'perfil-original',
            aggregateRevision: 4,
            nestedProfileGroups: <TenantAdminNestedProfileGroup>[
              TenantAdminNestedProfileGroup(
                idValue: TenantAdminNestedProfileGroupTextValue('parceiros'),
                labelValue: TenantAdminNestedProfileGroupTextValue('Parceiros'),
                orderValue: TenantAdminNestedProfileGroupOrderValue(0),
                memberCountValue: TenantAdminCountValue(1),
              ),
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
      profilesRepository.nestedGroupMemberPagesByGroupId['parceiros'] =
          <TenantAdminNestedGroupMemberPage>[
            TenantAdminNestedGroupMemberPage(
              items: <TenantAdminAccountProfileSelectionSummary>[
                TenantAdminAccountProfileSelectionSummary(
                  idValue: TenantAdminAccountProfileIdValue('profile-legacy'),
                  displayNameValue: TenantAdminOptionalTextValue()
                    ..parse('Perfil legado'),
                  isQueryableCandidateValue: TenantAdminFlagValue(true),
                ),
              ],
              nextCursorValue: TenantAdminOptionalTextValue(),
            ),
          ];
      profilesRepository.updateAccountProfileOverride = refreshedProfile;
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
      await controller.loadEditProfile('profile-1');

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

      expect(profilesRepository.lastUpdateNestedProfileGroups, isNull);
      expect(profilesRepository.lastUpdateAggregateRevision, isNull);
      expect(profilesRepository.lastPatchNestedGroupMembersProfileId, isNull);
      expect(profilesRepository.lastPatchNestedGroupMembersGroupId, isNull);
      expect(
        profilesRepository.lastPatchNestedGroupMembersAggregateRevision,
        isNull,
      );
      expect(profilesRepository.lastPatchNestedGroupAddIds, isEmpty);
      expect(profilesRepository.lastPatchNestedGroupRemoveIds, isEmpty);
      expect(controller.accountProfileStreamValue.value?.aggregateRevision, 5);
    },
  );

  test(
    'submitUpdateProfile does not send newly added nested groups through aggregate update or members subresource calls',
    () async {
      final refreshedProfile = tenantAdminAccountProfileFromRaw(
        id: 'profile-1',
        accountId: 'acc-1',
        profileType: 'venue',
        displayName: 'Perfil atualizado',
        aggregateRevision: 5,
        nestedProfileGroups: <TenantAdminNestedProfileGroup>[
          TenantAdminNestedProfileGroup(
            idValue: TenantAdminNestedProfileGroupTextValue('parceiros'),
            labelValue: TenantAdminNestedProfileGroupTextValue('Parceiros'),
            orderValue: TenantAdminNestedProfileGroupOrderValue(0),
            memberCountValue: TenantAdminCountValue(1),
          ),
        ],
      );
      final profilesRepository = _FakeAccountProfilesRepository(
        [
          tenantAdminAccountProfileFromRaw(
            id: 'profile-1',
            accountId: 'acc-1',
            profileType: 'venue',
            displayName: 'Perfil',
            slug: 'perfil-original',
            aggregateRevision: 4,
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
      profilesRepository.updateAccountProfileOverride = refreshedProfile;
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );
      await controller.loadEditProfile(
        'profile-1',
        prefetchedProfile: tenantAdminAccountProfileFromRaw(
          id: 'profile-1',
          accountId: 'acc-1',
          profileType: 'venue',
          displayName: 'Perfil',
          slug: 'perfil-original',
          aggregateRevision: 4,
        ),
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

      expect(profilesRepository.lastNestedGroupMembersProfileId, isNull);
      expect(profilesRepository.lastNestedGroupMembersGroupId, isNull);
      expect(profilesRepository.lastUpdateNestedProfileGroups, isNull);
      expect(profilesRepository.lastUpdateAggregateRevision, isNull);
      expect(profilesRepository.lastPatchNestedGroupMembersProfileId, isNull);
      expect(profilesRepository.lastPatchNestedGroupMembersGroupId, isNull);
      expect(
        profilesRepository.lastPatchNestedGroupMembersAggregateRevision,
        isNull,
      );
      expect(profilesRepository.lastPatchNestedGroupAddIds, isEmpty);
      expect(profilesRepository.lastPatchNestedGroupRemoveIds, isEmpty);
      expect(controller.accountProfileStreamValue.value?.aggregateRevision, 5);
    },
  );

  test(
    'submitUpdateProfile adopts canonical group ids returned by update without resending groups inline',
    () async {
      final loadedProfile = tenantAdminAccountProfileFromRaw(
        id: 'profile-1',
        accountId: 'acc-1',
        profileType: 'venue',
        displayName: 'Perfil',
        slug: 'perfil-original',
        aggregateRevision: 4,
        nestedProfileGroups: <TenantAdminNestedProfileGroup>[
          TenantAdminNestedProfileGroup(
            idValue: TenantAdminNestedProfileGroupTextValue('legacy-group-id'),
            labelValue: TenantAdminNestedProfileGroupTextValue('Parceiros'),
            orderValue: TenantAdminNestedProfileGroupOrderValue(0),
            memberCountValue: TenantAdminCountValue(1),
          ),
        ],
      );
      final refreshedProfile = tenantAdminAccountProfileFromRaw(
        id: 'profile-1',
        accountId: 'acc-1',
        profileType: 'venue',
        displayName: 'Perfil atualizado',
        slug: 'perfil-original',
        aggregateRevision: 5,
        nestedProfileGroups: <TenantAdminNestedProfileGroup>[
          TenantAdminNestedProfileGroup(
            idValue: TenantAdminNestedProfileGroupTextValue(
              'canonical-group-id',
            ),
            labelValue: TenantAdminNestedProfileGroupTextValue('Parceiros'),
            orderValue: TenantAdminNestedProfileGroupOrderValue(0),
            memberCountValue: TenantAdminCountValue(1),
          ),
        ],
      );
      final profilesRepository = _FakeAccountProfilesRepository(
        [loadedProfile],
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
      profilesRepository.updateAccountProfileOverride = refreshedProfile;
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );
      await controller.loadEditProfile('profile-1');

      final groups = <TenantAdminNestedProfileGroup>[
        TenantAdminNestedProfileGroup(
          idValue: TenantAdminNestedProfileGroupTextValue('legacy-group-id'),
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

      expect(profilesRepository.lastUpdateNestedProfileGroups, isNull);
      expect(profilesRepository.lastNestedGroupMembersGroupId, isNull);
      expect(profilesRepository.lastPatchNestedGroupMembersGroupId, isNull);
      expect(profilesRepository.lastPatchNestedGroupAddIds, isEmpty);
      expect(profilesRepository.lastPatchNestedGroupRemoveIds, isEmpty);
      expect(
        controller
            .accountProfileStreamValue
            .value
            ?.nestedProfileGroups
            .single
            .id,
        'canonical-group-id',
      );
      expect(controller.accountProfileStreamValue.value?.aggregateRevision, 5);
    },
  );

  test(
    'applyEditNestedGroupSelectionDelta uses canonical members subresource and refreshes profile',
    () async {
      final refreshedProfile = tenantAdminAccountProfileFromRaw(
        id: 'profile-1',
        accountId: 'acc-1',
        profileType: 'venue',
        displayName: 'Perfil',
        aggregateRevision: 5,
        nestedProfileGroups: <TenantAdminNestedProfileGroup>[
          TenantAdminNestedProfileGroup(
            idValue: TenantAdminNestedProfileGroupTextValue('parceiros'),
            labelValue: TenantAdminNestedProfileGroupTextValue('Parceiros'),
            orderValue: TenantAdminNestedProfileGroupOrderValue(0),
            memberCountValue: TenantAdminCountValue(2),
          ),
        ],
      );
      final profilesRepository =
          _FakeAccountProfilesRepository(<TenantAdminAccountProfile>[
            tenantAdminAccountProfileFromRaw(
              id: 'profile-1',
              accountId: 'acc-1',
              profileType: 'venue',
              displayName: 'Perfil',
              aggregateRevision: 4,
            ),
          ], const <TenantAdminProfileTypeDefinition>[]);
      profilesRepository.nestedGroupMemberPagesByGroupId['parceiros'] =
          <TenantAdminNestedGroupMemberPage>[
            TenantAdminNestedGroupMemberPage(
              items: <TenantAdminAccountProfileSelectionSummary>[
                TenantAdminAccountProfileSelectionSummary(
                  idValue: TenantAdminAccountProfileIdValue('profile-a'),
                  displayNameValue: TenantAdminOptionalTextValue()
                    ..parse('Perfil A'),
                  isQueryableCandidateValue: TenantAdminFlagValue(true),
                ),
              ],
              nextCursorValue: TenantAdminOptionalTextValue()
                ..parse('cursor-2'),
            ),
            TenantAdminNestedGroupMemberPage(
              items: <TenantAdminAccountProfileSelectionSummary>[
                TenantAdminAccountProfileSelectionSummary(
                  idValue: TenantAdminAccountProfileIdValue('profile-b'),
                  displayNameValue: TenantAdminOptionalTextValue()
                    ..parse('Perfil B'),
                  isQueryableCandidateValue: TenantAdminFlagValue(true),
                ),
              ],
              nextCursorValue: TenantAdminOptionalTextValue(),
            ),
          ];
      profilesRepository.accountProfileFetchOverrides['profile-1'] =
          refreshedProfile;
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );

      final baseline = await controller.loadEditNestedGroupMemberBaseline(
        accountProfileId: 'profile-1',
        groupId: 'parceiros',
      );

      expect(baseline.map((entry) => entry.id).toList(), <String>[
        'profile-a',
        'profile-b',
      ]);

      final saved = await controller.applyEditNestedGroupSelectionDelta(
        accountProfileId: 'profile-1',
        groupId: 'parceiros',
        previousSelections: baseline,
        nextSelections: <TenantAdminAccountProfileSelectionSummary>[
          baseline.first,
          TenantAdminAccountProfileSelectionSummary(
            idValue: TenantAdminAccountProfileIdValue('profile-c'),
            displayNameValue: TenantAdminOptionalTextValue()..parse('Perfil C'),
            isQueryableCandidateValue: TenantAdminFlagValue(true),
          ),
        ],
      );

      expect(saved, isTrue);
      expect(profilesRepository.lastNestedGroupMembersProfileId, 'profile-1');
      expect(profilesRepository.lastNestedGroupMembersGroupId, 'parceiros');
      expect(profilesRepository.lastNestedGroupMembersPerPage, 50);
      expect(profilesRepository.lastNestedGroupMembersCursor, 'cursor-2');
      expect(
        profilesRepository.lastPatchNestedGroupMembersProfileId,
        'profile-1',
      );
      expect(
        profilesRepository.lastPatchNestedGroupMembersGroupId,
        'parceiros',
      );
      expect(
        profilesRepository.lastPatchNestedGroupMembersAggregateRevision,
        isNull,
      );
      expect(profilesRepository.lastPatchNestedGroupAddIds, <String>[
        'profile-c',
      ]);
      expect(profilesRepository.lastPatchNestedGroupRemoveIds, <String>[
        'profile-b',
      ]);
      expect(controller.accountProfileStreamValue.value?.aggregateRevision, 5);
      expect(
        controller.editSuccessMessageStreamValue.value,
        'Perfis vinculados atualizados.',
      );
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
    'loadContactSourceCandidates uses only the canonical generic page query',
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

      expect(profilesRepository.fetchAccountProfilesPageCalls, 1);
      expect(profilesRepository.fetchAccountProfilesCalls, 0);
      expect(profilesRepository.lastFetchContactMode, 'own');
      expect(profilesRepository.lastFetchContactChannelsEnabledOnly, isTrue);
      expect(
        profilesRepository.lastFetchExcludeAccountProfileId,
        'profile-current',
      );
      expect(
        controller.contactSourceCandidatesStreamValue.value
            .map((profile) => profile.id)
            .toList(growable: false),
        ['profile-source'],
      );
    },
  );

  test(
    'loadContactSourceCandidates reruns the latest initial canonical page request after an in-flight request',
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
      profilesRepository.fetchAccountProfilesPageGate = gate;
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

      expect(profilesRepository.fetchAccountProfilesPageCalls, 2);
      expect(profilesRepository.fetchAccountProfilesPageExclusions, [
        'profile-a',
        latestExclusion,
      ]);
      expect(
        profilesRepository.fetchAccountProfilesPageContactModes,
        everyElement('own'),
      );
      expect(
        profilesRepository.fetchAccountProfilesPageContactChannelsEnabledOnly,
        everyElement(isTrue),
      );
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
      profilesRepository.fetchAccountProfilesPageOverrides[1] =
          tenantAdminPagedResultFromRaw(
            items: [source],
            hasMore: true,
            currentPage: 1,
            pageSize: 50,
          );
      profilesRepository.fetchAccountProfilesPageFailingPages.add(2);
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
        contains('account-profiles page 2 failed'),
      );
    },
  );

  test(
    'selecting a mirrored contact source hydrates the full profile detail for bubble preview',
    () async {
      final profilesRepository = _FakeAccountProfilesRepository(
        const <TenantAdminAccountProfile>[],
        const <TenantAdminProfileTypeDefinition>[],
      );
      final candidateRow = tenantAdminAccountProfileFromRaw(
        id: 'profile-source',
        accountId: 'acc-source',
        profileType: 'contact_source',
        displayName: 'Perfil de origem',
        contactMode: BellugaContactSourceMode.own,
      );
      final hydratedSource = tenantAdminAccountProfileFromRaw(
        id: 'profile-source',
        accountId: 'acc-source',
        profileType: 'contact_source',
        displayName: 'Perfil de origem',
        contactMode: BellugaContactSourceMode.own,
        effectiveContactChannels: <BellugaContactChannel>[
          BellugaContactChannel(
            id: 'whatsapp-source',
            type: BellugaContactChannelType.whatsapp,
            value: '+55 (27) 99999-1111',
          ),
        ],
      );
      profilesRepository.fetchAccountProfilesPageOverrides[1] =
          tenantAdminPagedResultFromRaw(
            items: <TenantAdminAccountProfile>[candidateRow],
            hasMore: false,
            currentPage: 1,
            pageSize: 20,
          );
      profilesRepository.accountProfileFetchOverrides['profile-source'] =
          hydratedSource;
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );

      await controller.loadContactSourceCandidates(
        excludeProfileId: 'profile-current',
      );
      controller.updateCreateContactMode(
        BellugaContactSourceMode.mirroredAccountProfile,
      );
      controller.updateCreateContactSourceAccountProfileId('profile-source');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(profilesRepository.fetchAccountProfileCalls, 1);
      expect(profilesRepository.lastFetchedProfileId, 'profile-source');
      final selectedSource = controller.contactSourceCandidatesStreamValue.value
          .singleWhere((profile) => profile.id == 'profile-source');
      expect(selectedSource.effectiveContactChannels, hasLength(1));
      expect(
        selectedSource.effectiveContactChannels.single.id,
        'whatsapp-source',
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
    'searchContactSourceCandidates returns filtered results after initial load completes [RED]',
    () async {
      final profilesRepository = _FakeAccountProfilesRepository([
        tenantAdminAccountProfileFromRaw(
          id: 'profile-alvo',
          accountId: 'acc-1',
          profileType: 'venue',
          displayName: 'Alvo de Contato',
          slug: 'alvo-contato',
        ),
        tenantAdminAccountProfileFromRaw(
          id: 'profile-outro',
          accountId: 'acc-2',
          profileType: 'venue',
          displayName: 'Outro Perfil',
          slug: 'outro-perfil',
        ),
      ], const []);
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );

      await controller.loadContactSourceCandidates();
      controller.searchContactSourceCandidates('alvo');
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await Future<void>.delayed(Duration.zero);

      expect(profilesRepository.lastFetchSearch, 'alvo');
      expect(
        controller.contactSourceCandidatesStreamValue.value
            .map((profile) => profile.id)
            .toList(growable: false),
        contains('profile-alvo'),
      );
      expect(
        controller.contactSourceCandidatesStreamValue.value.map(
          (profile) => profile.id,
        ),
        isNot(contains('profile-outro')),
      );
      expect(
        controller.contactSourceCandidatesLoadingStreamValue.value,
        isFalse,
      );
    },
  );

  test(
    'searchNestedProfileCandidates loading clears and results show when filterNestedProfileCandidatesByProfileType fires while initial load is in flight [RED]',
    () async {
      final profilesRepository = _FakeAccountProfilesRepository([
        tenantAdminAccountProfileFromRaw(
          id: 'profile-artist-alvo',
          accountId: 'acc-1',
          profileType: 'artist',
          displayName: 'Alvo Artista',
          slug: 'alvo-artista',
        ),
        tenantAdminAccountProfileFromRaw(
          id: 'profile-venue-alvo',
          accountId: 'acc-2',
          profileType: 'venue',
          displayName: 'Alvo Venue',
          slug: 'alvo-venue',
        ),
        tenantAdminAccountProfileFromRaw(
          id: 'profile-outro',
          accountId: 'acc-3',
          profileType: 'artist',
          displayName: 'Outro Perfil',
          slug: 'outro-perfil',
        ),
      ], const []);
      final gate = Completer<void>();
      profilesRepository.fetchAccountProfilesPageGate = gate;
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );

      // Initial load starts but is blocked by gate
      final initial = controller.loadNestedProfileCandidates();
      await Future<void>.delayed(Duration.zero);

      // Type filter fires before initial load completes (token supersession)
      controller.filterNestedProfileCandidatesByProfileType('artist');
      await Future<void>.delayed(Duration.zero);

      // Release gate — both initial (stale) and filter loads now complete
      gate.complete();
      await initial;
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      // Remove gate so subsequent loads are immediate
      profilesRepository.fetchAccountProfilesPageGate = null;

      // User now types slowly (filter load has already completed)
      controller.searchNestedProfileCandidates('alvo');
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await Future<void>.delayed(Duration.zero);

      expect(profilesRepository.lastFetchSearch, 'alvo');
      expect(
        controller.nestedProfileCandidatesStreamValue.value
            .map((profile) => profile.id)
            .toList(growable: false),
        containsAll(<String>['profile-artist-alvo']),
      );
      expect(
        controller.nestedProfileCandidatesStreamValue.value.map(
          (profile) => profile.id,
        ),
        isNot(contains('profile-outro')),
      );
      // Loading must be cleared — stuck loading is the "empty results even with slow typing" failure mode
      expect(controller.nestedProfileSearchLoadingStreamValue.value, isFalse);
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
