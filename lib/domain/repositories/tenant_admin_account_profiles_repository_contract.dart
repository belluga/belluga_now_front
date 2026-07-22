import 'dart:math' as math;

import 'package:belluga_contact_channels/belluga_contact_channels.dart';
import 'package:belluga_now/domain/repositories/value_objects/tenant_admin_account_profiles_repository_contract_values.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_candidate.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_gallery_update.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_profile_group.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_group_member_mutation_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_group_member_page.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_taxonomy_terms_value.dart';
import 'package:stream_value/core/stream_value.dart';

export 'package:belluga_now/domain/repositories/value_objects/tenant_admin_account_profiles_repository_contract_values.dart';
export 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_gallery_update.dart';
export 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_profile_group.dart';
export 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_taxonomy_terms_value.dart';

typedef TenantAdminAccountProfilesRepoString =
    TenantAdminAccountProfilesRepositoryContractTextValue;
typedef TenantAdminAccountProfilesRepoInt =
    TenantAdminAccountProfilesRepositoryContractIntValue;
typedef TenantAdminAccountProfilesRepoBool =
    TenantAdminAccountProfilesRepositoryContractBoolValue;

abstract class TenantAdminAccountProfilesRepositoryContract {
  static final Expando<_TenantAdminProfileTypesPaginationState>
  _profileTypesStateByRepository =
      Expando<_TenantAdminProfileTypesPaginationState>();
  static final Expando<_TenantAdminContactSourceCandidatesPaginationState>
  _contactSourceCandidatesStateByRepository =
      Expando<_TenantAdminContactSourceCandidatesPaginationState>();

  _TenantAdminProfileTypesPaginationState get _profileTypesPaginationState =>
      _profileTypesStateByRepository[this] ??=
          _TenantAdminProfileTypesPaginationState();
  _TenantAdminContactSourceCandidatesPaginationState
  get _contactSourceCandidatesPaginationState =>
      _contactSourceCandidatesStateByRepository[this] ??=
          _TenantAdminContactSourceCandidatesPaginationState();

  Future<List<TenantAdminAccountProfile>> fetchAccountProfiles({
    TenantAdminAccountProfilesRepoString? accountId,
    TenantAdminAccountProfilesRepoBool? queryableOnly,
    TenantAdminAccountProfilesRepoString? excludeAccountProfileId,
  });
  Future<TenantAdminPagedResult<TenantAdminAccountProfile>>
  fetchAccountProfilesPage({
    required TenantAdminAccountProfilesRepoInt page,
    required TenantAdminAccountProfilesRepoInt pageSize,
    TenantAdminAccountProfilesRepoString? search,
    TenantAdminAccountProfilesRepoString? accountId,
    TenantAdminAccountProfilesRepoBool? queryableOnly,
    TenantAdminAccountProfilesRepoString? excludeAccountProfileId,
  }) async {
    throw UnimplementedError(
      'fetchAccountProfilesPage must be implemented by paginated '
      'tenant-admin account-profile repositories.',
    );
  }

  Future<TenantAdminAccountProfileCandidatePage>
  fetchAccountProfileCandidatesPage({
    required TenantAdminAccountProfileCandidateScope scope,
    required TenantAdminAccountProfilesRepoString search,
    required TenantAdminAccountProfilesRepoInt page,
    required TenantAdminAccountProfilesRepoInt pageSize,
    TenantAdminAccountProfilesRepoString? excludeAccountProfileId,
  }) async {
    throw UnimplementedError(
      'fetchAccountProfileCandidatesPage must be implemented by tenant-admin '
      'account-profile repositories.',
    );
  }

  Future<TenantAdminPagedResult<TenantAdminAccountProfile>>
  fetchContactSourceCandidatesPage({
    required TenantAdminAccountProfilesRepoInt page,
    required TenantAdminAccountProfilesRepoInt pageSize,
    TenantAdminAccountProfilesRepoString? excludeAccountProfileId,
  }) async {
    throw UnimplementedError(
      'fetchContactSourceCandidatesPage must be implemented by tenant-admin '
      'account-profile repositories.',
    );
  }

  Future<TenantAdminPagedResult<TenantAdminAccountProfile>>
  loadContactSourceCandidates({
    TenantAdminAccountProfilesRepoString? excludeAccountProfileId,
    TenantAdminAccountProfilesRepoInt? pageSize,
  }) async {
    final effectivePageSize =
        pageSize ?? tenantAdminAccountProfilesRepoInt(50, defaultValue: 50);
    await _waitForContactSourceCandidatesFetch();
    _resetContactSourceCandidatesPagination(
      excludeAccountProfileId: excludeAccountProfileId,
      pageSize: effectivePageSize,
    );
    return _fetchContactSourceCandidatesPage(
      page: tenantAdminAccountProfilesRepoInt(1, defaultValue: 1),
      pageSize: effectivePageSize,
      excludeAccountProfileId: excludeAccountProfileId,
    );
  }

  Future<TenantAdminPagedResult<TenantAdminAccountProfile>?>
  loadNextContactSourceCandidatesPage() async {
    if (_contactSourceCandidatesPaginationState.isFetchingPage.value ||
        !_contactSourceCandidatesPaginationState.hasMore.value) {
      return null;
    }

    final nextPage = tenantAdminAccountProfilesRepoInt(
      _contactSourceCandidatesPaginationState.currentPage.value + 1,
      defaultValue: 1,
    );
    return _fetchContactSourceCandidatesPage(
      page: nextPage,
      pageSize: _contactSourceCandidatesPaginationState.pageSize,
      excludeAccountProfileId:
          _contactSourceCandidatesPaginationState.excludeAccountProfileId,
    );
  }

  void resetContactSourceCandidatesState() {
    _resetContactSourceCandidatesPagination();
  }

  Future<TenantAdminAccountProfile> fetchAccountProfile(
    TenantAdminAccountProfilesRepoString accountProfileId,
  );
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
  });
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
  });
  Future<TenantAdminAccountProfile> updateAccountProfileGallery({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    List<TenantAdminAccountProfileGalleryUpdateGroup> galleryGroups =
        const <TenantAdminAccountProfileGalleryUpdateGroup>[],
  }) async {
    return fetchAccountProfile(accountProfileId);
  }

  Future<TenantAdminNestedGroupMemberPage> fetchNestedGroupMembersPage({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    required TenantAdminAccountProfilesRepoString groupId,
    TenantAdminAccountProfilesRepoInt? perPage,
    TenantAdminAccountProfilesRepoString? cursor,
  }) async {
    throw UnimplementedError(
      'fetchNestedGroupMembersPage must be implemented by tenant-admin '
      'account-profile repositories.',
    );
  }

  Future<TenantAdminNestedGroupMemberPage> fetchAllNestedGroupMembers({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    required TenantAdminAccountProfilesRepoString groupId,
  }) async {
    throw UnimplementedError(
      'fetchAllNestedGroupMembers must be implemented by tenant-admin '
      'account-profile repositories.',
    );
  }

  Future<TenantAdminNestedGroupMemberMutationResult> patchNestedGroupMembers({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    required TenantAdminAccountProfilesRepoString groupId,
    required TenantAdminAccountProfilesRepoInt aggregateRevision,
    List<TenantAdminAccountProfilesRepoString> addIds = const [],
    List<TenantAdminAccountProfilesRepoString> removeIds = const [],
  }) async {
    throw UnimplementedError(
      'patchNestedGroupMembers must be implemented by tenant-admin '
      'account-profile repositories.',
    );
  }

  Future<void> deleteAccountProfile(
    TenantAdminAccountProfilesRepoString accountProfileId,
  );
  Future<TenantAdminAccountProfile> restoreAccountProfile(
    TenantAdminAccountProfilesRepoString accountProfileId,
  );
  Future<void> forceDeleteAccountProfile(
    TenantAdminAccountProfilesRepoString accountProfileId,
  );
  StreamValue<List<TenantAdminProfileTypeDefinition>?>
  get profileTypesStreamValue =>
      _profileTypesPaginationState.profileTypesStreamValue;

  StreamValue<TenantAdminAccountProfilesRepoBool>
  get hasMoreProfileTypesStreamValue =>
      _profileTypesPaginationState.hasMoreProfileTypesStreamValue;

  StreamValue<TenantAdminAccountProfilesRepoBool>
  get isProfileTypesPageLoadingStreamValue =>
      _profileTypesPaginationState.isProfileTypesPageLoadingStreamValue;

  StreamValue<TenantAdminAccountProfilesRepoString?>
  get profileTypesErrorStreamValue =>
      _profileTypesPaginationState.profileTypesErrorStreamValue;

  Future<void> loadProfileTypes({
    TenantAdminAccountProfilesRepoInt? pageSize,
  }) async {
    final effectivePageSize =
        pageSize ?? tenantAdminAccountProfilesRepoInt(20, defaultValue: 20);
    await _waitForProfileTypesFetch();
    _resetProfileTypesPagination();
    profileTypesStreamValue.addValue(null);
    await _fetchProfileTypesPage(
      page: tenantAdminAccountProfilesRepoInt(1, defaultValue: 1),
      pageSize: effectivePageSize,
    );
  }

  Future<void> loadNextProfileTypesPage({
    TenantAdminAccountProfilesRepoInt? pageSize,
  }) async {
    final effectivePageSize =
        pageSize ?? tenantAdminAccountProfilesRepoInt(20, defaultValue: 20);
    if (_profileTypesPaginationState.isFetchingProfileTypesPage.value ||
        !_profileTypesPaginationState.hasMoreProfileTypes.value) {
      return;
    }
    await _fetchProfileTypesPage(
      page: tenantAdminAccountProfilesRepoInt(
        _profileTypesPaginationState.currentProfileTypesPage.value + 1,
        defaultValue: 1,
      ),
      pageSize: effectivePageSize,
    );
  }

  Future<void> loadAllProfileTypes({
    TenantAdminAccountProfilesRepoInt? pageSize,
  }) async {
    final effectivePageSize =
        pageSize ?? tenantAdminAccountProfilesRepoInt(50, defaultValue: 50);
    await loadProfileTypes(pageSize: effectivePageSize);
    var safetyCounter = 0;
    while (hasMoreProfileTypesStreamValue.value.value && safetyCounter < 200) {
      safetyCounter += 1;
      await loadNextProfileTypesPage(pageSize: effectivePageSize);
    }
  }

  void resetProfileTypesState() {
    _resetProfileTypesPagination();
    profileTypesStreamValue.addValue(null);
    profileTypesErrorStreamValue.addValue(null);
  }

  Future<List<TenantAdminProfileTypeDefinition>> fetchProfileTypes();
  Future<TenantAdminProfileTypeDefinition> fetchProfileType(
    TenantAdminAccountProfilesRepoString profileType,
  );
  Future<TenantAdminPagedResult<TenantAdminProfileTypeDefinition>>
  fetchProfileTypesPage({
    required TenantAdminAccountProfilesRepoInt page,
    required TenantAdminAccountProfilesRepoInt pageSize,
  }) async {
    final profileTypes = await fetchProfileTypes();
    if (page.value <= 0 || pageSize.value <= 0) {
      return tenantAdminPagedResultFromRaw(
        items: <TenantAdminProfileTypeDefinition>[],
        hasMore: false,
      );
    }
    final startIndex = (page.value - 1) * pageSize.value;
    if (startIndex >= profileTypes.length) {
      return tenantAdminPagedResultFromRaw(
        items: <TenantAdminProfileTypeDefinition>[],
        hasMore: false,
      );
    }
    final endIndex = math.min(startIndex + pageSize.value, profileTypes.length);
    return tenantAdminPagedResultFromRaw(
      items: profileTypes.sublist(startIndex, endIndex),
      hasMore: endIndex < profileTypes.length,
    );
  }

  Future<TenantAdminProfileTypeDefinition> createProfileType({
    required TenantAdminAccountProfilesRepoString type,
    required TenantAdminAccountProfilesRepoString label,
    TenantAdminAccountProfilesRepoString? pluralLabel,
    List<TenantAdminAccountProfilesRepoString> allowedTaxonomies,
    required TenantAdminProfileTypeCapabilities capabilities,
  });
  Future<TenantAdminProfileTypeDefinition> createProfileTypeWithVisual({
    required TenantAdminAccountProfilesRepoString type,
    required TenantAdminAccountProfilesRepoString label,
    TenantAdminAccountProfilesRepoString? pluralLabel,
    List<TenantAdminAccountProfilesRepoString> allowedTaxonomies = const [],
    required TenantAdminProfileTypeCapabilities capabilities,
    TenantAdminPoiVisual? visual,
    TenantAdminMediaUpload? typeAssetUpload,
  }) async {
    return createProfileType(
      type: type,
      label: label,
      pluralLabel: pluralLabel,
      allowedTaxonomies: allowedTaxonomies,
      capabilities: capabilities,
    );
  }

  Future<TenantAdminProfileTypeDefinition> updateProfileType({
    required TenantAdminAccountProfilesRepoString type,
    TenantAdminAccountProfilesRepoString? newType,
    TenantAdminAccountProfilesRepoString? label,
    TenantAdminAccountProfilesRepoString? pluralLabel,
    List<TenantAdminAccountProfilesRepoString>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
  });
  Future<TenantAdminProfileTypeDefinition> updateProfileTypeWithVisual({
    required TenantAdminAccountProfilesRepoString type,
    TenantAdminAccountProfilesRepoString? newType,
    TenantAdminAccountProfilesRepoString? label,
    TenantAdminAccountProfilesRepoString? pluralLabel,
    List<TenantAdminAccountProfilesRepoString>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
    TenantAdminPoiVisual? visual,
    TenantAdminMediaUpload? typeAssetUpload,
    TenantAdminAccountProfilesRepoBool? removeTypeAsset,
  }) async {
    return updateProfileType(
      type: type,
      newType: newType,
      label: label,
      pluralLabel: pluralLabel,
      allowedTaxonomies: allowedTaxonomies,
      capabilities: capabilities,
    );
  }

  Future<TenantAdminAccountProfilesRepoInt>
  fetchProfileTypeMapPoiProjectionImpact({
    required TenantAdminAccountProfilesRepoString type,
  }) async {
    return tenantAdminAccountProfilesRepoInt(0, defaultValue: 0);
  }

  Future<void> deleteProfileType(TenantAdminAccountProfilesRepoString type);

  Future<void> _waitForProfileTypesFetch() async {
    while (_profileTypesPaginationState.isFetchingProfileTypesPage.value) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _waitForContactSourceCandidatesFetch() async {
    while (_contactSourceCandidatesPaginationState.isFetchingPage.value) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchProfileTypesPage({
    required TenantAdminAccountProfilesRepoInt page,
    required TenantAdminAccountProfilesRepoInt pageSize,
  }) async {
    if (_profileTypesPaginationState.isFetchingProfileTypesPage.value) return;
    if (page.value > 1 &&
        !_profileTypesPaginationState.hasMoreProfileTypes.value) {
      return;
    }

    _profileTypesPaginationState.isFetchingProfileTypesPage =
        tenantAdminAccountProfilesRepoBool(true, defaultValue: true);
    if (page.value > 1) {
      isProfileTypesPageLoadingStreamValue.addValue(
        tenantAdminAccountProfilesRepoBool(true, defaultValue: true),
      );
    }
    try {
      final result = await fetchProfileTypesPage(
        page: page,
        pageSize: pageSize,
      );
      if (page.value == 1) {
        _profileTypesPaginationState.cachedProfileTypes
          ..clear()
          ..addAll(result.items);
      } else {
        _profileTypesPaginationState.cachedProfileTypes.addAll(result.items);
      }
      _profileTypesPaginationState.currentProfileTypesPage = page;
      _profileTypesPaginationState.hasMoreProfileTypes =
          tenantAdminAccountProfilesRepoBool(
            result.hasMore,
            defaultValue: true,
          );
      hasMoreProfileTypesStreamValue.addValue(
        _profileTypesPaginationState.hasMoreProfileTypes,
      );
      profileTypesStreamValue.addValue(
        List<TenantAdminProfileTypeDefinition>.unmodifiable(
          _profileTypesPaginationState.cachedProfileTypes,
        ),
      );
      profileTypesErrorStreamValue.addValue(null);
    } catch (error) {
      profileTypesErrorStreamValue.addValue(
        tenantAdminAccountProfilesRepoString(error.toString()),
      );
      if (page.value == 1) {
        profileTypesStreamValue.addValue(
          const <TenantAdminProfileTypeDefinition>[],
        );
      }
    } finally {
      _profileTypesPaginationState.isFetchingProfileTypesPage =
          tenantAdminAccountProfilesRepoBool(false, defaultValue: false);
      isProfileTypesPageLoadingStreamValue.addValue(
        tenantAdminAccountProfilesRepoBool(false, defaultValue: false),
      );
    }
  }

  void _resetProfileTypesPagination() {
    _profileTypesPaginationState.cachedProfileTypes.clear();
    _profileTypesPaginationState.currentProfileTypesPage =
        tenantAdminAccountProfilesRepoInt(0, defaultValue: 0);
    _profileTypesPaginationState.hasMoreProfileTypes =
        tenantAdminAccountProfilesRepoBool(true, defaultValue: true);
    _profileTypesPaginationState.isFetchingProfileTypesPage =
        tenantAdminAccountProfilesRepoBool(false, defaultValue: false);
    hasMoreProfileTypesStreamValue.addValue(
      tenantAdminAccountProfilesRepoBool(true, defaultValue: true),
    );
    isProfileTypesPageLoadingStreamValue.addValue(
      tenantAdminAccountProfilesRepoBool(false, defaultValue: false),
    );
  }

  Future<TenantAdminPagedResult<TenantAdminAccountProfile>>
  _fetchContactSourceCandidatesPage({
    required TenantAdminAccountProfilesRepoInt page,
    required TenantAdminAccountProfilesRepoInt pageSize,
    TenantAdminAccountProfilesRepoString? excludeAccountProfileId,
  }) async {
    if (_contactSourceCandidatesPaginationState.isFetchingPage.value) {
      throw StateError('Contact-source candidates request already in flight.');
    }
    if (page.value > 1 &&
        !_contactSourceCandidatesPaginationState.hasMore.value) {
      return tenantAdminPagedResultFromRaw(
        items: const <TenantAdminAccountProfile>[],
        hasMore: false,
        currentPage: _contactSourceCandidatesPaginationState.currentPage.value,
        pageSize: _contactSourceCandidatesPaginationState.pageSize.value,
      );
    }

    _contactSourceCandidatesPaginationState.isFetchingPage =
        tenantAdminAccountProfilesRepoBool(true, defaultValue: true);
    try {
      final result = await fetchContactSourceCandidatesPage(
        page: page,
        pageSize: pageSize,
        excludeAccountProfileId: excludeAccountProfileId,
      );
      _contactSourceCandidatesPaginationState.currentPage = page;
      _contactSourceCandidatesPaginationState.hasMore =
          tenantAdminAccountProfilesRepoBool(
            result.hasMore,
            defaultValue: true,
          );
      _contactSourceCandidatesPaginationState.pageSize = pageSize;
      _contactSourceCandidatesPaginationState.excludeAccountProfileId =
          excludeAccountProfileId;
      return result;
    } catch (_) {
      _contactSourceCandidatesPaginationState.hasMore =
          tenantAdminAccountProfilesRepoBool(false, defaultValue: false);
      rethrow;
    } finally {
      _contactSourceCandidatesPaginationState.isFetchingPage =
          tenantAdminAccountProfilesRepoBool(false, defaultValue: false);
    }
  }

  void _resetContactSourceCandidatesPagination({
    TenantAdminAccountProfilesRepoString? excludeAccountProfileId,
    TenantAdminAccountProfilesRepoInt? pageSize,
  }) {
    _contactSourceCandidatesPaginationState.currentPage =
        tenantAdminAccountProfilesRepoInt(0, defaultValue: 0);
    _contactSourceCandidatesPaginationState.hasMore =
        tenantAdminAccountProfilesRepoBool(true, defaultValue: true);
    _contactSourceCandidatesPaginationState.isFetchingPage =
        tenantAdminAccountProfilesRepoBool(false, defaultValue: false);
    _contactSourceCandidatesPaginationState.pageSize =
        pageSize ?? tenantAdminAccountProfilesRepoInt(50, defaultValue: 50);
    _contactSourceCandidatesPaginationState.excludeAccountProfileId =
        excludeAccountProfileId;
  }
}

mixin TenantAdminProfileTypesPaginationMixin
    on TenantAdminAccountProfilesRepositoryContract {
  static final Expando<_TenantAdminProfileTypesPaginationState>
  _profileTypesStateByRepository =
      Expando<_TenantAdminProfileTypesPaginationState>();

  _TenantAdminProfileTypesPaginationState get _mixinProfileTypesState =>
      _profileTypesStateByRepository[this] ??=
          _TenantAdminProfileTypesPaginationState();

  @override
  StreamValue<List<TenantAdminProfileTypeDefinition>?>
  get profileTypesStreamValue =>
      _mixinProfileTypesState.profileTypesStreamValue;

  @override
  StreamValue<TenantAdminAccountProfilesRepoBool>
  get hasMoreProfileTypesStreamValue =>
      _mixinProfileTypesState.hasMoreProfileTypesStreamValue;

  @override
  StreamValue<TenantAdminAccountProfilesRepoBool>
  get isProfileTypesPageLoadingStreamValue =>
      _mixinProfileTypesState.isProfileTypesPageLoadingStreamValue;

  @override
  StreamValue<TenantAdminAccountProfilesRepoString?>
  get profileTypesErrorStreamValue =>
      _mixinProfileTypesState.profileTypesErrorStreamValue;

  @override
  Future<void> loadProfileTypes({
    TenantAdminAccountProfilesRepoInt? pageSize,
  }) async {
    final effectivePageSize =
        pageSize ?? tenantAdminAccountProfilesRepoInt(20, defaultValue: 20);
    await _waitForProfileTypesFetchMixin();
    _resetProfileTypesPaginationMixin();
    profileTypesStreamValue.addValue(null);
    await _fetchProfileTypesPageMixin(
      page: tenantAdminAccountProfilesRepoInt(1, defaultValue: 1),
      pageSize: effectivePageSize,
    );
  }

  @override
  Future<void> loadNextProfileTypesPage({
    TenantAdminAccountProfilesRepoInt? pageSize,
  }) async {
    final effectivePageSize =
        pageSize ?? tenantAdminAccountProfilesRepoInt(20, defaultValue: 20);
    if (_mixinProfileTypesState.isFetchingProfileTypesPage.value ||
        !_mixinProfileTypesState.hasMoreProfileTypes.value) {
      return;
    }
    await _fetchProfileTypesPageMixin(
      page: tenantAdminAccountProfilesRepoInt(
        _mixinProfileTypesState.currentProfileTypesPage.value + 1,
        defaultValue: 1,
      ),
      pageSize: effectivePageSize,
    );
  }

  @override
  Future<void> loadAllProfileTypes({
    TenantAdminAccountProfilesRepoInt? pageSize,
  }) async {
    final effectivePageSize =
        pageSize ?? tenantAdminAccountProfilesRepoInt(50, defaultValue: 50);
    await loadProfileTypes(pageSize: effectivePageSize);
    var safetyCounter = 0;
    while (hasMoreProfileTypesStreamValue.value.value && safetyCounter < 200) {
      safetyCounter += 1;
      await loadNextProfileTypesPage(pageSize: effectivePageSize);
    }
  }

  @override
  void resetProfileTypesState() {
    _resetProfileTypesPaginationMixin();
    profileTypesStreamValue.addValue(null);
    profileTypesErrorStreamValue.addValue(null);
  }

  @override
  Future<TenantAdminProfileTypeDefinition> createProfileTypeWithVisual({
    required TenantAdminAccountProfilesRepoString type,
    required TenantAdminAccountProfilesRepoString label,
    TenantAdminAccountProfilesRepoString? pluralLabel,
    List<TenantAdminAccountProfilesRepoString> allowedTaxonomies = const [],
    required TenantAdminProfileTypeCapabilities capabilities,
    TenantAdminPoiVisual? visual,
    TenantAdminMediaUpload? typeAssetUpload,
  }) {
    return createProfileType(
      type: type,
      label: label,
      pluralLabel: pluralLabel,
      allowedTaxonomies: allowedTaxonomies,
      capabilities: capabilities,
    );
  }

  @override
  Future<TenantAdminProfileTypeDefinition> updateProfileTypeWithVisual({
    required TenantAdminAccountProfilesRepoString type,
    TenantAdminAccountProfilesRepoString? newType,
    TenantAdminAccountProfilesRepoString? label,
    TenantAdminAccountProfilesRepoString? pluralLabel,
    List<TenantAdminAccountProfilesRepoString>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
    TenantAdminPoiVisual? visual,
    TenantAdminMediaUpload? typeAssetUpload,
    TenantAdminAccountProfilesRepoBool? removeTypeAsset,
  }) {
    return updateProfileType(
      type: type,
      newType: newType,
      label: label,
      pluralLabel: pluralLabel,
      allowedTaxonomies: allowedTaxonomies,
      capabilities: capabilities,
    );
  }

  @override
  Future<TenantAdminAccountProfilesRepoInt>
  fetchProfileTypeMapPoiProjectionImpact({
    required TenantAdminAccountProfilesRepoString type,
  }) async {
    return tenantAdminAccountProfilesRepoInt(0, defaultValue: 0);
  }

  Future<void> _waitForProfileTypesFetchMixin() async {
    while (_mixinProfileTypesState.isFetchingProfileTypesPage.value) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchProfileTypesPageMixin({
    required TenantAdminAccountProfilesRepoInt page,
    required TenantAdminAccountProfilesRepoInt pageSize,
  }) async {
    if (_mixinProfileTypesState.isFetchingProfileTypesPage.value) return;
    if (page.value > 1 && !_mixinProfileTypesState.hasMoreProfileTypes.value) {
      return;
    }

    _mixinProfileTypesState.isFetchingProfileTypesPage =
        tenantAdminAccountProfilesRepoBool(true, defaultValue: true);
    if (page.value > 1) {
      isProfileTypesPageLoadingStreamValue.addValue(
        tenantAdminAccountProfilesRepoBool(true, defaultValue: true),
      );
    }
    try {
      final result = await fetchProfileTypesPage(
        page: page,
        pageSize: pageSize,
      );
      if (page.value == 1) {
        _mixinProfileTypesState.cachedProfileTypes
          ..clear()
          ..addAll(result.items);
      } else {
        _mixinProfileTypesState.cachedProfileTypes.addAll(result.items);
      }
      _mixinProfileTypesState.currentProfileTypesPage = page;
      _mixinProfileTypesState.hasMoreProfileTypes =
          tenantAdminAccountProfilesRepoBool(
            result.hasMore,
            defaultValue: true,
          );
      hasMoreProfileTypesStreamValue.addValue(
        _mixinProfileTypesState.hasMoreProfileTypes,
      );
      profileTypesStreamValue.addValue(
        List<TenantAdminProfileTypeDefinition>.unmodifiable(
          _mixinProfileTypesState.cachedProfileTypes,
        ),
      );
      profileTypesErrorStreamValue.addValue(null);
    } catch (error) {
      profileTypesErrorStreamValue.addValue(
        tenantAdminAccountProfilesRepoString(error.toString()),
      );
      if (page.value == 1) {
        profileTypesStreamValue.addValue(
          const <TenantAdminProfileTypeDefinition>[],
        );
      }
    } finally {
      _mixinProfileTypesState.isFetchingProfileTypesPage =
          tenantAdminAccountProfilesRepoBool(false, defaultValue: false);
      isProfileTypesPageLoadingStreamValue.addValue(
        tenantAdminAccountProfilesRepoBool(false, defaultValue: false),
      );
    }
  }

  void _resetProfileTypesPaginationMixin() {
    _mixinProfileTypesState.cachedProfileTypes.clear();
    _mixinProfileTypesState.currentProfileTypesPage =
        tenantAdminAccountProfilesRepoInt(0, defaultValue: 0);
    _mixinProfileTypesState.hasMoreProfileTypes =
        tenantAdminAccountProfilesRepoBool(true, defaultValue: true);
    _mixinProfileTypesState.isFetchingProfileTypesPage =
        tenantAdminAccountProfilesRepoBool(false, defaultValue: false);
    hasMoreProfileTypesStreamValue.addValue(
      tenantAdminAccountProfilesRepoBool(true, defaultValue: true),
    );
    isProfileTypesPageLoadingStreamValue.addValue(
      tenantAdminAccountProfilesRepoBool(false, defaultValue: false),
    );
  }
}

class _TenantAdminProfileTypesPaginationState {
  final List<TenantAdminProfileTypeDefinition> cachedProfileTypes =
      <TenantAdminProfileTypeDefinition>[];
  final StreamValue<List<TenantAdminProfileTypeDefinition>?>
  profileTypesStreamValue =
      StreamValue<List<TenantAdminProfileTypeDefinition>?>();
  final StreamValue<TenantAdminAccountProfilesRepoBool>
  hasMoreProfileTypesStreamValue =
      StreamValue<TenantAdminAccountProfilesRepoBool>(
        defaultValue: tenantAdminAccountProfilesRepoBool(
          true,
          defaultValue: true,
        ),
      );
  final StreamValue<TenantAdminAccountProfilesRepoBool>
  isProfileTypesPageLoadingStreamValue =
      StreamValue<TenantAdminAccountProfilesRepoBool>(
        defaultValue: tenantAdminAccountProfilesRepoBool(
          false,
          defaultValue: false,
        ),
      );
  final StreamValue<TenantAdminAccountProfilesRepoString?>
  profileTypesErrorStreamValue =
      StreamValue<TenantAdminAccountProfilesRepoString?>();
  TenantAdminAccountProfilesRepoBool isFetchingProfileTypesPage =
      tenantAdminAccountProfilesRepoBool(false, defaultValue: false);
  TenantAdminAccountProfilesRepoBool hasMoreProfileTypes =
      tenantAdminAccountProfilesRepoBool(true, defaultValue: true);
  TenantAdminAccountProfilesRepoInt currentProfileTypesPage =
      tenantAdminAccountProfilesRepoInt(0, defaultValue: 0);
}

class _TenantAdminContactSourceCandidatesPaginationState {
  TenantAdminAccountProfilesRepoBool isFetchingPage =
      tenantAdminAccountProfilesRepoBool(false, defaultValue: false);
  TenantAdminAccountProfilesRepoBool hasMore =
      tenantAdminAccountProfilesRepoBool(true, defaultValue: true);
  TenantAdminAccountProfilesRepoInt currentPage =
      tenantAdminAccountProfilesRepoInt(0, defaultValue: 0);
  TenantAdminAccountProfilesRepoInt pageSize =
      tenantAdminAccountProfilesRepoInt(50, defaultValue: 50);
  TenantAdminAccountProfilesRepoString? excludeAccountProfileId;
}
