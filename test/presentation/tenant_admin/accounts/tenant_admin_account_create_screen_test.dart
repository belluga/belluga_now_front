import 'package:belluga_contact_channels/belluga_contact_channels.dart';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_form_validation/belluga_form_validation.dart'
    show FormValidationFailure;
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_meta.dart';
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
import 'package:belluga_now/domain/services/tenant_admin_external_image_proxy_contract.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_location_selection_service.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/controllers/tenant_admin_account_create_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/models/tenant_admin_account_create_validation_config.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/screens/tenant_admin_account_create_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class _FakeAccountsRepository
    with TenantAdminAccountsRepositoryPaginationMixin
    implements TenantAdminAccountsRepositoryContract {
  Object? createAccountError;
  TenantAdminMediaUpload? lastOnboardingAvatarUpload;
  TenantAdminMediaUpload? lastOnboardingCoverUpload;
  List<TenantAdminNestedProfileGroup> lastOnboardingNestedGroups = const [];
  int createOnboardingCallCount = 0;

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
    return tenantAdminAccountFromRaw(
      id: 'acc-1',
      name: name.value,
      slug: 'acc-1',
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
    List<TenantAdminNestedProfileGroup> nestedProfileGroups =
        const <TenantAdminNestedProfileGroup>[],
    BellugaContactSourceMode contactMode = BellugaContactSourceMode.own,
    TenantAdminAccountProfilesRepoString? contactSourceAccountProfileId,
    List<BellugaContactChannelDraft> contactChannelDrafts =
        const <BellugaContactChannelDraft>[],
    BellugaContactBubbleSelectionMutation bubbleSelection =
        const BellugaContactBubbleSelectionMutation.omit(),
  }) async {
    createOnboardingCallCount += 1;
    lastOnboardingAvatarUpload = avatarUpload;
    lastOnboardingCoverUpload = coverUpload;
    lastOnboardingNestedGroups = List<TenantAdminNestedProfileGroup>.from(
      nestedProfileGroups,
    );
    final error = createAccountError;
    if (error != null) {
      throw error;
    }
    final account = tenantAdminAccountFromRaw(
      id: 'acc-1',
      name: name.value,
      slug: 'acc-1',
      document: tenantAdminDocumentFromRaw(type: 'cpf', number: '000'),
      ownershipState: ownershipState,
    );
    final profile = tenantAdminAccountProfileFromRaw(
      id: 'profile-1',
      accountId: account.id,
      profileType: profileType.value,
      displayName: name.value,
      location: location,
      taxonomyTerms: taxonomyTerms,
      bio: bio?.value,
      content: content?.value,
    );
    return TenantAdminAccountOnboardingResult(
      account: account,
      accountProfile: profile,
    );
  }

  @override
  Future<void> deleteAccount(
    TenantAdminAccountsRepositoryContractPrimString accountSlug,
  ) async {}

  @override
  Future<TenantAdminAccount> fetchAccountBySlug(
    TenantAdminAccountsRepositoryContractPrimString accountSlug,
  ) async {
    return tenantAdminAccountFromRaw(
      id: 'acc-1',
      name: 'Conta',
      slug: accountSlug.value,
      document: tenantAdminDocumentFromRaw(type: 'cpf', number: '000'),
      ownershipState: TenantAdminOwnershipState.tenantOwned,
    );
  }

  @override
  Future<List<TenantAdminAccount>> fetchAccounts() async {
    return [];
  }

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
  Future<void> forceDeleteAccount(
    TenantAdminAccountsRepositoryContractPrimString accountSlug,
  ) async {}

  @override
  Future<TenantAdminAccount> restoreAccount(
    TenantAdminAccountsRepositoryContractPrimString accountSlug,
  ) async {
    return tenantAdminAccountFromRaw(
      id: 'acc-1',
      name: 'Conta',
      slug: accountSlug.value,
      document: tenantAdminDocumentFromRaw(type: 'cpf', number: '000'),
      ownershipState: TenantAdminOwnershipState.tenantOwned,
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
    return tenantAdminAccountFromRaw(
      id: 'acc-1',
      name: name?.value ?? 'Conta',
      slug: slug?.value ?? accountSlug.value,
      document:
          document ?? tenantAdminDocumentFromRaw(type: 'cpf', number: '000'),
      ownershipState: TenantAdminOwnershipState.tenantOwned,
      publicationStatus: publication?.status.value,
    );
  }
}

class _FakeAccountProfilesRepository
    extends TenantAdminAccountProfilesRepositoryContract
    with TenantAdminProfileTypesPaginationMixin {
  _FakeAccountProfilesRepository({
    List<TenantAdminProfileTypeDefinition>? profileTypes,
  }) : _profileTypes =
           profileTypes ??
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
                 hasAvatar: TenantAdminFlagValue(true),
                 hasCover: TenantAdminFlagValue(true),
                 hasEvents: TenantAdminFlagValue(false),
               ),
             ),
           ];

  List<TenantAdminProfileTypeDefinition> _profileTypes;
  List<TenantAdminAccountProfile> profilesToReturn = const [];
  String? lastFetchPageProfileType;
  String? lastFetchPageSearch;
  String? lastCreateBio;
  List<TenantAdminTaxonomyTerm> lastCreateTaxonomyTerms = const [];
  Object? createProfileError;

  @override
  Future<List<TenantAdminProfileTypeDefinition>> fetchProfileTypes() async {
    return _profileTypes;
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
    final error = createProfileError;
    if (error != null) {
      throw error;
    }
    lastCreateBio = bio?.value;
    lastCreateTaxonomyTerms = List<TenantAdminTaxonomyTerm>.from(
      taxonomyTerms.items,
    );
    return tenantAdminAccountProfileFromRaw(
      id: 'profile-1',
      accountId: accountId.value,
      profileType: profileType.value,
      displayName: displayName.value,
      location: location,
      taxonomyTerms: taxonomyTerms,
    );
  }

  @override
  Future<void> deleteAccountProfile(
    TenantAdminAccountProfilesRepoString accountProfileId,
  ) async {}

  @override
  Future<void> forceDeleteAccountProfile(
    TenantAdminAccountProfilesRepoString accountProfileId,
  ) async {}

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
  Future<List<TenantAdminAccountProfile>> fetchAccountProfiles({
    TenantAdminAccountProfilesRepoString? accountId,
    TenantAdminAccountProfilesRepoBool? queryableOnly,
    TenantAdminAccountProfilesRepoString? excludeAccountProfileId,
  }) async {
    return _filterProfiles(
      excludeAccountProfileId: excludeAccountProfileId?.value,
    );
  }

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
    lastFetchPageProfileType = profileType?.value;
    lastFetchPageSearch = search?.value;
    final filtered = _filterProfiles(
      search: search?.value,
      profileType: profileType?.value,
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
  Future<TenantAdminProfileTypeDefinition> createProfileType({
    required TenantAdminAccountProfilesRepoString type,
    required TenantAdminAccountProfilesRepoString label,
    TenantAdminAccountProfilesRepoString? pluralLabel,
    List<TenantAdminAccountProfilesRepoString> allowedTaxonomies = const [],
    required TenantAdminProfileTypeCapabilities capabilities,
  }) async {
    return tenantAdminProfileTypeDefinitionFromRaw(
      type: type.value,
      label: label.value,
      allowedTaxonomies: allowedTaxonomies
          .map((entry) => entry.value)
          .toList(growable: false),
      capabilities: capabilities,
    );
  }

  @override
  Future<void> deleteProfileType(
    TenantAdminAccountProfilesRepoString type,
  ) async {}

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
  Future<TenantAdminProfileTypeDefinition> updateProfileType({
    required TenantAdminAccountProfilesRepoString type,
    TenantAdminAccountProfilesRepoString? newType,
    TenantAdminAccountProfilesRepoString? label,
    TenantAdminAccountProfilesRepoString? pluralLabel,
    List<TenantAdminAccountProfilesRepoString>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
  }) async {
    return tenantAdminProfileTypeDefinitionFromRaw(
      type: type.value,
      label: label?.value ?? 'Venue',
      allowedTaxonomies:
          allowedTaxonomies
              ?.map((entry) => entry.value)
              .toList(growable: false) ??
          [],
      capabilities:
          capabilities ??
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
    return tenantAdminAccountProfileFromRaw(
      id: accountProfileId.value,
      accountId: 'acc-1',
      profileType: profileType?.value ?? 'venue',
      displayName: displayName?.value ?? 'Perfil',
      location: location,
      taxonomyTerms: taxonomyTerms ?? const TenantAdminTaxonomyTerms.empty(),
    );
  }

  List<TenantAdminAccountProfile> _filterProfiles({
    String? search,
    String? profileType,
    String? excludeAccountProfileId,
  }) {
    final normalizedSearch = search?.trim().toLowerCase() ?? '';
    final normalizedProfileType = profileType?.trim().toLowerCase() ?? '';
    return profilesToReturn
        .where((profile) {
          if (excludeAccountProfileId != null &&
              excludeAccountProfileId.isNotEmpty &&
              profile.id == excludeAccountProfileId) {
            return false;
          }
          if (normalizedProfileType.isNotEmpty &&
              profile.profileType.toLowerCase() != normalizedProfileType) {
            return false;
          }
          if (normalizedSearch.isEmpty) {
            return true;
          }
          return profile.displayName.toLowerCase().startsWith(normalizedSearch);
        })
        .toList(growable: false);
  }
}

class _FakeTaxonomiesRepository
    with TenantAdminTaxonomiesPaginationMixin
    implements TenantAdminTaxonomiesRepositoryContract {
  _FakeTaxonomiesRepository({
    List<TenantAdminTaxonomyDefinition>? taxonomies,
    Map<String, List<TenantAdminTaxonomyTermDefinition>>? termsByTaxonomyId,
  }) : _taxonomies = taxonomies ?? [],
       _termsByTaxonomyId = termsByTaxonomyId ?? {};

  List<TenantAdminTaxonomyDefinition> _taxonomies;
  Map<String, List<TenantAdminTaxonomyTermDefinition>> _termsByTaxonomyId;

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
  Future<void> deleteTaxonomy(TenantAdminTaxRepoString taxonomyId) async {}

  @override
  Future<void> deleteTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString termId,
  }) async {}

  @override
  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomies() async =>
      List<TenantAdminTaxonomyDefinition>.from(_taxonomies);

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyDefinition>>
  fetchTaxonomiesPage({
    required TenantAdminTaxRepoInt page,
    required TenantAdminTaxRepoInt pageSize,
  }) async {
    if (page.value <= 0 || pageSize.value <= 0) {
      return tenantAdminPagedResultFromRaw(
        items: <TenantAdminTaxonomyDefinition>[],
        hasMore: false,
      );
    }
    final start = (page.value - 1) * pageSize.value;
    if (start >= _taxonomies.length) {
      return tenantAdminPagedResultFromRaw(
        items: <TenantAdminTaxonomyDefinition>[],
        hasMore: false,
      );
    }
    final end = start + pageSize.value < _taxonomies.length
        ? start + pageSize.value
        : _taxonomies.length;
    return tenantAdminPagedResultFromRaw(
      items: _taxonomies.sublist(start, end),
      hasMore: end < _taxonomies.length,
    );
  }

  @override
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required TenantAdminTaxRepoString taxonomyId,
  }) async => List<TenantAdminTaxonomyTermDefinition>.from(
    _termsByTaxonomyId[taxonomyId.value] ?? [],
  );

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyTermDefinition>>
  fetchTermsPage({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoInt page,
    required TenantAdminTaxRepoInt pageSize,
  }) async {
    final terms = _termsByTaxonomyId[taxonomyId.value] ?? [];
    if (page.value <= 0 || pageSize.value <= 0) {
      return tenantAdminPagedResultFromRaw(
        items: <TenantAdminTaxonomyTermDefinition>[],
        hasMore: false,
      );
    }
    final start = (page.value - 1) * pageSize.value;
    if (start >= terms.length) {
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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  final fallbackTempDir = Directory.systemTemp.createTempSync(
    'tenant-admin-account-create-test',
  );

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
          if (call.method == 'getTemporaryDirectory') {
            return fallbackTempDir.path;
          }
          return null;
        });
  });

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<TenantAdminAccountsRepositoryContract>(
      _FakeAccountsRepository(),
    );
    GetIt.I.registerSingleton<TenantAdminAccountProfilesRepositoryContract>(
      _FakeAccountProfilesRepository(),
    );
    GetIt.I.registerSingleton<TenantAdminTaxonomiesRepositoryContract>(
      _FakeTaxonomiesRepository(),
    );
    final TenantAdminLocationSelectionContract locationSelectionService =
        TenantAdminLocationSelectionService();
    GetIt.I.registerSingleton<TenantAdminLocationSelectionContract>(
      locationSelectionService,
    );
    GetIt.I.registerSingleton<TenantAdminExternalImageProxyContract>(
      _FakeExternalImageProxy(),
    );
    GetIt.I.registerSingleton<TenantAdminAccountCreateController>(
      TenantAdminAccountCreateController(
        locationSelectionService: locationSelectionService,
      ),
    );
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    if (fallbackTempDir.existsSync()) {
      fallbackTempDir.deleteSync(recursive: true);
    }
  });

  testWidgets(
    'requires location and shows map pick for POI-enabled profile type',
    (tester) async {
      await _pumpWithAutoRoute(
        tester,
        Scaffold(body: TenantAdminAccountCreateScreen()),
      );

      final profileTypeDropdown = find.byType(DropdownButtonFormField<String>);
      await tester.ensureVisible(profileTypeDropdown.last);
      await tester.tap(profileTypeDropdown.last, warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Venue').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome'),
        'Conta Teste',
      );

      expect(
        find.byKey(const ValueKey('tenant_admin_account_create_map_pick')),
        findsOneWidget,
      );

      final saveButton = find.byKey(
        const ValueKey('tenant_admin_account_create_save'),
      );
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(
        find.text('Localizacao e obrigatoria para este perfil.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('hides media authoring in reduced account create flow', (
    tester,
  ) async {
    await _pumpWithAutoRoute(
      tester,
      Scaffold(body: TenantAdminAccountCreateScreen()),
    );

    expect(
      find.byKey(const ValueKey('tenant_admin_account_create_avatar_pick')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('tenant_admin_account_create_cover_pick')),
      findsNothing,
    );

    final profileTypeDropdown = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(profileTypeDropdown.last);
    await tester.tap(profileTypeDropdown.last, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Venue').last);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('tenant_admin_account_create_avatar_pick')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('tenant_admin_account_create_cover_pick')),
      findsNothing,
    );
  });

  testWidgets('keeps media busy state hidden in reduced account create flow', (
    tester,
  ) async {
    await _pumpWithAutoRoute(
      tester,
      const Scaffold(body: TenantAdminAccountCreateScreen()),
    );

    final profileTypeDropdown = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(profileTypeDropdown.last);
    await tester.tap(profileTypeDropdown.last, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Venue').last);
    await tester.pumpAndSettle();

    final controller = GetIt.I.get<TenantAdminAccountCreateController>();
    controller.createSubmittingStreamValue.addValue(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(
      find.byKey(const ValueKey('tenant_admin_account_create_avatar_pick')),
      findsNothing,
    );
  });

  testWidgets(
    'hides bio and taxonomy authoring in reduced account create flow',
    (tester) async {
      final profilesRepository =
          GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
              as _FakeAccountProfilesRepository;
      profilesRepository._profileTypes = [
        tenantAdminProfileTypeDefinitionFromRaw(
          type: 'complete',
          label: 'Completo',
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
      ];
      final taxonomiesRepository =
          GetIt.I.get<TenantAdminTaxonomiesRepositoryContract>()
              as _FakeTaxonomiesRepository;
      taxonomiesRepository
        .._taxonomies = [
          tenantAdminTaxonomyDefinitionFromRaw(
            id: 'tax-1',
            slug: 'genre',
            name: 'Genero',
            appliesTo: ['account_profile'],
            icon: null,
            color: null,
          ),
        ]
        .._termsByTaxonomyId = {
          'tax-1': [
            tenantAdminTaxonomyTermDefinitionFromRaw(
              id: 'term-1',
              taxonomyId: 'tax-1',
              slug: 'urbana',
              name: 'Urbana',
            ),
          ],
        };

      await _pumpWithAutoRoute(
        tester,
        const Scaffold(body: TenantAdminAccountCreateScreen()),
      );

      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Completo').last);
      await tester.pumpAndSettle();

      expect(find.text('Bio'), findsNothing);
      expect(find.text('Taxonomias'), findsNothing);
      expect(find.text('Urbana'), findsNothing);
    },
  );

  testWidgets('renders backend global validation inline without snackbar', (
    tester,
  ) async {
    final accountsRepository =
        GetIt.I.get<TenantAdminAccountsRepositoryContract>()
            as _FakeAccountsRepository;
    final profilesRepository =
        GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
            as _FakeAccountProfilesRepository;
    profilesRepository._profileTypes = [
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
    ];
    accountsRepository.createAccountError = FormValidationFailure(
      statusCode: 422,
      message: 'The given data was invalid.',
      fieldErrors: <String, List<String>>{
        'account_profile': <String>['Conta invalida.', 'Tente novamente.'],
      },
    );

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(body: TenantAdminAccountCreateScreen()),
    );

    await _selectProfileType(tester, 'Venue');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome'),
      'Conta teste',
    );
    await tester.tap(
      find.byKey(const ValueKey('tenant_admin_account_create_save')),
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.textContaining('Conta invalida.'), findsOneWidget);
    expect(find.text('Ver todos'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets(
    'renders backend profile_type validation inline without snackbar',
    (tester) async {
      final accountsRepository =
          GetIt.I.get<TenantAdminAccountsRepositoryContract>()
              as _FakeAccountsRepository;
      final profilesRepository =
          GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
              as _FakeAccountProfilesRepository;
      profilesRepository._profileTypes = [
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
      ];
      accountsRepository.createAccountError = FormValidationFailure(
        statusCode: 422,
        message: 'The given data was invalid.',
        fieldErrors: <String, List<String>>{
          'profile_type': <String>['Tipo de perfil invalido.'],
        },
      );

      await _pumpWithAutoRoute(
        tester,
        const Scaffold(body: TenantAdminAccountCreateScreen()),
      );

      await _selectProfileType(tester, 'Venue');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome'),
        'Conta teste',
      );
      await tester.tap(
        find.byKey(const ValueKey('tenant_admin_account_create_save')),
        warnIfMissed: false,
      );
      await tester.pump();
      await tester.pumpAndSettle();

      final controller = GetIt.I.get<TenantAdminAccountCreateController>();
      expect(find.text('Tipo de perfil invalido.'), findsOneWidget);
      expect(
        controller.createValidationStreamValue.value.errorForField(
          TenantAdminAccountCreateValidationTargets.profileType,
        ),
        'Tipo de perfil invalido.',
      );
      expect(find.byType(SnackBar), findsNothing);
    },
  );

  testWidgets('shows operational submit failures in snackbar', (tester) async {
    final accountsRepository =
        GetIt.I.get<TenantAdminAccountsRepositoryContract>()
            as _FakeAccountsRepository;
    final profilesRepository =
        GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
            as _FakeAccountProfilesRepository;
    profilesRepository._profileTypes = [
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
    ];
    accountsRepository.createAccountError = Exception('backend exploded');

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(body: TenantAdminAccountCreateScreen()),
    );

    await _selectProfileType(tester, 'Venue');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome'),
      'Conta teste',
    );
    await tester.tap(
      find.byKey(const ValueKey('tenant_admin_account_create_save')),
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('backend exploded'), findsOneWidget);
  });

  testWidgets('replaces create route with account profile edit on success', (
    tester,
  ) async {
    final profilesRepository =
        GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
            as _FakeAccountProfilesRepository;
    profilesRepository._profileTypes = [
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
    ];

    await _pumpWithAutoRoute(
      tester,
      const Scaffold(body: TenantAdminAccountCreateScreen()),
    );

    await _selectProfileType(tester, 'Venue');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome'),
      'Conta criada',
    );
    await tester.tap(
      find.byKey(const ValueKey('tenant_admin_account_create_save')),
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(TenantAdminAccountCreateScreen), findsNothing);
    expect(find.text('Edit: acc-1/profile-1'), findsOneWidget);
  });

  testWidgets('hides nested group authoring in reduced account create flow', (
    tester,
  ) async {
    final profilesRepository =
        GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
            as _FakeAccountProfilesRepository;
    profilesRepository._profileTypes = [
      tenantAdminProfileTypeDefinitionFromRaw(
        type: 'venue',
        label: 'Venue',
        allowedTaxonomies: [],
        capabilities: TenantAdminProfileTypeCapabilities(
          isQueryable: TenantAdminFlagValue(true),
          isFavoritable: TenantAdminFlagValue(true),
          isPoiEnabled: TenantAdminFlagValue(false),
          hasBio: TenantAdminFlagValue(false),
          hasContent: TenantAdminFlagValue(false),
          hasTaxonomies: TenantAdminFlagValue(false),
          hasAvatar: TenantAdminFlagValue(false),
          hasCover: TenantAdminFlagValue(false),
          hasEvents: TenantAdminFlagValue(false),
          hasNestedProfileGroups: TenantAdminFlagValue(true),
        ),
      ),
    ];
    await _pumpWithAutoRoute(
      tester,
      const Scaffold(body: TenantAdminAccountCreateScreen()),
    );

    await _selectProfileType(tester, 'Venue');

    expect(find.text('Abas de contas vinculadas'), findsNothing);
    expect(
      find.byKey(const Key('tenantAdminAccountCreateAddNestedGroupButton')),
      findsNothing,
    );
  });

  testWidgets('submits reduced onboarding without nested group metadata', (
    tester,
  ) async {
    final accountsRepository =
        GetIt.I.get<TenantAdminAccountsRepositoryContract>()
            as _FakeAccountsRepository;
    final profilesRepository =
        GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
            as _FakeAccountProfilesRepository;
    profilesRepository._profileTypes = [
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
          hasNestedProfileGroups: TenantAdminFlagValue(true),
        ),
      ),
    ];
    await _pumpWithAutoRoute(
      tester,
      const Scaffold(body: TenantAdminAccountCreateScreen()),
    );

    await _selectProfileType(tester, 'Venue');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome'),
      'Conta criada',
    );
    await tester.tap(
      find.byKey(const ValueKey('tenant_admin_account_create_save')),
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(accountsRepository.lastOnboardingNestedGroups, isEmpty);
  });
}

Future<void> _pumpWithAutoRoute(WidgetTester tester, Widget child) async {
  final router = RootStackRouter.build(
    routes: [
      NamedRouteDef(
        name: TenantAdminAccountCreateRoute.name,
        path: '/',
        meta: canonicalRouteMeta(
          family: CanonicalRouteFamily.tenantAdminAccountsInternal,
          chromeMode: RouteChromeMode.fullscreen,
        ),
        builder: (context, routeData) => child,
      ),
      NamedRouteDef(
        name: TenantAdminAccountDetailRoute.name,
        path: '/admin/accounts/:accountSlug',
        meta: canonicalRouteMeta(
          family: CanonicalRouteFamily.tenantAdminAccountsInternal,
          chromeMode: RouteChromeMode.fullscreen,
        ),
        builder: (_, data) => Scaffold(
          body: Text('Detail: ${data.params.getString('accountSlug')}'),
        ),
      ),
      NamedRouteDef(
        name: TenantAdminAccountProfileEditRoute.name,
        path: '/admin/accounts/:accountSlug/profiles/:accountProfileId/edit',
        meta: canonicalRouteMeta(
          family: CanonicalRouteFamily.tenantAdminAccountsInternal,
          chromeMode: RouteChromeMode.fullscreen,
        ),
        builder: (_, data) => Scaffold(
          body: Text(
            'Edit: ${data.params.getString('accountSlug')}/${data.params.getString('accountProfileId')}',
          ),
        ),
      ),
    ],
  );

  await tester.pumpWidget(
    MaterialApp.router(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      routeInformationParser: router.defaultRouteParser(),
      routerDelegate: router.delegate(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _selectProfileType(WidgetTester tester, String label) async {
  final profileTypeDropdown = find.byType(DropdownButtonFormField<String>);
  await tester.ensureVisible(profileTypeDropdown.last);
  await tester.tap(profileTypeDropdown.last, warnIfMissed: false);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

class _FakeExternalImageProxy implements TenantAdminExternalImageProxyContract {
  @override
  Future<Uint8List> fetchExternalImageBytes({required Object imageUrl}) async {
    throw UnimplementedError();
  }
}
