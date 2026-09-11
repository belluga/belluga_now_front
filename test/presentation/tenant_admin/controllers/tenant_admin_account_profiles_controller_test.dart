import 'package:belluga_contact_channels/belluga_contact_channels.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:belluga_form_validation/belluga_form_validation.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/partners/account_profile_external_link.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_onboarding_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_candidate_selection_summary.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_gallery_group.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_gallery_capabilities.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_gallery_snapshot.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_group_head_mutation_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_group_order_mutation_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_group_label_mutation_result.dart';
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
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_location_selection_service.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profiles_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
import 'package:belluga_now/application/router/resolvers/tenant_admin_account_profile_edit_route_resolver.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_unknown_mutation_failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
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
    TenantAdminAccountPublication? publication,
  }) async {
    lastUpdatedOwnershipState = ownershipState;
    final account = tenantAdminAccountFromRaw(
      id: 'acc-1',
      name: name?.value ?? 'Conta',
      slug: slug?.value ?? accountSlug.value,
      document:
          document ?? tenantAdminDocumentFromRaw(type: 'cpf', number: '000'),
      ownershipState: ownershipState ?? TenantAdminOwnershipState.tenantOwned,
      publicationStatus: publication?.status.value,
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
  int? lastUpdateAggregateRevision;
  int fetchAccountProfileCalls = 0;
  String? lastFetchedProfileId;
  int? lastFetchPage;
  int? lastFetchPageSize;
  String? lastFetchSearch;
  String? lastFetchProfileType;
  int fetchAccountProfilesPageCalls = 0;
  int fetchAccountProfilesCalls = 0;
  final Map<String, TenantAdminAccountProfile> accountProfileFetchOverrides =
      <String, TenantAdminAccountProfile>{};
  final Map<String, Object> accountProfileFetchErrors = <String, Object>{};
  final Map<String, Future<TenantAdminAccountProfile>>
  accountProfileFetchFutures = <String, Future<TenantAdminAccountProfile>>{};
  Completer<void>? fetchAccountProfileSignal;
  TenantAdminAccountProfile? updateAccountProfileOverride;
  final List<String?> fetchAccountProfilesPageProfileTypes = [];
  Completer<void>? fetchAccountProfilesPageGate;
  final Set<int> fetchAccountProfilesPageFailingPages = <int>{};
  final Map<int, TenantAdminPagedResult<TenantAdminAccountProfile>>
  fetchAccountProfilesPageOverrides =
      <int, TenantAdminPagedResult<TenantAdminAccountProfile>>{};
  List<TenantAdminNestedProfileGroup>? lastCreateNestedProfileGroups;
  List<TenantAdminNestedProfileGroup>? lastUpdateNestedProfileGroups;
  TenantAdminAccountProfileGallerySnapshot? gallerySnapshotToReturn;
  final List<Completer<TenantAdminAccountProfileGallerySnapshot>>
  createGalleryGroupGates =
      <Completer<TenantAdminAccountProfileGallerySnapshot>>[];
  Object? createGalleryGroupError;
  Completer<TenantAdminAccountProfileGallerySnapshot>? reorderGalleryGroupsGate;
  Object? reorderGalleryGroupsError;
  Object? reorderGalleryItemsError;
  Object? updateGalleryItemError;
  Completer<TenantAdminAccountProfileGallerySnapshot>? updateGalleryItemGate;
  int createGalleryGroupCalls = 0;
  int reorderGalleryGroupsCalls = 0;
  final List<String> galleryMutationCalls = <String>[];
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
  int moveNestedProfileGroupCalls = 0;
  TenantAdminGroupMoveDirection? lastMoveNestedProfileGroupDirection;
  Completer<TenantAdminGroupOrderMutationResult>? moveNestedProfileGroupGate;
  TenantAdminGroupOrderMutationResult? moveNestedProfileGroupResult;
  Object? moveNestedProfileGroupError;
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
  int patchNestedGroupLabelCalls = 0;
  Completer<TenantAdminNestedGroupLabelMutationResult>?
  patchNestedGroupLabelGate;
  Object? patchNestedGroupLabelError;
  TenantAdminNestedGroupLabelMutationResult? patchNestedGroupLabelResult;
  Object? externalLinkMutationError;
  Completer<TenantAdminAccountProfile>? externalLinkMutationGate;
  int externalLinkMutationCalls = 0;

  @override
  Future<List<TenantAdminAccountProfile>> fetchAccountProfiles({
    TenantAdminAccountProfilesRepoString? accountId,
  }) async => () {
    fetchAccountProfilesCalls += 1;
    return _filterProfiles();
  }();

  @override
  Future<TenantAdminPagedResult<TenantAdminAccountProfile>>
  fetchAccountProfilesPage({
    required TenantAdminAccountProfilesRepoInt page,
    required TenantAdminAccountProfilesRepoInt pageSize,
    TenantAdminAccountProfilesRepoString? search,
    TenantAdminAccountProfilesRepoString? accountId,
    TenantAdminAccountProfilesRepoString? profileType,
  }) async {
    fetchAccountProfilesPageCalls += 1;
    lastFetchPage = page.value;
    lastFetchPageSize = pageSize.value;
    lastFetchSearch = search?.value;
    lastFetchProfileType = profileType?.value;
    fetchAccountProfilesPageProfileTypes.add(profileType?.value);
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
    final signal = fetchAccountProfileSignal;
    if (signal != null && !signal.isCompleted) signal.complete();
    final future = accountProfileFetchFutures[accountProfileId.value];
    if (future != null) {
      return future;
    }
    final error = accountProfileFetchErrors[accountProfileId.value];
    if (error != null) {
      throw error;
    }
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
    lastUpdateAggregateRevision = aggregateRevision?.value;
    lastUpdateNestedProfileGroups = nestedProfileGroups;
    return updateAccountProfileOverride ?? _profiles.first;
  }

  Future<TenantAdminAccountProfile> _externalLinkMutation() async {
    externalLinkMutationCalls += 1;
    final gate = externalLinkMutationGate;
    if (gate != null) return gate.future;
    final error = externalLinkMutationError;
    if (error != null) throw error;
    return _profiles.first;
  }

  @override
  Future<TenantAdminAccountProfile> createExternalLink({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    required AccountProfileExternalLinkType type,
    required AccountProfileExternalLinkUrlValue url,
    AccountProfileExternalLinkLabelValue? label,
  }) => _externalLinkMutation();

  @override
  Future<TenantAdminAccountProfile> updateExternalLink({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    required TenantAdminAccountProfilesRepoString externalLinkId,
    required AccountProfileExternalLinkUrlValue url,
    AccountProfileExternalLinkLabelValue? label,
  }) => _externalLinkMutation();

  @override
  Future<TenantAdminAccountProfile> deleteExternalLink({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    required TenantAdminAccountProfilesRepoString externalLinkId,
  }) => _externalLinkMutation();

  @override
  Future<TenantAdminAccountProfileGallerySnapshot> createGalleryGroup({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    required TenantAdminAccountProfilesRepoString subtitle,
  }) async {
    createGalleryGroupCalls += 1;
    if (createGalleryGroupGates.isNotEmpty) {
      return createGalleryGroupGates.removeAt(0).future;
    }
    if (createGalleryGroupError != null) throw createGalleryGroupError!;
    return gallerySnapshotToReturn!;
  }

  @override
  Future<TenantAdminAccountProfileGallerySnapshot> reorderGalleryGroups({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    required List<TenantAdminAccountProfilesRepoString> groupIds,
  }) async {
    reorderGalleryGroupsCalls += 1;
    final gate = reorderGalleryGroupsGate;
    if (gate != null) return gate.future;
    if (reorderGalleryGroupsError != null) throw reorderGalleryGroupsError!;
    return gallerySnapshotToReturn!;
  }

  @override
  Future<TenantAdminAccountProfileGallerySnapshot> renameGalleryGroup({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    required TenantAdminAccountProfilesRepoString groupId,
    required TenantAdminAccountProfilesRepoString subtitle,
  }) async {
    galleryMutationCalls.add(
      'rename:${accountProfileId.value}:${groupId.value}:${subtitle.value}',
    );
    return gallerySnapshotToReturn!;
  }

  @override
  Future<TenantAdminAccountProfileGallerySnapshot> deleteGalleryGroup({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    required TenantAdminAccountProfilesRepoString groupId,
  }) async {
    galleryMutationCalls.add(
      'delete-group:${accountProfileId.value}:${groupId.value}',
    );
    return gallerySnapshotToReturn!;
  }

  @override
  Future<TenantAdminAccountProfileGallerySnapshot> createGalleryItem({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    required TenantAdminAccountProfilesRepoString groupId,
    required TenantAdminAccountProfileGalleryItemType type,
    TenantAdminOptionalTextValue? title,
    TenantAdminOptionalTextValue? description,
    TenantAdminMediaUpload? image,
    TenantAdminAccountProfilesRepoString? youtubeUrl,
  }) async {
    galleryMutationCalls.add(
      'create-item:${accountProfileId.value}:${groupId.value}:${type.name}:${youtubeUrl?.value}',
    );
    return gallerySnapshotToReturn!;
  }

  @override
  Future<TenantAdminAccountProfileGallerySnapshot> updateGalleryItem({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    required TenantAdminAccountProfilesRepoString groupId,
    required TenantAdminAccountProfilesRepoString itemId,
    TenantAdminAccountProfileGalleryItemType? type,
    TenantAdminOptionalTextValue? title,
    TenantAdminOptionalTextValue? description,
    TenantAdminMediaUpload? image,
    TenantAdminAccountProfilesRepoString? youtubeUrl,
  }) async {
    galleryMutationCalls.add(
      'update-item:${accountProfileId.value}:${groupId.value}:${itemId.value}:${title?.nullableValue}:${description?.nullableValue}:${youtubeUrl?.value}',
    );
    final gate = updateGalleryItemGate;
    if (gate != null) return gate.future;
    if (updateGalleryItemError != null) throw updateGalleryItemError!;
    return gallerySnapshotToReturn!;
  }

  @override
  Future<TenantAdminAccountProfileGallerySnapshot> deleteGalleryItem({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    required TenantAdminAccountProfilesRepoString groupId,
    required TenantAdminAccountProfilesRepoString itemId,
  }) async {
    galleryMutationCalls.add(
      'delete-item:${accountProfileId.value}:${groupId.value}:${itemId.value}',
    );
    return gallerySnapshotToReturn!;
  }

  @override
  Future<TenantAdminAccountProfileGallerySnapshot> reorderGalleryItems({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    required TenantAdminAccountProfilesRepoString groupId,
    required List<TenantAdminAccountProfilesRepoString> itemIds,
  }) async {
    galleryMutationCalls.add(
      'reorder-items:${accountProfileId.value}:${groupId.value}:${itemIds.map((item) => item.value).join(',')}',
    );
    if (reorderGalleryItemsError != null) throw reorderGalleryItemsError!;
    return gallerySnapshotToReturn!;
  }

  @override
  Future<TenantAdminNestedGroupMemberPage> fetchNestedGroupMembersPage({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    required TenantAdminAccountProfilesRepoString groupId,
    TenantAdminAccountProfilesRepoInt? perPage,
    TenantAdminAccountProfilesRepoString? cursor,
    TenantAdminAccountProfilesRepoString? search,
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
  Future<TenantAdminGroupOrderMutationResult> moveNestedProfileGroup({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    required TenantAdminAccountProfilesRepoString groupId,
    required TenantAdminGroupMoveDirection direction,
  }) async {
    moveNestedProfileGroupCalls += 1;
    lastMoveNestedProfileGroupDirection = direction;
    if (moveNestedProfileGroupError != null) throw moveNestedProfileGroupError!;
    if (moveNestedProfileGroupGate != null) {
      return moveNestedProfileGroupGate!.future;
    }
    return moveNestedProfileGroupResult ??
        TenantAdminGroupOrderMutationResult(
          accountProfileIdValue: TenantAdminNestedProfileGroupTextValue(
            accountProfileId.value,
          ),
          groups: [
            for (final group in _profileById(
              accountProfileId.value,
            ).nestedProfileGroups)
              TenantAdminGroupOrderEntry(
                idValue: TenantAdminNestedProfileGroupTextValue(group.id),
                orderValue: TenantAdminNestedProfileGroupOrderValue(
                  group.order,
                ),
              ),
          ],
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
  }) {
    final normalizedSearch = search?.trim().toLowerCase() ?? '';
    final normalizedProfileType = profileType?.trim();
    return _profiles
        .where((profile) {
          if (normalizedProfileType != null &&
              normalizedProfileType.isNotEmpty &&
              profile.profileType != normalizedProfileType) {
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

  @override
  Future<TenantAdminNestedGroupLabelMutationResult>
  patchNestedProfileGroupLabel({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    required TenantAdminAccountProfilesRepoString groupId,
    required TenantAdminAccountProfilesRepoString label,
  }) async {
    patchNestedGroupLabelCalls += 1;
    final gate = patchNestedGroupLabelGate;
    if (gate != null) return gate.future;
    final error = patchNestedGroupLabelError;
    if (error != null) throw error;
    return patchNestedGroupLabelResult ??
        TenantAdminNestedGroupLabelMutationResult(
          idValue: TenantAdminNestedProfileGroupTextValue(groupId.value),
          labelValue: TenantAdminNestedProfileGroupTextValue(label.value),
        );
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
  TestWidgetsFlutterBinding.ensureInitialized();

  TenantAdminAccountProfilesController labelController(
    _FakeAccountProfilesRepository repository, {
    TenantAdminTenantScopeContract? tenantScope,
  }) => TenantAdminAccountProfilesController(
    profilesRepository: repository,
    accountsRepository: _FakeAccountsRepository(),
    taxonomiesRepository: _FakeTaxonomiesRepository(),
    locationSelectionService: TenantAdminLocationSelectionService(),
    tenantScope: tenantScope,
  );

  TenantAdminAccountProfile externalLinkProfile(
    String id, {
    int? limit = 3,
    List<AccountProfileExternalLink>? externalLinks,
  }) => tenantAdminAccountProfileFromRaw(
    id: id,
    accountId: 'account-$id',
    profileType: 'custom',
    displayName: 'Profile $id',
    externalLinks: externalLinks ?? const <AccountProfileExternalLink>[],
    externalLinksLimit: limit,
  );

  test(
    'external link completion is ignored after route generation changes',
    () async {
      final firstProfile = externalLinkProfile('profile-1');
      final secondProfile = externalLinkProfile('profile-2');
      final repository = _FakeAccountProfilesRepository([
        firstProfile,
        secondProfile,
      ], const []);
      final controller = labelController(repository);
      controller.adoptExternalLinkRouteProfile(firstProfile);
      final firstDraft = controller.beginExternalLinkDraft(
        accountProfileId: firstProfile.id,
      );
      firstDraft.urlController.text = 'https://instagram.com/first';
      final gate = Completer<TenantAdminAccountProfile>();
      repository.externalLinkMutationGate = gate;

      final pending = controller.saveExternalLinkDraft(firstDraft);
      controller.adoptExternalLinkRouteProfile(secondProfile);
      final secondDraft = controller.beginExternalLinkDraft(
        accountProfileId: secondProfile.id,
      );
      gate.complete(firstProfile);

      expect(await pending, TenantAdminExternalLinkMutationOutcome.ignored);
      expect(controller.accountProfileStreamValue.value?.id, 'profile-2');
      controller.endExternalLinkDraft(firstDraft);
      controller.endExternalLinkDraft(secondDraft);
      controller.dispose();
    },
  );

  test(
    'external link draft tracks dirty and valid state from canonical input',
    () {
      final profile = externalLinkProfile('profile-dirty');
      final controller = labelController(
        _FakeAccountProfilesRepository([profile], const []),
      );
      controller.adoptExternalLinkRouteProfile(profile);
      final existing = _parseExternalLink(
        id: 'instagram-link',
        type: AccountProfileExternalLinkType.instagram,
        url: 'https://instagram.com/belluga',
      );
      final draft = controller.beginExternalLinkDraft(
        accountProfileId: profile.id,
        existingLink: existing,
      );

      expect(draft.dirtyStreamValue.value, isFalse);
      expect(draft.canSubmitStreamValue.value, isTrue);

      draft.urlController.text = 'not-a-url';
      expect(draft.dirtyStreamValue.value, isTrue);
      expect(draft.canSubmitStreamValue.value, isFalse);

      draft.urlController.text = 'https://instagram.com/belluga';
      expect(draft.dirtyStreamValue.value, isFalse);
      expect(draft.canSubmitStreamValue.value, isTrue);

      controller.endExternalLinkDraft(draft);
      controller.dispose();
    },
  );

  test(
    'external link profile reconciliation preserves unrelated parent edits',
    () {
      final profile = externalLinkProfile('profile-parent-draft');
      final updated = externalLinkProfile('profile-parent-draft');
      final controller = labelController(
        _FakeAccountProfilesRepository([profile, updated], const []),
      );
      controller.adoptExternalLinkRouteProfile(profile);
      controller.editStateStreamValue.addValue(
        controller.editStateStreamValue.value.copyWith(
          contactSourceAccountProfileId: 'unsaved-contact-source',
          nestedProfileGroups: const [],
        ),
      );

      controller.adoptExternalLinkRouteProfile(updated);

      expect(
        controller.editStateStreamValue.value.contactSourceAccountProfileId,
        'unsaved-contact-source',
      );
      controller.dispose();
    },
  );

  test(
    'successful external link mutation primes the parent resolver without a GET',
    () async {
      final profile = externalLinkProfile('profile-parent-prefetch');
      final updatedLink = _parseExternalLink(
        id: 'instagram-link',
        type: AccountProfileExternalLinkType.instagram,
        url: 'https://instagram.com/belluga',
      );
      final updated = tenantAdminAccountProfileFromRaw(
        id: profile.id,
        accountId: profile.accountId,
        profileType: profile.profileType,
        displayName: profile.displayName,
        externalLinks: [updatedLink],
        externalLinksLimit: 3,
      );
      final repository = _FakeAccountProfilesRepository([updated], const []);
      final controller = labelController(repository);
      controller.adoptExternalLinkRouteProfile(profile);
      final draft = controller.beginExternalLinkDraft(
        accountProfileId: profile.id,
      );
      draft.urlController.text = 'https://instagram.com/belluga';

      expect(
        await controller.saveExternalLinkDraft(draft),
        TenantAdminExternalLinkMutationOutcome.saved,
      );
      expect(repository.fetchAccountProfileCalls, 0);

      final resolver = TenantAdminAccountProfileEditRouteResolver(
        accountProfilesRepository: repository,
        accountProfilesController: controller,
      );
      final resolved = await resolver.resolve({
        'accountSlug': 'account-one',
        'accountProfileId': profile.id,
      });

      expect(resolved, same(updated));
      expect(repository.fetchAccountProfileCalls, 0);
      controller.endExternalLinkDraft(draft);
      controller.dispose();
    },
  );

  test(
    'new external link draft becomes submittable only after valid input',
    () {
      final profile = externalLinkProfile('profile-new');
      final controller = labelController(
        _FakeAccountProfilesRepository([profile], const []),
      );
      controller.adoptExternalLinkRouteProfile(profile);
      final draft = controller.beginExternalLinkDraft(
        accountProfileId: profile.id,
      );

      expect(draft.dirtyStreamValue.value, isFalse);
      expect(draft.canSubmitStreamValue.value, isFalse);

      draft.urlController.text = 'https://instagram.com/belluga';
      expect(draft.dirtyStreamValue.value, isTrue);
      expect(draft.canSubmitStreamValue.value, isTrue);

      controller.endExternalLinkDraft(draft);
      controller.dispose();
    },
  );

  test(
    'new external link draft skips configured Instagram and starts at the first free type',
    () {
      final profile = externalLinkProfile(
        'profile-available-type',
        externalLinks: [
          _parseExternalLink(
            id: 'instagram-link',
            type: AccountProfileExternalLinkType.instagram,
            url: 'https://instagram.com/belluga',
          ),
        ],
      );
      final controller = labelController(
        _FakeAccountProfilesRepository([profile], const []),
      );
      controller.adoptExternalLinkRouteProfile(profile);

      final draft = controller.beginExternalLinkDraft(
        accountProfileId: profile.id,
      );

      expect(
        draft.selectedTypeStreamValue.value,
        AccountProfileExternalLinkType.facebook,
      );
      controller.endExternalLinkDraft(draft);
      controller.dispose();
    },
  );

  test(
    'new external link draft is rejected when every registry type is configured',
    () {
      final links = <AccountProfileExternalLink>[
        _parseExternalLink(
          id: 'instagram-link',
          type: AccountProfileExternalLinkType.instagram,
          url: 'https://instagram.com/belluga',
        ),
        _parseExternalLink(
          id: 'facebook-link',
          type: AccountProfileExternalLinkType.facebook,
          url: 'https://facebook.com/belluga',
        ),
        _parseExternalLink(
          id: 'youtube-link',
          type: AccountProfileExternalLinkType.youtube,
          url: 'https://youtu.be/dQw4w9WgXcQ',
        ),
        _parseExternalLink(
          id: 'tiktok-link',
          type: AccountProfileExternalLinkType.tiktok,
          url: 'https://www.tiktok.com/@belluga',
        ),
        _parseExternalLink(
          id: 'spotify-link',
          type: AccountProfileExternalLinkType.spotify,
          url: 'https://open.spotify.com/artist/belluga',
        ),
        _parseExternalLink(
          id: 'website-link',
          type: AccountProfileExternalLinkType.website,
          url: 'https://belluga.example',
          label: 'Belluga',
        ),
      ];
      final profile = externalLinkProfile(
        'profile-no-available-type',
        limit: 8,
        externalLinks: links,
      );
      final controller = labelController(
        _FakeAccountProfilesRepository([profile], const []),
      );
      controller.adoptExternalLinkRouteProfile(profile);

      expect(
        () => controller.beginExternalLinkDraft(accountProfileId: profile.id),
        throwsA(isA<StateError>()),
      );
      controller.dispose();
    },
  );

  test(
    'external link mutation single-flights ten triggers across three repetitions',
    () async {
      for (var repetition = 0; repetition < 3; repetition++) {
        final profile = externalLinkProfile('profile-burst-$repetition');
        final repository = _FakeAccountProfilesRepository([profile], const []);
        final controller = labelController(repository);
        controller.adoptExternalLinkRouteProfile(profile);
        final draft = controller.beginExternalLinkDraft(
          accountProfileId: profile.id,
        );
        draft.urlController.text = 'https://instagram.com/burst-$repetition';
        final gate = Completer<TenantAdminAccountProfile>();
        repository.externalLinkMutationGate = gate;

        final outcomes = List.generate(
          10,
          (_) => controller.saveExternalLinkDraft(draft),
        );
        expect(repository.externalLinkMutationCalls, 1);
        gate.complete(profile);

        expect(
          await outcomes.first,
          TenantAdminExternalLinkMutationOutcome.saved,
        );
        expect(
          await Future.wait(outcomes.skip(1)),
          everyElement(TenantAdminExternalLinkMutationOutcome.ignored),
        );
        controller.endExternalLinkDraft(draft);
        controller.dispose();
      }
    },
  );

  test(
    'unknown external link outcome fences retries until explicit reload',
    () async {
      final profile = externalLinkProfile('profile-1');
      final repository = _FakeAccountProfilesRepository([profile], const []);
      repository.externalLinkMutationError =
          const TenantAdminUnknownMutationFailure();
      final controller = labelController(repository);
      controller.adoptExternalLinkRouteProfile(profile);
      final draft = controller.beginExternalLinkDraft(
        accountProfileId: profile.id,
      );
      draft.urlController.text = 'https://instagram.com/profile';

      expect(
        await controller.saveExternalLinkDraft(draft),
        TenantAdminExternalLinkMutationOutcome.failed,
      );
      expect(draft.requiresReloadStreamValue.value, isTrue);
      expect(
        await controller.saveExternalLinkDraft(draft),
        TenantAdminExternalLinkMutationOutcome.ignored,
      );
      expect(repository.externalLinkMutationCalls, 1);

      repository.externalLinkMutationError = null;
      expect(await controller.reloadExternalLinkBaseline(draft), isTrue);
      expect(draft.requiresReloadStreamValue.value, isFalse);
      controller.endExternalLinkDraft(draft);
      controller.dispose();
    },
  );

  test(
    'ordinary external link validation failure stays on the draft and remains retryable',
    () async {
      final profile = externalLinkProfile('profile-validation');
      final repository = _FakeAccountProfilesRepository([profile], const []);
      repository.externalLinkMutationError = FormValidationFailure(
        statusCode: 422,
        message: 'URL inválida.',
        fieldErrors: const {
          'url': ['URL inválida.'],
        },
      );
      final controller = labelController(repository);
      controller.adoptExternalLinkRouteProfile(profile);
      final draft = controller.beginExternalLinkDraft(
        accountProfileId: profile.id,
      );
      draft.urlController.text = 'https://instagram.com/profile';

      expect(
        await controller.saveExternalLinkDraft(draft),
        TenantAdminExternalLinkMutationOutcome.failed,
      );
      expect(draft.errorStreamValue.value, 'URL inválida.');
      expect(draft.requiresReloadStreamValue.value, isFalse);
      expect(draft.busyStreamValue.value, isFalse);
      expect(repository.externalLinkMutationCalls, 1);

      repository.externalLinkMutationError = null;
      expect(
        await controller.saveExternalLinkDraft(draft),
        TenantAdminExternalLinkMutationOutcome.saved,
      );
      expect(repository.externalLinkMutationCalls, 2);
      controller.endExternalLinkDraft(draft);
      controller.dispose();
    },
  );

  test('late external link failure after route disposal is ignored', () async {
    final profile = externalLinkProfile('profile-late-failure');
    final repository = _FakeAccountProfilesRepository([profile], const []);
    final controller = labelController(repository);
    controller.adoptExternalLinkRouteProfile(profile);
    final draft = controller.beginExternalLinkDraft(
      accountProfileId: profile.id,
    );
    draft.urlController.text = 'https://instagram.com/profile';
    final gate = Completer<TenantAdminAccountProfile>();
    repository.externalLinkMutationGate = gate;

    final pending = controller.saveExternalLinkDraft(draft);
    controller.endExternalLinkDraft(draft);
    gate.completeError(
      FormValidationFailure(
        statusCode: 422,
        message: 'URL inválida.',
        fieldErrors: const {
          'url': ['URL inválida.'],
        },
      ),
    );

    expect(await pending, TenantAdminExternalLinkMutationOutcome.ignored);
    expect(controller.accountProfileStreamValue.value?.id, profile.id);
    controller.dispose();
  });

  test(
    'capability-disabled mutation refreshes and invalidates matching draft',
    () async {
      final enabled = externalLinkProfile('profile-1');
      final disabled = externalLinkProfile('profile-1', limit: null);
      final repository = _FakeAccountProfilesRepository([enabled], const []);
      repository.externalLinkMutationError = FormValidationFailure(
        statusCode: 422,
        message: 'Capability disabled.',
        errorCode: 'account_profile_external_links_capability_disabled',
        fieldErrors: const {
          'external_links': ['Capability disabled.'],
        },
      );
      repository.accountProfileFetchOverrides[enabled.id] = disabled;
      final controller = labelController(repository);
      controller.adoptExternalLinkRouteProfile(enabled);
      final draft = controller.beginExternalLinkDraft(
        accountProfileId: enabled.id,
      );
      draft.urlController.text = 'https://instagram.com/profile';

      expect(
        await controller.saveExternalLinkDraft(draft),
        TenantAdminExternalLinkMutationOutcome.capabilityDisabled,
      );
      expect(
        controller.accountProfileStreamValue.value?.externalLinksLimit,
        isNull,
      );
      expect(
        await controller.saveExternalLinkDraft(draft),
        TenantAdminExternalLinkMutationOutcome.ignored,
      );
      draft.dispose();
      controller.dispose();
    },
  );

  test(
    'nested group label coordinator single-flights and applies authoritative success',
    () async {
      final repository = _FakeAccountProfilesRepository(
        <TenantAdminAccountProfile>[],
        const <TenantAdminProfileTypeDefinition>[],
      );
      final controller = labelController(repository);
      final gate = Completer<TenantAdminNestedGroupLabelMutationResult>();
      repository.patchNestedGroupLabelGate = gate;
      controller.beginNestedGroupLabelEdit(
        accountProfileId: 'p',
        groupId: 'g',
        label: 'Old',
      );
      controller.changeNestedGroupLabelDraft(
        accountProfileId: 'p',
        groupId: 'g',
        label: 'New',
      );
      final first = controller.saveNestedGroupLabel(
        accountProfileId: 'p',
        groupId: 'g',
        authoritativeLabel: 'Old',
      );
      final duplicate = controller.saveNestedGroupLabel(
        accountProfileId: 'p',
        groupId: 'g',
        authoritativeLabel: 'Old',
      );
      await Future<void>.delayed(Duration.zero);
      expect(repository.patchNestedGroupLabelCalls, 1);
      gate.complete(
        TenantAdminNestedGroupLabelMutationResult(
          idValue: TenantAdminNestedProfileGroupTextValue('g'),
          labelValue: TenantAdminNestedProfileGroupTextValue('Authoritative'),
        ),
      );
      await Future.wait([first, duplicate]);
      expect(
        controller
            .nestedGroupLabelState(
              accountProfileId: 'p',
              groupId: 'g',
              label: 'Old',
            )
            .value
            .draft,
        'Authoritative',
      );
      controller.dispose();
    },
  );

  test(
    'nested group label retries remain explicit controller requests',
    () async {
      final repository = _FakeAccountProfilesRepository(
        <TenantAdminAccountProfile>[],
        const <TenantAdminProfileTypeDefinition>[],
      );
      final controller = labelController(repository);
      controller.beginNestedGroupLabelEdit(
        accountProfileId: 'p',
        groupId: 'g',
        label: 'Old',
      );
      controller.changeNestedGroupLabelDraft(
        accountProfileId: 'p',
        groupId: 'g',
        label: 'New',
      );
      repository.patchNestedGroupLabelError =
          const TenantAdminUnknownMutationFailure();
      await controller.saveNestedGroupLabel(
        accountProfileId: 'p',
        groupId: 'g',
        authoritativeLabel: 'Old',
      );
      await controller.saveNestedGroupLabel(
        accountProfileId: 'p',
        groupId: 'g',
        authoritativeLabel: 'Old',
      );
      controller.changeNestedGroupLabelDraft(
        accountProfileId: 'p',
        groupId: 'g',
        label: 'Changed after unknown',
      );
      await controller.saveNestedGroupLabel(
        accountProfileId: 'p',
        groupId: 'g',
        authoritativeLabel: 'Old',
      );
      repository.patchNestedGroupLabelError = StateError('422');
      await controller.saveNestedGroupLabel(
        accountProfileId: 'p',
        groupId: 'g',
        authoritativeLabel: 'Old',
      );
      await controller.saveNestedGroupLabel(
        accountProfileId: 'p',
        groupId: 'g',
        authoritativeLabel: 'Old',
      );
      expect(repository.patchNestedGroupLabelCalls, 5);
      controller.dispose();
    },
  );

  test(
    'nested group label success preserves local state and invalidates revision without parent GET',
    () async {
      final group = TenantAdminNestedProfileGroup(
        idValue: TenantAdminNestedProfileGroupTextValue('g'),
        labelValue: TenantAdminNestedProfileGroupTextValue('Old'),
        orderValue: TenantAdminNestedProfileGroupOrderValue(4),
        memberCountValue: TenantAdminCountValue(2),
        accountProfileIdValues: <TenantAdminNestedProfileGroupTextValue>[
          TenantAdminNestedProfileGroupTextValue('member-a'),
          TenantAdminNestedProfileGroupTextValue('member-b'),
        ],
      );
      final sibling = TenantAdminNestedProfileGroup(
        idValue: TenantAdminNestedProfileGroupTextValue('sibling'),
        labelValue: TenantAdminNestedProfileGroupTextValue('Sibling'),
        orderValue: TenantAdminNestedProfileGroupOrderValue(9),
        memberCountValue: TenantAdminCountValue(1),
      );
      final profile = tenantAdminAccountProfileFromRaw(
        id: 'p',
        accountId: 'a',
        profileType: 'venue',
        displayName: 'Profile',
        aggregateRevision: 7,
        bio: 'Preserved bio',
        nestedProfileGroups: [group, sibling],
      );
      final repository = _FakeAccountProfilesRepository([profile], const []);
      repository.patchNestedGroupLabelResult =
          TenantAdminNestedGroupLabelMutationResult(
            idValue: TenantAdminNestedProfileGroupTextValue(group.id),
            labelValue: TenantAdminNestedProfileGroupTextValue('Readback'),
          );
      final controller = labelController(repository);
      await controller.loadEditProfile('p', prefetchedProfile: profile);
      controller.beginNestedGroupLabelEdit(
        accountProfileId: 'p',
        groupId: 'g',
        label: 'Old',
      );
      controller.changeNestedGroupLabelDraft(
        accountProfileId: 'p',
        groupId: 'g',
        label: 'New',
      );
      await controller.saveNestedGroupLabel(
        accountProfileId: 'p',
        groupId: 'g',
        authoritativeLabel: 'Old',
      );
      expect(repository.fetchAccountProfileCalls, 0);
      final groups = controller.editStateStreamValue.value.nestedProfileGroups;
      expect(groups.map((entry) => entry.id), <String>['g', 'sibling']);
      expect(groups.first.label, 'Readback');
      expect(groups.first.order, 4);
      expect(groups.first.memberCount, 2);
      expect(
        groups.first.accountProfileIdValues.map((entry) => entry.value),
        <String>['member-a', 'member-b'],
      );
      expect(groups[1].label, 'Sibling');
      expect(groups[1].order, 9);
      expect(groups[1].memberCount, 1);
      expect(
        controller.accountProfileStreamValue.value?.aggregateRevision,
        isNull,
      );
      expect(controller.accountProfileStreamValue.value?.bio, 'Preserved bio');
      expect(
        controller
            .nestedGroupLabelState(
              accountProfileId: 'p',
              groupId: 'g',
              label: 'Old',
            )
            .value
            .draft,
        'Readback',
      );
      controller.dispose();
    },
  );

  test('nested group label response id mismatch fails closed', () async {
    final group = TenantAdminNestedProfileGroup(
      idValue: TenantAdminNestedProfileGroupTextValue('g'),
      labelValue: TenantAdminNestedProfileGroupTextValue('Old'),
      orderValue: TenantAdminNestedProfileGroupOrderValue(0),
    );
    final profile = tenantAdminAccountProfileFromRaw(
      id: 'p',
      accountId: 'a',
      profileType: 'venue',
      displayName: 'Profile',
      aggregateRevision: 3,
      nestedProfileGroups: [group],
    );
    final repository = _FakeAccountProfilesRepository([profile], const [])
      ..patchNestedGroupLabelResult = TenantAdminNestedGroupLabelMutationResult(
        idValue: TenantAdminNestedProfileGroupTextValue('other'),
        labelValue: TenantAdminNestedProfileGroupTextValue('Wrong target'),
      );
    final controller = labelController(repository);
    await controller.loadEditProfile('p', prefetchedProfile: profile);
    controller.beginNestedGroupLabelEdit(
      accountProfileId: 'p',
      groupId: 'g',
      label: 'Old',
    );
    controller.changeNestedGroupLabelDraft(
      accountProfileId: 'p',
      groupId: 'g',
      label: 'New',
    );

    await controller.saveNestedGroupLabel(
      accountProfileId: 'p',
      groupId: 'g',
      authoritativeLabel: 'Old',
    );

    expect(
      controller.editStateStreamValue.value.nestedProfileGroups.single.label,
      'Old',
    );
    expect(controller.accountProfileStreamValue.value?.aggregateRevision, 3);
    expect(
      controller
          .nestedGroupLabelState(
            accountProfileId: 'p',
            groupId: 'g',
            label: 'Old',
          )
          .value
          .hasError,
      isTrue,
    );
    controller.dispose();
  });

  test('nested group label ignores late completion after dispose', () async {
    final repository = _FakeAccountProfilesRepository(
      <TenantAdminAccountProfile>[],
      const [],
    );
    final controller = labelController(repository);
    final gate = Completer<TenantAdminNestedGroupLabelMutationResult>();
    repository.patchNestedGroupLabelGate = gate;
    controller.beginNestedGroupLabelEdit(
      accountProfileId: 'p',
      groupId: 'g',
      label: 'Old',
    );
    controller.changeNestedGroupLabelDraft(
      accountProfileId: 'p',
      groupId: 'g',
      label: 'New',
    );
    final future = controller.saveNestedGroupLabel(
      accountProfileId: 'p',
      groupId: 'g',
      authoritativeLabel: 'Old',
    );
    controller.dispose();
    gate.complete(
      TenantAdminNestedGroupLabelMutationResult(
        idValue: TenantAdminNestedProfileGroupTextValue('g'),
        labelValue: TenantAdminNestedProfileGroupTextValue('Late'),
      ),
    );
    await future;
  });

  test(
    'nested group label exposes only safe structured validation errors',
    () async {
      final repository = _FakeAccountProfilesRepository(
        <TenantAdminAccountProfile>[],
        const <TenantAdminProfileTypeDefinition>[],
      );
      final controller = labelController(repository);
      controller.beginNestedGroupLabelEdit(
        accountProfileId: 'p',
        groupId: 'g',
        label: 'Old',
      );
      controller.changeNestedGroupLabelDraft(
        accountProfileId: 'p',
        groupId: 'g',
        label: 'New',
      );

      repository.patchNestedGroupLabelError = FormValidationFailure(
        statusCode: 422,
        message: 'Validation failed.',
        fieldErrors: <String, List<String>>{
          'label': <String>['Nome da aba é inválido.'],
        },
      );
      await controller.saveNestedGroupLabel(
        accountProfileId: 'p',
        groupId: 'g',
        authoritativeLabel: 'Old',
      );
      expect(
        controller
            .nestedGroupLabelState(
              accountProfileId: 'p',
              groupId: 'g',
              label: 'Old',
            )
            .value
            .errorText,
        'Nome da aba é inválido.',
      );

      for (final error in <Object>[
        StateError('500 <html> https://internal.example/payload'),
        const FormatException('decode https://internal.example/payload'),
      ]) {
        repository.patchNestedGroupLabelError = error;
        await controller.saveNestedGroupLabel(
          accountProfileId: 'p',
          groupId: 'g',
          authoritativeLabel: 'Old',
        );
        expect(
          controller
              .nestedGroupLabelState(
                accountProfileId: 'p',
                groupId: 'g',
                label: 'Old',
              )
              .value
              .errorText,
          'Não foi possível salvar o grupo.',
        );
      }
      repository.patchNestedGroupLabelError =
          const TenantAdminUnknownMutationFailure();
      await controller.saveNestedGroupLabel(
        accountProfileId: 'p',
        groupId: 'g',
        authoritativeLabel: 'Old',
      );
      expect(
        controller
            .nestedGroupLabelState(
              accountProfileId: 'p',
              groupId: 'g',
              label: 'Old',
            )
            .value
            .errorText,
        'Não foi possível confirmar o salvamento. Tente novamente.',
      );
      controller.dispose();
    },
  );

  test(
    'nested group label ignores a late completion after parent reload with equal ids',
    () async {
      final profile = tenantAdminAccountProfileFromRaw(
        id: 'p',
        accountId: 'a',
        profileType: 'venue',
        displayName: 'Profile',
      );
      final repository = _FakeAccountProfilesRepository([profile], const []);
      final controller = labelController(repository);
      final gate = Completer<TenantAdminNestedGroupLabelMutationResult>();
      repository.patchNestedGroupLabelGate = gate;
      controller.beginNestedGroupLabelEdit(
        accountProfileId: 'p',
        groupId: 'g',
        label: 'Before reload',
      );
      controller.changeNestedGroupLabelDraft(
        accountProfileId: 'p',
        groupId: 'g',
        label: 'Pending old parent',
      );
      final save = controller.saveNestedGroupLabel(
        accountProfileId: 'p',
        groupId: 'g',
        authoritativeLabel: 'Before reload',
      );

      await controller.loadEditProfile('p', prefetchedProfile: profile);
      final replacementState = controller.nestedGroupLabelState(
        accountProfileId: 'p',
        groupId: 'g',
        label: 'Reloaded parent',
      );
      gate.complete(
        TenantAdminNestedGroupLabelMutationResult(
          idValue: TenantAdminNestedProfileGroupTextValue('g'),
          labelValue: TenantAdminNestedProfileGroupTextValue('Late label'),
        ),
      );

      await save;
      expect(replacementState.value.draft, 'Reloaded parent');
      expect(replacementState.value.isEditing, isFalse);
      controller.dispose();
    },
  );

  test(
    'nested group label ignores late completion after tenant change with equal ids',
    () async {
      final repository = _FakeAccountProfilesRepository(
        <TenantAdminAccountProfile>[],
        const [],
      );
      final tenantScope = _FakeTenantScope();
      tenantScope.selectTenantDomain('tenant-a.localhost');
      final controller = labelController(repository, tenantScope: tenantScope);
      final gate = Completer<TenantAdminNestedGroupLabelMutationResult>();
      repository.patchNestedGroupLabelGate = gate;
      controller.beginNestedGroupLabelEdit(
        accountProfileId: 'p',
        groupId: 'g',
        label: 'Tenant A',
      );
      controller.changeNestedGroupLabelDraft(
        accountProfileId: 'p',
        groupId: 'g',
        label: 'Pending',
      );
      final save = controller.saveNestedGroupLabel(
        accountProfileId: 'p',
        groupId: 'g',
        authoritativeLabel: 'Tenant A',
      );
      tenantScope.selectTenantDomain('tenant-b.localhost');
      await Future<void>.delayed(Duration.zero);
      final replacement = controller.nestedGroupLabelState(
        accountProfileId: 'p',
        groupId: 'g',
        label: 'Tenant B',
      );
      gate.complete(
        TenantAdminNestedGroupLabelMutationResult(
          idValue: TenantAdminNestedProfileGroupTextValue('g'),
          labelValue: TenantAdminNestedProfileGroupTextValue('Late'),
        ),
      );
      await save;
      expect(replacement.value.draft, 'Tenant B');
      controller.dispose();
    },
  );

  test(
    'nested group label state is isolated by profile and group identity',
    () {
      final repository = _FakeAccountProfilesRepository(
        <TenantAdminAccountProfile>[],
        const <TenantAdminProfileTypeDefinition>[],
      );
      final controller = labelController(repository);
      controller.beginNestedGroupLabelEdit(
        accountProfileId: 'profile-a',
        groupId: 'group-a',
        label: 'A',
      );
      controller.changeNestedGroupLabelDraft(
        accountProfileId: 'profile-a',
        groupId: 'group-a',
        label: 'A draft',
      );
      controller.beginNestedGroupLabelEdit(
        accountProfileId: 'profile-a',
        groupId: 'group-b',
        label: 'B',
      );
      controller.beginNestedGroupLabelEdit(
        accountProfileId: 'profile-b',
        groupId: 'group-a',
        label: 'Other A',
      );

      expect(
        controller
            .nestedGroupLabelState(
              accountProfileId: 'profile-a',
              groupId: 'group-a',
              label: 'A',
            )
            .value
            .draft,
        'A draft',
      );
      expect(
        controller
            .nestedGroupLabelState(
              accountProfileId: 'profile-a',
              groupId: 'group-b',
              label: 'B',
            )
            .value
            .draft,
        'B',
      );
      expect(
        controller
            .nestedGroupLabelState(
              accountProfileId: 'profile-b',
              groupId: 'group-a',
              label: 'Other A',
            )
            .value
            .draft,
        'Other A',
      );
      controller.dispose();
    },
  );

  test(
    'nested group label rejects a 256-character draft before transport',
    () async {
      final repository = _FakeAccountProfilesRepository(
        <TenantAdminAccountProfile>[],
        const <TenantAdminProfileTypeDefinition>[],
      );
      final controller = labelController(repository);
      controller.beginNestedGroupLabelEdit(
        accountProfileId: 'p',
        groupId: 'g',
        label: 'Old',
      );
      controller.changeNestedGroupLabelDraft(
        accountProfileId: 'p',
        groupId: 'g',
        label: 'x' * 256,
      );
      await controller.saveNestedGroupLabel(
        accountProfileId: 'p',
        groupId: 'g',
        authoritativeLabel: 'Old',
      );
      expect(repository.patchNestedGroupLabelCalls, 0);
      expect(
        controller
            .nestedGroupLabelState(
              accountProfileId: 'p',
              groupId: 'g',
              label: 'Old',
            )
            .value
            .hasError,
        isTrue,
      );
      controller.dispose();
    },
  );

  test(
    'nested group label trim no-op closes editing without repository mutation',
    () async {
      final repository = _FakeAccountProfilesRepository(
        <TenantAdminAccountProfile>[],
        const <TenantAdminProfileTypeDefinition>[],
      );
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: repository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );
      controller.beginNestedGroupLabelEdit(
        accountProfileId: 'profile-1',
        groupId: 'partners',
        label: 'Partners',
      );
      controller.changeNestedGroupLabelDraft(
        accountProfileId: 'profile-1',
        groupId: 'partners',
        label: ' Partners ',
      );

      await controller.saveNestedGroupLabel(
        accountProfileId: 'profile-1',
        groupId: 'partners',
        authoritativeLabel: 'Partners',
      );

      expect(
        controller
            .nestedGroupLabelState(
              accountProfileId: 'profile-1',
              groupId: 'partners',
              label: 'Partners',
            )
            .value
            .isEditing,
        isFalse,
      );
      expect(repository.patchNestedGroupLabelCalls, 0);
      controller.dispose();
    },
  );

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
    'moveEditNestedProfileGroupHead applies only authoritative order',
    () async {
      final originalGroups = <TenantAdminNestedProfileGroup>[
        TenantAdminNestedProfileGroup(
          idValue: TenantAdminNestedProfileGroupTextValue('artists'),
          labelValue: TenantAdminNestedProfileGroupTextValue('Artists'),
          orderValue: TenantAdminNestedProfileGroupOrderValue(0),
          memberCountValue: TenantAdminCountValue(7),
        ),
        TenantAdminNestedProfileGroup(
          idValue: TenantAdminNestedProfileGroupTextValue('partners'),
          labelValue: TenantAdminNestedProfileGroupTextValue('Partners'),
          orderValue: TenantAdminNestedProfileGroupOrderValue(1),
          memberCountValue: TenantAdminCountValue(11),
        ),
      ];
      final repository = _FakeAccountProfilesRepository([
        tenantAdminAccountProfileFromRaw(
          id: 'profile-1',
          accountId: 'acc-1',
          profileType: 'venue',
          displayName: 'Perfil',
          aggregateRevision: 4,
          nestedProfileGroups: originalGroups,
        ),
      ], const []);
      repository.moveNestedProfileGroupResult =
          TenantAdminGroupOrderMutationResult(
            accountProfileIdValue: TenantAdminNestedProfileGroupTextValue(
              'profile-1',
            ),
            groups: [
              TenantAdminGroupOrderEntry(
                idValue: TenantAdminNestedProfileGroupTextValue('partners'),
                orderValue: TenantAdminNestedProfileGroupOrderValue(0),
              ),
              TenantAdminGroupOrderEntry(
                idValue: TenantAdminNestedProfileGroupTextValue('artists'),
                orderValue: TenantAdminNestedProfileGroupOrderValue(1),
              ),
            ],
          );
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: repository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );
      await controller.loadEditProfile('profile-1');

      await controller.moveEditNestedProfileGroupHead(
        accountProfileId: 'profile-1',
        groupId: 'partners',
        delta: -1,
      );

      expect(repository.moveNestedProfileGroupCalls, 1);
      expect(
        repository.lastMoveNestedProfileGroupDirection,
        TenantAdminGroupMoveDirection.up,
      );
      expect(
        controller.editStateStreamValue.value.nestedProfileGroups.map(
          (group) => group.id,
        ),
        ['partners', 'artists'],
      );
      expect(
        controller.editStateStreamValue.value.nestedProfileGroups.map(
          (group) => group.memberCount,
        ),
        [11, 7],
      );
      expect(
        controller.accountProfileStreamValue.value?.aggregateRevision,
        isNull,
      );
    },
  );

  test(
    'definitive account group move failure preserves local state without reconciliation',
    () async {
      final originalGroups = <TenantAdminNestedProfileGroup>[
        TenantAdminNestedProfileGroup(
          idValue: TenantAdminNestedProfileGroupTextValue('artists'),
          labelValue: TenantAdminNestedProfileGroupTextValue('Local Artists'),
          orderValue: TenantAdminNestedProfileGroupOrderValue(0),
          memberCountValue: TenantAdminCountValue(7),
        ),
        TenantAdminNestedProfileGroup(
          idValue: TenantAdminNestedProfileGroupTextValue('partners'),
          labelValue: TenantAdminNestedProfileGroupTextValue('Local Partners'),
          orderValue: TenantAdminNestedProfileGroupOrderValue(1),
          memberCountValue: TenantAdminCountValue(11),
        ),
      ];
      final repository = _FakeAccountProfilesRepository([
        tenantAdminAccountProfileFromRaw(
          id: 'profile-1',
          accountId: 'acc-1',
          profileType: 'venue',
          displayName: 'Perfil',
          aggregateRevision: 4,
          nestedProfileGroups: originalGroups,
        ),
      ], const []);
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: repository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );
      await controller.loadEditProfile('profile-1');
      repository.moveNestedProfileGroupError = StateError(
        'definitive move failure',
      );

      await controller.moveEditNestedProfileGroupHead(
        accountProfileId: 'profile-1',
        groupId: 'partners',
        delta: -1,
      );

      final groups = controller.editStateStreamValue.value.nestedProfileGroups;
      expect(repository.moveNestedProfileGroupCalls, 1);
      expect(repository.fetchAccountProfileCalls, 1);
      expect(groups.map((group) => group.id), ['artists', 'partners']);
      expect(groups.map((group) => group.label), [
        'Local Artists',
        'Local Partners',
      ]);
      expect(groups.map((group) => group.memberCount), [7, 11]);
      expect(
        controller.editErrorMessageStreamValue.value,
        contains('definitive move failure'),
      );
      expect(controller.editNestedGroupMutationBusyStreamValue.value, isFalse);
    },
  );

  test(
    'foreign group move success performs one GET reconciliation without PATCH replay',
    () async {
      TenantAdminAccountProfile profileWith(
        List<TenantAdminNestedProfileGroup> groups,
        int revision,
      ) => tenantAdminAccountProfileFromRaw(
        id: 'profile-1',
        accountId: 'acc-1',
        profileType: 'venue',
        displayName: 'Perfil',
        aggregateRevision: revision,
        nestedProfileGroups: groups,
      );
      final localGroups = <TenantAdminNestedProfileGroup>[
        TenantAdminNestedProfileGroup(
          idValue: TenantAdminNestedProfileGroupTextValue('artists'),
          labelValue: TenantAdminNestedProfileGroupTextValue('Local Artists'),
          orderValue: TenantAdminNestedProfileGroupOrderValue(0),
          memberCountValue: TenantAdminCountValue(7),
        ),
        TenantAdminNestedProfileGroup(
          idValue: TenantAdminNestedProfileGroupTextValue('partners'),
          labelValue: TenantAdminNestedProfileGroupTextValue('Local Partners'),
          orderValue: TenantAdminNestedProfileGroupOrderValue(1),
          memberCountValue: TenantAdminCountValue(11),
        ),
      ];
      final repository = _FakeAccountProfilesRepository([
        profileWith(localGroups, 4),
      ], const []);
      repository.moveNestedProfileGroupResult =
          TenantAdminGroupOrderMutationResult(
            accountProfileIdValue: TenantAdminNestedProfileGroupTextValue(
              'foreign-profile',
            ),
            groups: [
              TenantAdminGroupOrderEntry(
                idValue: TenantAdminNestedProfileGroupTextValue('partners'),
                orderValue: TenantAdminNestedProfileGroupOrderValue(0),
              ),
              TenantAdminGroupOrderEntry(
                idValue: TenantAdminNestedProfileGroupTextValue('artists'),
                orderValue: TenantAdminNestedProfileGroupOrderValue(1),
              ),
            ],
          );
      final reconciledProfile = profileWith([
        localGroups[1].copyWith(
          orderValue: TenantAdminNestedProfileGroupOrderValue(0),
        ),
        localGroups[0].copyWith(
          orderValue: TenantAdminNestedProfileGroupOrderValue(1),
        ),
      ], 5);
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: repository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );
      await controller.loadEditProfile('profile-1');
      repository.accountProfileFetchOverrides['profile-1'] = reconciledProfile;

      await controller.moveEditNestedProfileGroupHead(
        accountProfileId: 'profile-1',
        groupId: 'partners',
        delta: -1,
      );

      expect(repository.moveNestedProfileGroupCalls, 1);
      expect(repository.fetchAccountProfileCalls, 2);
      expect(
        controller.editStateStreamValue.value.nestedProfileGroups.map(
          (group) => group.id,
        ),
        ['partners', 'artists'],
      );
      expect(
        controller.editStateStreamValue.value.nestedProfileGroups.map(
          (group) => group.label,
        ),
        ['Local Partners', 'Local Artists'],
      );
      expect(controller.accountProfileStreamValue.value?.aggregateRevision, 5);
    },
  );

  test(
    'group move single-flights ten triggers across three repetitions',
    () async {
      for (var repetition = 0; repetition < 3; repetition++) {
        final groups = <TenantAdminNestedProfileGroup>[
          TenantAdminNestedProfileGroup(
            idValue: TenantAdminNestedProfileGroupTextValue('artists'),
            labelValue: TenantAdminNestedProfileGroupTextValue('Artists'),
            orderValue: TenantAdminNestedProfileGroupOrderValue(0),
            memberCountValue: TenantAdminCountValue(7),
          ),
          TenantAdminNestedProfileGroup(
            idValue: TenantAdminNestedProfileGroupTextValue('partners'),
            labelValue: TenantAdminNestedProfileGroupTextValue('Partners'),
            orderValue: TenantAdminNestedProfileGroupOrderValue(1),
            memberCountValue: TenantAdminCountValue(11),
          ),
        ];
        final repository = _FakeAccountProfilesRepository([
          tenantAdminAccountProfileFromRaw(
            id: 'profile-$repetition',
            accountId: 'acc-$repetition',
            profileType: 'venue',
            displayName: 'Perfil',
            nestedProfileGroups: groups,
          ),
        ], const []);
        final gate = Completer<TenantAdminGroupOrderMutationResult>();
        repository.moveNestedProfileGroupGate = gate;
        final controller = TenantAdminAccountProfilesController(
          profilesRepository: repository,
          accountsRepository: _FakeAccountsRepository(),
          taxonomiesRepository: _FakeTaxonomiesRepository(),
          locationSelectionService: TenantAdminLocationSelectionService(),
        );
        await controller.loadEditProfile('profile-$repetition');

        final attempts = List.generate(
          10,
          (_) => controller.moveEditNestedProfileGroupHead(
            accountProfileId: 'profile-$repetition',
            groupId: 'partners',
            delta: -1,
          ),
        );
        await Future.wait(attempts.skip(1));

        expect(repository.moveNestedProfileGroupCalls, 1);
        expect(controller.editNestedGroupMutationBusyStreamValue.value, isTrue);
        gate.complete(
          TenantAdminGroupOrderMutationResult(
            accountProfileIdValue: TenantAdminNestedProfileGroupTextValue(
              'profile-$repetition',
            ),
            groups: [
              TenantAdminGroupOrderEntry(
                idValue: TenantAdminNestedProfileGroupTextValue('partners'),
                orderValue: TenantAdminNestedProfileGroupOrderValue(0),
              ),
              TenantAdminGroupOrderEntry(
                idValue: TenantAdminNestedProfileGroupTextValue('artists'),
                orderValue: TenantAdminNestedProfileGroupOrderValue(1),
              ),
            ],
          ),
        );
        await attempts.first;

        expect(
          controller.editNestedGroupMutationBusyStreamValue.value,
          isFalse,
        );
        expect(
          controller.editStateStreamValue.value.nestedProfileGroups.map(
            (group) => group.id,
          ),
          ['partners', 'artists'],
        );
        controller.dispose();
      }
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
    'loadEditProfile does not open a candidate query when persisted mode is own',
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

      expect(profilesRepository.fetchAccountProfilesPageCalls, 0);
    },
  );

  test(
    'loadEditProfile hydrates only the selected mirrored contact source',
    () async {
      final profilesRepository = _FakeAccountProfilesRepository([
        tenantAdminAccountProfileFromRaw(
          id: '507f1f77bcf86cd799439011',
          accountId: 'acc-1',
          profileType: 'venue',
          displayName: 'Perfil',
          contactMode: BellugaContactSourceMode.mirroredAccountProfile,
          contactSourceAccountProfileId: '507f1f77bcf86cd799439012',
        ),
      ], const []);
      profilesRepository
              .accountProfileFetchOverrides['507f1f77bcf86cd799439012'] =
          tenantAdminAccountProfileFromRaw(
            id: '507f1f77bcf86cd799439012',
            accountId: 'acc-source',
            profileType: 'venue',
            displayName: 'Origem',
          );
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );

      await controller.loadEditProfile('507f1f77bcf86cd799439011');
      await Future<void>.delayed(Duration.zero);

      expect(profilesRepository.fetchAccountProfilesPageCalls, 0);
      expect(
        profilesRepository.lastFetchedProfileId,
        '507f1f77bcf86cd799439012',
      );
      expect(
        controller.selectedContactSourceProfilesStreamValue.value.single.id,
        '507f1f77bcf86cd799439012',
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
    'applyEditNestedGroupSelectionDelta sends only the explicit bounded delta',
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
      profilesRepository.accountProfileFetchOverrides['profile-1'] =
          refreshedProfile;
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );

      final current = TenantAdminAccountProfileSelectionSummary(
        idValue: TenantAdminAccountProfileIdValue('profile-a'),
        displayNameValue: TenantAdminOptionalTextValue()..parse('Perfil A'),
        isQueryableCandidateValue: TenantAdminFlagValue(true),
      );

      final saved = await controller.applyEditNestedGroupSelectionDelta(
        accountProfileId: 'profile-1',
        groupId: 'parceiros',
        previousSelections: <TenantAdminAccountProfileSelectionSummary>[
          current,
        ],
        nextSelections: <TenantAdminAccountProfileSelectionSummary>[
          current,
          TenantAdminAccountProfileSelectionSummary(
            idValue: TenantAdminAccountProfileIdValue('profile-c'),
            displayNameValue: TenantAdminOptionalTextValue()..parse('Perfil C'),
            isQueryableCandidateValue: TenantAdminFlagValue(true),
          ),
        ],
      );

      expect(saved, isTrue);
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
      expect(profilesRepository.lastPatchNestedGroupRemoveIds, isEmpty);
      expect(controller.accountProfileStreamValue.value?.aggregateRevision, 5);
      expect(
        controller.editSuccessMessageStreamValue.value,
        'Perfis vinculados atualizados.',
      );
    },
  );

  test(
    'submitUpdateProfile preserves independently loaded gallery state',
    () async {
      final loadedProfile = tenantAdminAccountProfileFromRaw(
        id: 'profile-1',
        accountId: 'acc-1',
        profileType: 'venue',
        displayName: 'Perfil',
        galleryGroups: [_galleryGroup()],
        galleryCapabilities: TenantAdminAccountProfileGalleryCapabilities(
          maxGalleriesValue: TenantAdminCountValue(6),
          maxItemsPerGalleryValue: TenantAdminCountValue(12),
        ),
      );
      final profilesRepository =
          _FakeAccountProfilesRepository(
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
                    hasTaxonomies: TenantAdminFlagValue(false),
                    hasAvatar: TenantAdminFlagValue(false),
                    hasCover: TenantAdminFlagValue(false),
                    hasEvents: TenantAdminFlagValue(false),
                  ),
                ),
              ],
            )
            ..updateAccountProfileOverride = tenantAdminAccountProfileFromRaw(
              id: 'profile-1',
              accountId: 'acc-1',
              profileType: 'venue',
              displayName: 'Perfil atualizado',
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
        taxonomyTerms: const TenantAdminTaxonomyTerms.empty(),
        avatarUpload: null,
        coverUpload: null,
      );

      expect(controller.editStateStreamValue.value.galleryGroups, hasLength(1));
      expect(
        controller.editStateStreamValue.value.galleryCapabilities.maxGalleries,
        6,
      );
      expect(
        controller
            .editStateStreamValue
            .value
            .galleryCapabilities
            .maxItemsPerGallery,
        12,
      );
    },
  );

  test(
    'submitAutoSaveImages preserves independently loaded gallery state',
    () async {
      final loadedProfile = tenantAdminAccountProfileFromRaw(
        id: 'profile-1',
        accountId: 'acc-1',
        profileType: 'venue',
        displayName: 'Perfil',
        galleryGroups: [_galleryGroup()],
        galleryCapabilities: TenantAdminAccountProfileGalleryCapabilities(
          maxGalleriesValue: TenantAdminCountValue(7),
          maxItemsPerGalleryValue: TenantAdminCountValue(13),
        ),
      );
      final profilesRepository =
          _FakeAccountProfilesRepository([loadedProfile], const [])
            ..updateAccountProfileOverride = tenantAdminAccountProfileFromRaw(
              id: 'profile-1',
              accountId: 'acc-1',
              profileType: 'venue',
              displayName: 'Perfil',
              avatarUrl: 'https://tenant.test/avatar.png',
            );
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );

      await controller.loadEditProfile('profile-1');
      await controller.submitAutoSaveImages(
        accountProfileId: 'profile-1',
        avatarUpload: null,
        coverUpload: null,
        avatarUrl: 'https://tenant.test/avatar.png',
      );

      expect(
        controller.editStateStreamValue.value.galleryGroups.single.groupId,
        'group-1',
      );
      expect(
        controller.editStateStreamValue.value.galleryCapabilities.maxGalleries,
        7,
      );
      expect(
        controller
            .editStateStreamValue
            .value
            .galleryCapabilities
            .maxItemsPerGallery,
        13,
      );
    },
  );

  for (final burstSize in <int>[5, 10, 20]) {
    test(
      'gallery mutation rejects a burst of $burstSize while busy and recovers',
      () async {
        final snapshot = TenantAdminAccountProfileGallerySnapshot(
          groups: [_galleryGroup()],
          capabilities: TenantAdminAccountProfileGalleryCapabilities(
            maxGalleriesValue: TenantAdminCountValue(6),
            maxItemsPerGalleryValue: TenantAdminCountValue(12),
          ),
        );
        final gate = Completer<TenantAdminAccountProfileGallerySnapshot>();
        final profilesRepository =
            _FakeAccountProfilesRepository([
                tenantAdminAccountProfileFromRaw(
                  id: 'profile-1',
                  accountId: 'acc-1',
                  profileType: 'venue',
                  displayName: 'Perfil',
                ),
              ], const [])
              ..gallerySnapshotToReturn = snapshot
              ..createGalleryGroupGates.add(gate);
        final controller = TenantAdminAccountProfilesController(
          profilesRepository: profilesRepository,
          accountsRepository: _FakeAccountsRepository(),
          taxonomiesRepository: _FakeTaxonomiesRepository(),
          locationSelectionService: TenantAdminLocationSelectionService(),
        );

        await controller.loadEditProfile('profile-1');
        final pending = List<Future<void>>.generate(
          burstSize,
          (_) => controller.addEditGalleryGroup('Ambiente'),
        );

        expect(profilesRepository.createGalleryGroupCalls, 1);
        expect(controller.editGalleryMutationBusyStreamValue.value, isTrue);

        gate.complete(snapshot);
        await Future.wait(pending);
        expect(controller.editGalleryMutationBusyStreamValue.value, isFalse);

        await controller.addEditGalleryGroup('Palco');
        expect(profilesRepository.createGalleryGroupCalls, 2);
      },
    );
  }

  test('busy gallery mutation blocks optimistic reorder effects', () async {
    final profile = tenantAdminAccountProfileFromRaw(
      id: 'profile-1',
      accountId: 'acc-1',
      profileType: 'venue',
      displayName: 'Perfil',
      galleryGroups: [
        _galleryGroup(includeSecondItem: true),
        _galleryGroup(groupId: 'group-2', order: 1),
      ],
    );
    final gate = Completer<TenantAdminAccountProfileGallerySnapshot>();
    final profilesRepository =
        _FakeAccountProfilesRepository([profile], const [])
          ..gallerySnapshotToReturn = TenantAdminAccountProfileGallerySnapshot(
            groups: profile.galleryGroups,
            capabilities: profile.galleryCapabilities,
          )
          ..createGalleryGroupGates.add(gate);
    final controller = TenantAdminAccountProfilesController(
      profilesRepository: profilesRepository,
      accountsRepository: _FakeAccountsRepository(),
      taxonomiesRepository: _FakeTaxonomiesRepository(),
      locationSelectionService: TenantAdminLocationSelectionService(),
    );

    await controller.loadEditProfile('profile-1');
    final pending = controller.addEditGalleryGroup('Pendente');
    await controller.moveEditGalleryGroup('group-1', 1);
    await controller.moveEditGalleryItem(
      groupId: 'group-1',
      itemId: 'item-1',
      delta: 1,
    );

    expect(profilesRepository.reorderGalleryGroupsCalls, 0);
    expect(profilesRepository.galleryMutationCalls, isEmpty);
    expect(
      controller.editStateStreamValue.value.galleryGroups.map(
        (group) => group.groupId,
      ),
      ['group-1', 'group-2'],
    );
    expect(
      controller.editStateStreamValue.value.galleryGroups.first.items.map(
        (item) => item.itemId,
      ),
      ['item-1', 'item-2'],
    );

    gate.complete(profilesRepository.gallerySnapshotToReturn!);
    await pending;
  });

  test(
    'profile switch during upload preparation prevents repository mutation',
    () async {
      final profileA = tenantAdminAccountProfileFromRaw(
        id: 'profile-a',
        accountId: 'acc-1',
        profileType: 'venue',
        displayName: 'Perfil A',
      );
      final profileB = tenantAdminAccountProfileFromRaw(
        id: 'profile-b',
        accountId: 'acc-1',
        profileType: 'venue',
        displayName: 'Perfil B',
        galleryGroups: [_galleryGroup(groupId: 'group-b')],
      );
      final uploadGate = Completer<TenantAdminMediaUpload?>();
      final profilesRepository =
          _FakeAccountProfilesRepository([profileA, profileB], const [])
            ..gallerySnapshotToReturn =
                TenantAdminAccountProfileGallerySnapshot(
                  groups: profileA.galleryGroups,
                  capabilities: profileA.galleryCapabilities,
                );
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
        imageIngestionService: _DelayedImageIngestionService(uploadGate),
      );

      await controller.loadEditProfile('profile-a');
      final pending = controller.addEditGalleryPhoto(
        groupId: 'group-a',
        uploadFile: XFile.fromData(Uint8List.fromList(<int>[1])),
      );
      expect(controller.editGalleryMutationBusyStreamValue.value, isTrue);

      await controller.loadEditProfile(
        'profile-b',
        prefetchedProfile: profileB,
      );
      uploadGate.complete(
        tenantAdminMediaUploadFromRaw(
          bytes: Uint8List.fromList(<int>[1]),
          fileName: 'gallery.jpg',
          mimeType: 'image/jpeg',
        ),
      );
      await pending;

      expect(profilesRepository.galleryMutationCalls, isEmpty);
      expect(controller.editGalleryMutationBusyStreamValue.value, isFalse);
      expect(
        controller.editStateStreamValue.value.galleryGroups.single.groupId,
        'group-b',
      );
    },
  );

  test(
    'replace upload preparation is fenced before repository mutation',
    () async {
      final profileA = tenantAdminAccountProfileFromRaw(
        id: 'profile-a',
        accountId: 'acc-1',
        profileType: 'venue',
        displayName: 'Perfil A',
        galleryGroups: [_galleryGroup()],
      );
      final profileB = tenantAdminAccountProfileFromRaw(
        id: 'profile-b',
        accountId: 'acc-1',
        profileType: 'venue',
        displayName: 'Perfil B',
        galleryGroups: [_galleryGroup(groupId: 'group-b')],
      );
      final uploadGate = Completer<TenantAdminMediaUpload?>();
      final profilesRepository = _FakeAccountProfilesRepository([
        profileA,
        profileB,
      ], const []);
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
        imageIngestionService: _DelayedImageIngestionService(uploadGate),
      );

      await controller.loadEditProfile('profile-a');
      final pending = controller.replaceEditGalleryItemUpload(
        groupId: 'group-1',
        itemId: 'item-1',
        uploadFile: XFile.fromData(Uint8List.fromList(<int>[1])),
      );
      expect(controller.editGalleryMutationBusyStreamValue.value, isTrue);
      await controller.loadEditProfile(
        'profile-b',
        prefetchedProfile: profileB,
      );
      uploadGate.complete(
        tenantAdminMediaUploadFromRaw(
          bytes: Uint8List.fromList(<int>[1]),
          fileName: 'gallery.jpg',
          mimeType: 'image/jpeg',
        ),
      );
      await pending;

      expect(profilesRepository.galleryMutationCalls, isEmpty);
      expect(
        controller.editStateStreamValue.value.galleryGroups.single.groupId,
        'group-b',
      );
    },
  );

  test('stale gallery completion cannot clear Profile B busy state', () async {
    final snapshotA = TenantAdminAccountProfileGallerySnapshot(
      groups: [_galleryGroup(groupId: 'group-a')],
      capabilities: TenantAdminAccountProfileGalleryCapabilities(
        maxGalleriesValue: TenantAdminCountValue(6),
        maxItemsPerGalleryValue: TenantAdminCountValue(12),
      ),
    );
    final snapshotB = TenantAdminAccountProfileGallerySnapshot(
      groups: [_galleryGroup(groupId: 'group-b')],
      capabilities: TenantAdminAccountProfileGalleryCapabilities(
        maxGalleriesValue: TenantAdminCountValue(7),
        maxItemsPerGalleryValue: TenantAdminCountValue(13),
      ),
    );
    final gateA = Completer<TenantAdminAccountProfileGallerySnapshot>();
    final gateB = Completer<TenantAdminAccountProfileGallerySnapshot>();
    final profileA = tenantAdminAccountProfileFromRaw(
      id: 'profile-a',
      accountId: 'acc-1',
      profileType: 'venue',
      displayName: 'Perfil A',
    );
    final profileB = tenantAdminAccountProfileFromRaw(
      id: 'profile-b',
      accountId: 'acc-1',
      profileType: 'venue',
      displayName: 'Perfil B',
      galleryGroups: [_galleryGroup(groupId: 'group-b')],
    );
    final profilesRepository =
        _FakeAccountProfilesRepository([profileA, profileB], const [])
          ..gallerySnapshotToReturn = snapshotB
          ..createGalleryGroupGates.addAll([gateA, gateB]);
    final controller = TenantAdminAccountProfilesController(
      profilesRepository: profilesRepository,
      accountsRepository: _FakeAccountsRepository(),
      taxonomiesRepository: _FakeTaxonomiesRepository(),
      locationSelectionService: TenantAdminLocationSelectionService(),
    );

    await controller.loadEditProfile('profile-a');
    final pendingA = controller.addEditGalleryGroup('A');
    await controller.loadEditProfile('profile-b', prefetchedProfile: profileB);
    final pendingB = controller.addEditGalleryGroup('B');

    gateA.complete(snapshotA);
    await pendingA;
    expect(controller.editGalleryMutationBusyStreamValue.value, isTrue);
    expect(
      controller.editStateStreamValue.value.galleryGroups.single.groupId,
      'group-b',
    );

    gateB.complete(snapshotB);
    await pendingB;
    expect(controller.editGalleryMutationBusyStreamValue.value, isFalse);
    expect(
      controller.editStateStreamValue.value.galleryGroups.single.groupId,
      'group-b',
    );
  });

  test('same-profile reload fences gallery completion by generation', () async {
    final staleSnapshot = TenantAdminAccountProfileGallerySnapshot(
      groups: [_galleryGroup(groupId: 'group-stale')],
      capabilities: TenantAdminAccountProfileGalleryCapabilities(
        maxGalleriesValue: TenantAdminCountValue(99),
        maxItemsPerGalleryValue: TenantAdminCountValue(99),
      ),
    );
    final initial = tenantAdminAccountProfileFromRaw(
      id: 'profile-1',
      accountId: 'acc-1',
      profileType: 'venue',
      displayName: 'Perfil inicial',
    );
    final reloaded = tenantAdminAccountProfileFromRaw(
      id: 'profile-1',
      accountId: 'acc-1',
      profileType: 'venue',
      displayName: 'Perfil recarregado',
      galleryGroups: [_galleryGroup(groupId: 'group-current')],
    );
    final gate = Completer<TenantAdminAccountProfileGallerySnapshot>();
    final profilesRepository =
        _FakeAccountProfilesRepository([initial], const [])
          ..gallerySnapshotToReturn = staleSnapshot
          ..createGalleryGroupGates.add(gate);
    final controller = TenantAdminAccountProfilesController(
      profilesRepository: profilesRepository,
      accountsRepository: _FakeAccountsRepository(),
      taxonomiesRepository: _FakeTaxonomiesRepository(),
      locationSelectionService: TenantAdminLocationSelectionService(),
    );

    await controller.loadEditProfile('profile-1');
    final pending = controller.addEditGalleryGroup('Antiga');
    await controller.loadEditProfile('profile-1', prefetchedProfile: reloaded);
    gate.complete(staleSnapshot);
    await pending;

    expect(controller.editGalleryMutationBusyStreamValue.value, isFalse);
    expect(
      controller.editStateStreamValue.value.galleryGroups.single.groupId,
      'group-current',
    );
  });

  test(
    'stale capacity refresh and finally cannot publish into Profile B',
    () async {
      final profileA = tenantAdminAccountProfileFromRaw(
        id: 'profile-a',
        accountId: 'acc-1',
        profileType: 'venue',
        displayName: 'Perfil A',
      );
      final profileB = tenantAdminAccountProfileFromRaw(
        id: 'profile-b',
        accountId: 'acc-1',
        profileType: 'venue',
        displayName: 'Perfil B',
        galleryGroups: [_galleryGroup(groupId: 'group-b')],
        galleryCapabilities: TenantAdminAccountProfileGalleryCapabilities(
          maxGalleriesValue: TenantAdminCountValue(7),
          maxItemsPerGalleryValue: TenantAdminCountValue(13),
        ),
      );
      final refreshedA = tenantAdminAccountProfileFromRaw(
        id: 'profile-a',
        accountId: 'acc-1',
        profileType: 'venue',
        displayName: 'Perfil A atualizado',
        galleryGroups: [_galleryGroup(groupId: 'group-a-refreshed')],
        galleryCapabilities: TenantAdminAccountProfileGalleryCapabilities(
          maxGalleriesValue: TenantAdminCountValue(99),
          maxItemsPerGalleryValue: TenantAdminCountValue(99),
        ),
      );
      final gateA = Completer<TenantAdminAccountProfileGallerySnapshot>();
      final gateB = Completer<TenantAdminAccountProfileGallerySnapshot>();
      final refreshA = Completer<TenantAdminAccountProfile>();
      final refreshStarted = Completer<void>();
      final snapshotB = TenantAdminAccountProfileGallerySnapshot(
        groups: profileB.galleryGroups,
        capabilities: profileB.galleryCapabilities,
      );
      final profilesRepository =
          _FakeAccountProfilesRepository([profileA, profileB], const [])
            ..gallerySnapshotToReturn = snapshotB
            ..createGalleryGroupGates.addAll([gateA, gateB]);
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );

      await controller.loadEditProfile('profile-a');
      profilesRepository
        ..accountProfileFetchFutures['profile-a'] = refreshA.future
        ..fetchAccountProfileSignal = refreshStarted;
      final pendingA = controller.addEditGalleryGroup('A');
      gateA.completeError(
        FormValidationFailure(
          statusCode: 422,
          message: 'Limite antigo',
          fieldErrors: const {
            'gallery_capabilities.max_galleries': ['Limite antigo'],
          },
        ),
      );
      await refreshStarted.future;

      await controller.loadEditProfile(
        'profile-b',
        prefetchedProfile: profileB,
      );
      controller.updateEditGalleryInputValue('draft-b', 'preservar');
      final pendingB = controller.addEditGalleryGroup('B');
      refreshA.complete(refreshedA);
      await pendingA;

      expect(controller.editGalleryMutationBusyStreamValue.value, isTrue);
      expect(controller.editGalleryFieldErrorsStreamValue.value, isEmpty);
      expect(controller.editGalleryOperationErrorStreamValue.value, isNull);
      expect(controller.editGalleryInputValue('draft-b', ''), 'preservar');
      expect(
        controller.editStateStreamValue.value.galleryGroups.single.groupId,
        'group-b',
      );
      expect(
        controller.editStateStreamValue.value.galleryCapabilities.maxGalleries,
        7,
      );

      gateB.complete(snapshotB);
      await pendingB;
      expect(controller.editGalleryMutationBusyStreamValue.value, isFalse);
    },
  );

  test('resetEditState fences completion by Profile identity', () async {
    final staleSnapshot = TenantAdminAccountProfileGallerySnapshot(
      groups: [_galleryGroup(groupId: 'group-stale')],
      capabilities: TenantAdminAccountProfileGalleryCapabilities(
        maxGalleriesValue: TenantAdminCountValue(6),
        maxItemsPerGalleryValue: TenantAdminCountValue(12),
      ),
    );
    final gate = Completer<TenantAdminAccountProfileGallerySnapshot>();
    final profilesRepository =
        _FakeAccountProfilesRepository([
            tenantAdminAccountProfileFromRaw(
              id: 'profile-1',
              accountId: 'acc-1',
              profileType: 'venue',
              displayName: 'Perfil',
            ),
          ], const [])
          ..gallerySnapshotToReturn = staleSnapshot
          ..createGalleryGroupGates.add(gate);
    final controller = TenantAdminAccountProfilesController(
      profilesRepository: profilesRepository,
      accountsRepository: _FakeAccountsRepository(),
      taxonomiesRepository: _FakeTaxonomiesRepository(),
      locationSelectionService: TenantAdminLocationSelectionService(),
    );

    await controller.loadEditProfile('profile-1');
    final pending = controller.addEditGalleryGroup('Antiga');
    controller.updateEditGalleryInputValue('draft', 'antigo');
    controller.resetEditState();
    gate.complete(staleSnapshot);
    await pending;

    expect(controller.editGalleryMutationBusyStreamValue.value, isFalse);
    expect(controller.editGalleryFieldErrorsStreamValue.value, isEmpty);
    expect(controller.editGalleryOperationErrorStreamValue.value, isNull);
    expect(controller.editGalleryInputValue('draft', ''), isEmpty);
    expect(controller.editStateStreamValue.value.galleryGroups, isEmpty);
  });

  test('stale validation error cannot publish into Profile B', () async {
    final profileA = tenantAdminAccountProfileFromRaw(
      id: 'profile-a',
      accountId: 'acc-1',
      profileType: 'venue',
      displayName: 'Perfil A',
      galleryGroups: [_galleryGroup()],
    );
    final profileB = tenantAdminAccountProfileFromRaw(
      id: 'profile-b',
      accountId: 'acc-1',
      profileType: 'venue',
      displayName: 'Perfil B',
      galleryGroups: [_galleryGroup(groupId: 'group-b')],
    );
    final gate = Completer<TenantAdminAccountProfileGallerySnapshot>();
    final profilesRepository = _FakeAccountProfilesRepository([
      profileA,
      profileB,
    ], const [])..updateGalleryItemGate = gate;
    final controller = TenantAdminAccountProfilesController(
      profilesRepository: profilesRepository,
      accountsRepository: _FakeAccountsRepository(),
      taxonomiesRepository: _FakeTaxonomiesRepository(),
      locationSelectionService: TenantAdminLocationSelectionService(),
    );

    await controller.loadEditProfile('profile-a');
    final pending = controller.updateEditGalleryItemTitle(
      groupId: 'group-1',
      itemId: 'item-1',
      title: 'Inválido',
    );
    await controller.loadEditProfile('profile-b', prefetchedProfile: profileB);
    gate.completeError(
      FormValidationFailure(
        statusCode: 422,
        message: 'Erro antigo',
        fieldErrors: const {
          'title': ['Erro antigo'],
        },
      ),
    );
    await pending;

    expect(controller.editGalleryFieldErrorsStreamValue.value, isEmpty);
    expect(controller.editGalleryOperationErrorStreamValue.value, isNull);
    expect(
      controller.editStateStreamValue.value.galleryGroups.single.groupId,
      'group-b',
    );
  });

  test('stale reorder error cannot roll Profile B back to Profile A', () async {
    final profileA = tenantAdminAccountProfileFromRaw(
      id: 'profile-a',
      accountId: 'acc-1',
      profileType: 'venue',
      displayName: 'Perfil A',
      galleryGroups: [
        _galleryGroup(),
        _galleryGroup(groupId: 'group-a-2', order: 1),
      ],
    );
    final profileB = tenantAdminAccountProfileFromRaw(
      id: 'profile-b',
      accountId: 'acc-1',
      profileType: 'venue',
      displayName: 'Perfil B',
      galleryGroups: [_galleryGroup(groupId: 'group-b')],
    );
    final gate = Completer<TenantAdminAccountProfileGallerySnapshot>();
    final profilesRepository = _FakeAccountProfilesRepository([
      profileA,
      profileB,
    ], const [])..reorderGalleryGroupsGate = gate;
    final controller = TenantAdminAccountProfilesController(
      profilesRepository: profilesRepository,
      accountsRepository: _FakeAccountsRepository(),
      taxonomiesRepository: _FakeTaxonomiesRepository(),
      locationSelectionService: TenantAdminLocationSelectionService(),
    );

    await controller.loadEditProfile('profile-a');
    final pending = controller.moveEditGalleryGroup('group-1', 1);
    expect(
      controller.editStateStreamValue.value.galleryGroups.first.groupId,
      'group-a-2',
    );
    await controller.loadEditProfile('profile-b', prefetchedProfile: profileB);
    gate.completeError(StateError('erro antigo'));
    await pending;

    expect(controller.editGalleryOperationErrorStreamValue.value, isNull);
    expect(
      controller.editStateStreamValue.value.galleryGroups.single.groupId,
      'group-b',
    );
  });

  test('gallery create applies the authoritative mutation snapshot', () async {
    final profilesRepository =
        _FakeAccountProfilesRepository([
            tenantAdminAccountProfileFromRaw(
              id: 'profile-1',
              accountId: 'acc-1',
              profileType: 'venue',
              displayName: 'Perfil',
            ),
          ], const [])
          ..gallerySnapshotToReturn = TenantAdminAccountProfileGallerySnapshot(
            groups: [_galleryGroup()],
            capabilities: TenantAdminAccountProfileGalleryCapabilities(
              maxGalleriesValue: TenantAdminCountValue(6),
              maxItemsPerGalleryValue: TenantAdminCountValue(12),
            ),
          );
    final controller = TenantAdminAccountProfilesController(
      profilesRepository: profilesRepository,
      accountsRepository: _FakeAccountsRepository(),
      taxonomiesRepository: _FakeTaxonomiesRepository(),
      locationSelectionService: TenantAdminLocationSelectionService(),
    );

    await controller.loadEditProfile('profile-1');
    await controller.addEditGalleryGroup('Ambiente');

    expect(profilesRepository.createGalleryGroupCalls, 1);
    expect(controller.editStateStreamValue.value.galleryGroups, hasLength(1));
    expect(
      controller.editStateStreamValue.value.galleryCapabilities.maxGalleries,
      6,
    );
  });

  test('gallery controller delegates independent CRUD mutations', () async {
    final snapshot = TenantAdminAccountProfileGallerySnapshot(
      groups: [_galleryGroup()],
      capabilities: TenantAdminAccountProfileGalleryCapabilities(
        maxGalleriesValue: TenantAdminCountValue(6),
        maxItemsPerGalleryValue: TenantAdminCountValue(12),
      ),
    );
    final profilesRepository = _FakeAccountProfilesRepository([
      tenantAdminAccountProfileFromRaw(
        id: 'profile-1',
        accountId: 'acc-1',
        profileType: 'venue',
        displayName: 'Perfil',
        galleryGroups: [_galleryGroup()],
      ),
    ], const [])..gallerySnapshotToReturn = snapshot;
    final controller = TenantAdminAccountProfilesController(
      profilesRepository: profilesRepository,
      accountsRepository: _FakeAccountsRepository(),
      taxonomiesRepository: _FakeTaxonomiesRepository(),
      locationSelectionService: TenantAdminLocationSelectionService(),
    );

    await controller.loadEditProfile('profile-1');
    await controller.renameEditGalleryGroup('group-1', 'Palco');
    await controller.addEditGalleryYoutube(
      groupId: 'group-1',
      youtubeUrl: 'https://youtu.be/dQw4w9WgXcQ',
    );
    await controller.replaceEditGalleryYoutube(
      groupId: 'group-1',
      itemId: 'item-1',
      youtubeUrl: 'https://youtube.com/shorts/69ePBThnsVg',
    );
    await controller.updateEditGalleryItemDescription(
      groupId: 'group-1',
      itemId: 'item-1',
      description: 'Vista principal',
    );
    await controller.updateEditGalleryItemTitle(
      groupId: 'group-1',
      itemId: 'item-1',
      title: 'Um minuto na praia',
    );
    await controller.removeEditGalleryItem(
      groupId: 'group-1',
      itemId: 'item-1',
    );
    await controller.removeEditGalleryGroup('group-1');

    expect(profilesRepository.galleryMutationCalls, [
      'rename:profile-1:group-1:Palco',
      'create-item:profile-1:group-1:youtube:https://youtu.be/dQw4w9WgXcQ',
      'update-item:profile-1:group-1:item-1:null:null:https://youtube.com/shorts/69ePBThnsVg',
      'update-item:profile-1:group-1:item-1:null:Vista principal:null',
      'update-item:profile-1:group-1:item-1:Um minuto na praia:null:null',
      'delete-item:profile-1:group-1:item-1',
      'delete-group:profile-1:group-1',
    ]);
    expect(controller.editStateStreamValue.value.galleryGroups, hasLength(1));
  });

  test(
    'gallery reorder restores the prior row after a transport failure',
    () async {
      final profilesRepository =
          _FakeAccountProfilesRepository([
              tenantAdminAccountProfileFromRaw(
                id: 'profile-1',
                accountId: 'acc-1',
                profileType: 'venue',
                displayName: 'Perfil',
                galleryGroups: [
                  _galleryGroup(),
                  _galleryGroup(
                    groupId: 'group-2',
                    subtitle: 'Palco',
                    order: 1,
                  ),
                ],
              ),
            ], const [])
            ..reorderGalleryGroupsError = FormValidationFailure(
              statusCode: 422,
              message: 'A ordem mudou no servidor.',
              fieldErrors: const {
                'group_ids': ['A lista de grupos está desatualizada.'],
                'title': ['Não existe campo de título neste reorder.'],
              },
            );
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );

      await controller.loadEditProfile('profile-1');
      await controller.moveEditGalleryGroup('group-1', 1);

      expect(profilesRepository.reorderGalleryGroupsCalls, 1);
      expect(
        controller.editStateStreamValue.value.galleryGroups.map(
          (group) => group.groupId,
        ),
        ['group-1', 'group-2'],
      );
      expect(controller.editGalleryFieldErrorsStreamValue.value, isEmpty);
      expect(
        controller.editGalleryOperationErrorStreamValue.value,
        'A ordem mudou no servidor.',
      );
      expect(controller.editErrorMessageStreamValue.value, isNull);
    },
  );

  test(
    'capability-loss validation remains visible as an operation error',
    () async {
      final profilesRepository =
          _FakeAccountProfilesRepository([
              tenantAdminAccountProfileFromRaw(
                id: 'profile-1',
                accountId: 'acc-1',
                profileType: 'venue',
                displayName: 'Perfil',
              ),
            ], const [])
            ..createGalleryGroupError = FormValidationFailure(
              statusCode: 422,
              message: 'Galerias não estão disponíveis para este perfil.',
              fieldErrors: const {
                'gallery_groups': ['A capability de galeria foi removida.'],
              },
            );
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );

      await controller.loadEditProfile('profile-1');
      await controller.addEditGalleryGroup('Ambiente');

      expect(controller.editGalleryFieldErrorsStreamValue.value, isEmpty);
      expect(
        controller.editGalleryOperationErrorStreamValue.value,
        'Galerias não estão disponíveis para este perfil.',
      );
      expect(controller.editErrorMessageStreamValue.value, isNull);
    },
  );

  test('gallery item reorder restores the prior row after failure', () async {
    final profilesRepository = _FakeAccountProfilesRepository([
      tenantAdminAccountProfileFromRaw(
        id: 'profile-1',
        accountId: 'acc-1',
        profileType: 'venue',
        displayName: 'Perfil',
        galleryGroups: [_galleryGroup(includeSecondItem: true)],
      ),
    ], const [])..reorderGalleryItemsError = StateError('offline');
    final controller = TenantAdminAccountProfilesController(
      profilesRepository: profilesRepository,
      accountsRepository: _FakeAccountsRepository(),
      taxonomiesRepository: _FakeTaxonomiesRepository(),
      locationSelectionService: TenantAdminLocationSelectionService(),
    );

    await controller.loadEditProfile('profile-1');
    await controller.moveEditGalleryItem(
      groupId: 'group-1',
      itemId: 'item-1',
      delta: 1,
    );

    expect(
      profilesRepository.galleryMutationCalls.single,
      'reorder-items:profile-1:group-1:item-2,item-1',
    );
    expect(
      controller.editStateStreamValue.value.galleryGroups.single.items.map(
        (item) => item.itemId,
      ),
      ['item-1', 'item-2'],
    );
  });

  test(
    'capacity rejection refreshes once and never replays the mutation',
    () async {
      final profilesRepository =
          _FakeAccountProfilesRepository([
              tenantAdminAccountProfileFromRaw(
                id: 'profile-1',
                accountId: 'acc-1',
                profileType: 'venue',
                displayName: 'Perfil',
                galleryCapabilities:
                    TenantAdminAccountProfileGalleryCapabilities(
                      maxGalleriesValue: TenantAdminCountValue(2),
                      maxItemsPerGalleryValue: TenantAdminCountValue(3),
                    ),
              ),
            ], const [])
            ..createGalleryGroupError = FormValidationFailure(
              statusCode: 422,
              message: 'Limite do plano atingido.',
              fieldErrors: const {
                'gallery_capabilities.max_galleries': ['Limite atingido.'],
              },
            );
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );

      await controller.loadEditProfile('profile-1');
      await controller.addEditGalleryGroup('Outra');

      expect(profilesRepository.createGalleryGroupCalls, 1);
      expect(profilesRepository.fetchAccountProfileCalls, 2);
      expect(
        controller.editGalleryFieldErrorsStreamValue.value,
        contains('gallery_capabilities.max_galleries'),
      );
      expect(controller.editGalleryOperationErrorStreamValue.value, isNull);
    },
  );

  test('gallery item validation is scoped to the addressed control', () async {
    final profilesRepository =
        _FakeAccountProfilesRepository([
            tenantAdminAccountProfileFromRaw(
              id: 'profile-1',
              accountId: 'acc-1',
              profileType: 'venue',
              displayName: 'Perfil',
              galleryGroups: [_galleryGroup()],
            ),
          ], const [])
          ..updateGalleryItemError = FormValidationFailure(
            statusCode: 422,
            message: 'Título inválido.',
            fieldErrors: const {
              'title': ['Use no máximo 255 caracteres.'],
            },
          );
    final controller = TenantAdminAccountProfilesController(
      profilesRepository: profilesRepository,
      accountsRepository: _FakeAccountsRepository(),
      taxonomiesRepository: _FakeTaxonomiesRepository(),
      locationSelectionService: TenantAdminLocationSelectionService(),
    );

    await controller.loadEditProfile('profile-1');
    await controller.updateEditGalleryItemTitle(
      groupId: 'group-1',
      itemId: 'item-1',
      title: 'Título corrigível',
    );

    expect(controller.editGalleryFieldErrorsStreamValue.value, {
      'group.group-1.item.item-1.title': 'Use no máximo 255 caracteres.',
    });
    expect(controller.editGalleryOperationErrorStreamValue.value, isNull);
    expect(controller.editErrorMessageStreamValue.value, isNull);
  });

  test(
    'gallery operation failure stays section-owned until the next mutation',
    () async {
      final profile = tenantAdminAccountProfileFromRaw(
        id: 'profile-1',
        accountId: 'acc-1',
        profileType: 'venue',
        displayName: 'Perfil',
        galleryGroups: [_galleryGroup()],
      );
      final profilesRepository = _FakeAccountProfilesRepository([
        profile,
      ], const [])..updateGalleryItemError = Exception('Falha de rede');
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );

      await controller.loadEditProfile('profile-1');
      await controller.updateEditGalleryItemTitle(
        groupId: 'group-1',
        itemId: 'item-1',
        title: 'Título corrigível',
      );

      expect(
        controller.editGalleryOperationErrorStreamValue.value,
        contains('Falha de rede'),
      );
      expect(controller.editGalleryFieldErrorsStreamValue.value, isEmpty);
      expect(controller.editErrorMessageStreamValue.value, isNull);

      profilesRepository
        ..updateGalleryItemError = null
        ..gallerySnapshotToReturn = TenantAdminAccountProfileGallerySnapshot(
          groups: profile.galleryGroups,
          capabilities: profile.galleryCapabilities,
        );
      await controller.updateEditGalleryItemTitle(
        groupId: 'group-1',
        itemId: 'item-1',
        title: 'Título confirmado',
      );

      expect(controller.editGalleryOperationErrorStreamValue.value, isNull);
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
        taxonomyTerms: const TenantAdminTaxonomyTerms.empty(),
        avatarUpload: null,
        coverUpload: null,
      );
    },
  );

  test('submitUpdateProfile preserves persisted gallery content', () async {
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
      taxonomyTerms: const TenantAdminTaxonomyTerms.empty(),
      avatarUpload: null,
      coverUpload: null,
    );
  });

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
    'selecting a mirrored contact source hydrates the full profile detail for bubble preview',
    () async {
      final profilesRepository = _FakeAccountProfilesRepository(
        const <TenantAdminAccountProfile>[],
        const <TenantAdminProfileTypeDefinition>[],
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
      profilesRepository.accountProfileFetchOverrides['profile-source'] =
          hydratedSource;
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );

      controller.updateCreateContactMode(
        BellugaContactSourceMode.mirroredAccountProfile,
      );
      controller.updateCreateContactSourceAccountProfileId('profile-source');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(profilesRepository.fetchAccountProfileCalls, 1);
      expect(profilesRepository.lastFetchedProfileId, 'profile-source');
      final selectedSource = controller
          .selectedContactSourceProfilesStreamValue
          .value
          .singleWhere((profile) => profile.id == 'profile-source');
      expect(selectedSource.effectiveContactChannels, hasLength(1));
      expect(
        selectedSource.effectiveContactChannels.single.id,
        'whatsapp-source',
      );
    },
  );

  test(
    'failed create contact-source hydration exposes retry and recovers',
    () async {
      final profilesRepository = _FakeAccountProfilesRepository(
        const <TenantAdminAccountProfile>[],
        const <TenantAdminProfileTypeDefinition>[],
      );
      profilesRepository.accountProfileFetchErrors['profile-source'] =
          StateError('detail unavailable');
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );

      controller.updateCreateContactMode(
        BellugaContactSourceMode.mirroredAccountProfile,
      );
      controller.updateCreateContactSourceAccountProfileId('profile-source');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(
        controller.selectedContactSourceProfilesStreamValue.value,
        isEmpty,
      );
      expect(
        controller.selectedContactSourceHydrationErrorStreamValue.value,
        'Não foi possível carregar o perfil de origem.',
      );

      profilesRepository.accountProfileFetchErrors.remove('profile-source');
      profilesRepository.accountProfileFetchOverrides['profile-source'] =
          tenantAdminAccountProfileFromRaw(
            id: 'profile-source',
            accountId: 'acc-source',
            profileType: 'contact_source',
            displayName: 'Perfil recuperado',
          );
      await controller.retrySelectedContactSourceHydration();

      expect(
        controller.selectedContactSourceProfilesStreamValue.value.single.id,
        'profile-source',
      );
      expect(
        controller.selectedContactSourceHydrationErrorStreamValue.value,
        isNull,
      );
      controller.dispose();
    },
  );

  test(
    'failed edit contact-source hydration exposes retryable error',
    () async {
      final profilesRepository = _FakeAccountProfilesRepository(
        const <TenantAdminAccountProfile>[],
        const <TenantAdminProfileTypeDefinition>[],
      );
      profilesRepository.accountProfileFetchErrors['profile-source'] =
          StateError('detail unavailable');
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );

      controller.updateEditContactMode(
        BellugaContactSourceMode.mirroredAccountProfile,
      );
      controller.updateEditContactSourceAccountProfileId('profile-source');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(
        controller.selectedContactSourceHydrationErrorStreamValue.value,
        'Não foi possível carregar o perfil de origem.',
      );
      controller.dispose();
    },
  );

  test(
    'superseded contact-source failure does not replace current success',
    () async {
      final profilesRepository = _FakeAccountProfilesRepository(
        const <TenantAdminAccountProfile>[],
        const <TenantAdminProfileTypeDefinition>[],
      );
      final stale = Completer<TenantAdminAccountProfile>();
      profilesRepository.accountProfileFetchFutures['profile-stale'] =
          stale.future;
      profilesRepository.accountProfileFetchOverrides['profile-current'] =
          tenantAdminAccountProfileFromRaw(
            id: 'profile-current',
            accountId: 'acc-current',
            profileType: 'contact_source',
            displayName: 'Perfil atual',
          );
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );

      controller.updateCreateContactMode(
        BellugaContactSourceMode.mirroredAccountProfile,
      );
      controller.updateCreateContactSourceAccountProfileId('profile-stale');
      controller.updateCreateContactSourceAccountProfileId('profile-current');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      stale.completeError(StateError('stale failure'));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(
        controller.selectedContactSourceProfilesStreamValue.value.single.id,
        'profile-current',
      );
      expect(
        controller.selectedContactSourceHydrationErrorStreamValue.value,
        isNull,
      );
      controller.dispose();
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
    'submitTaxonomySelectionUpdate resolves profileType and sends bio',
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
      );

      expect(saved, isTrue);
      expect(profilesRepository.lastUpdateProfileType, 'artist');
      expect(profilesRepository.lastUpdateBio, '');
    },
  );

  test(
    'submitTaxonomySelectionUpdate preserves independently loaded gallery state',
    () async {
      final loadedProfile = tenantAdminAccountProfileFromRaw(
        id: 'profile-1',
        accountId: 'acc-1',
        profileType: 'artist',
        displayName: 'Perfil',
        galleryGroups: [_galleryGroup()],
        galleryCapabilities: TenantAdminAccountProfileGalleryCapabilities(
          maxGalleriesValue: TenantAdminCountValue(8),
          maxItemsPerGalleryValue: TenantAdminCountValue(14),
        ),
      );
      final profilesRepository =
          _FakeAccountProfilesRepository(
              [loadedProfile],
              [
                tenantAdminProfileTypeDefinitionFromRaw(
                  type: 'artist',
                  label: 'Artist',
                  allowedTaxonomies: ['music-style'],
                  capabilities: TenantAdminProfileTypeCapabilities(
                    isFavoritable: TenantAdminFlagValue(true),
                    isPoiEnabled: TenantAdminFlagValue(false),
                    hasBio: TenantAdminFlagValue(true),
                    hasTaxonomies: TenantAdminFlagValue(true),
                    hasAvatar: TenantAdminFlagValue(true),
                    hasCover: TenantAdminFlagValue(true),
                    hasEvents: TenantAdminFlagValue(true),
                  ),
                ),
              ],
            )
            ..updateAccountProfileOverride = tenantAdminAccountProfileFromRaw(
              id: 'profile-1',
              accountId: 'acc-1',
              profileType: 'artist',
              displayName: 'Perfil',
            );
      final controller = TenantAdminAccountProfilesController(
        profilesRepository: profilesRepository,
        accountsRepository: _FakeAccountsRepository(),
        taxonomiesRepository: _FakeTaxonomiesRepository(),
        locationSelectionService: TenantAdminLocationSelectionService(),
      );

      await controller.loadEditProfile('profile-1');
      final saved = await controller.submitTaxonomySelectionUpdate(
        accountProfileId: 'profile-1',
        profileType: 'artist',
        taxonomyTerms: const TenantAdminTaxonomyTerms.empty(),
      );

      expect(saved, isTrue);
      expect(
        controller.editStateStreamValue.value.galleryGroups.single.groupId,
        'group-1',
      );
      expect(
        controller.editStateStreamValue.value.galleryCapabilities.maxGalleries,
        8,
      );
      expect(
        controller
            .editStateStreamValue
            .value
            .galleryCapabilities
            .maxItemsPerGallery,
        14,
      );
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

      await controller.loadAccountForEdit('yuri-dias');
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

class _FakeTenantScope implements TenantAdminTenantScopeContract {
  @override
  final StreamValue<String?> selectedTenantDomainStreamValue =
      StreamValue<String?>(defaultValue: null);

  @override
  String? get selectedTenantDomain => selectedTenantDomainStreamValue.value;

  @override
  String get selectedTenantAdminBaseUrl => '';

  @override
  void clearSelectedTenantDomain() =>
      selectedTenantDomainStreamValue.addValue(null);

  @override
  void selectTenantDomain(Object tenantDomain) =>
      selectedTenantDomainStreamValue.addValue(tenantDomain as String);
}

class _DelayedImageIngestionService extends TenantAdminImageIngestionService {
  _DelayedImageIngestionService(this.gate);

  final Completer<TenantAdminMediaUpload?> gate;

  @override
  Future<TenantAdminMediaUpload?> buildUpload(
    XFile? file, {
    required TenantAdminImageSlot slot,
  }) => gate.future;
}

AccountProfileExternalLink _parseExternalLink({
  required String id,
  required AccountProfileExternalLinkType type,
  required String url,
  String? label,
}) => AccountProfileExternalLinkRegistry.validateMutation(
  id: AccountProfileExternalLinkIdValue(id),
  type: type,
  url: AccountProfileExternalLinkUrlValue(url),
  label: label == null ? null : AccountProfileExternalLinkLabelValue(label),
);

TenantAdminAccountProfileGalleryGroup _galleryGroup({
  String groupId = 'group-1',
  String subtitle = 'Ambiente',
  int order = 0,
  bool includeSecondItem = false,
}) {
  return TenantAdminAccountProfileGalleryGroup(
    groupIdValue: TenantAdminNestedProfileGroupTextValue(groupId),
    subtitleValue: TenantAdminNestedProfileGroupTextValue(subtitle),
    orderValue: TenantAdminNestedProfileGroupOrderValue(order),
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
      if (includeSecondItem)
        TenantAdminAccountProfileGalleryItem(
          itemIdValue: TenantAdminNestedProfileGroupTextValue('item-2'),
          descriptionValue: TenantAdminOptionalTextValue(),
          orderValue: TenantAdminNestedProfileGroupOrderValue(1),
          imageUrlValue: TenantAdminOptionalUrlValue()
            ..parse('https://tenant.test/gallery/image-2.png'),
          thumbUrlValue: TenantAdminOptionalUrlValue(),
          cardUrlValue: TenantAdminOptionalUrlValue(),
          modalUrlValue: TenantAdminOptionalUrlValue(),
        ),
    ],
  );
}
