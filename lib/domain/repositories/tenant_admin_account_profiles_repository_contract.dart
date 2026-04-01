import 'dart:math' as math;

import 'package:belluga_now/domain/repositories/value_objects/tenant_admin_account_profiles_repository_contract_values.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_taxonomy_terms_value.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms.dart';

export 'package:belluga_now/domain/repositories/value_objects/tenant_admin_account_profiles_repository_contract_values.dart';
export 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_taxonomy_terms_value.dart';

typedef TenantAdminAccountProfilesRepoString
    = TenantAdminAccountProfilesRepositoryContractTextValue;
typedef TenantAdminAccountProfilesRepoInt
    = TenantAdminAccountProfilesRepositoryContractIntValue;
typedef TenantAdminAccountProfilesRepoBool
    = TenantAdminAccountProfilesRepositoryContractBoolValue;

abstract class TenantAdminAccountProfilesRepositoryContract {
  static final Expando<_TenantAdminProfileTypesPaginationState>
      _profileTypesStateByRepository =
      Expando<_TenantAdminProfileTypesPaginationState>();

  _TenantAdminProfileTypesPaginationState get _profileTypesPaginationState =>
      _profileTypesStateByRepository[this] ??=
          _TenantAdminProfileTypesPaginationState();

  Future<List<TenantAdminAccountProfile>> fetchAccountProfiles({
    TenantAdminAccountProfilesRepoString? accountId,
  });
  Future<TenantAdminAccountProfile> fetchAccountProfile(
      TenantAdminAccountProfilesRepoString accountProfileId);
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
  });
  Future<void> deleteAccountProfile(
      TenantAdminAccountProfilesRepoString accountProfileId);
  Future<TenantAdminAccountProfile> restoreAccountProfile(
      TenantAdminAccountProfilesRepoString accountProfileId);
  Future<void> forceDeleteAccountProfile(
      TenantAdminAccountProfilesRepoString accountProfileId);
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
    final effectivePageSize = pageSize ??
        tenantAdminAccountProfilesRepoInt(
          20,
          defaultValue: 20,
        );
    await _waitForProfileTypesFetch();
    _resetProfileTypesPagination();
    profileTypesStreamValue.addValue(null);
    await _fetchProfileTypesPage(
      page: tenantAdminAccountProfilesRepoInt(
        1,
        defaultValue: 1,
      ),
      pageSize: effectivePageSize,
    );
  }

  Future<void> loadNextProfileTypesPage({
    TenantAdminAccountProfilesRepoInt? pageSize,
  }) async {
    final effectivePageSize = pageSize ??
        tenantAdminAccountProfilesRepoInt(
          20,
          defaultValue: 20,
        );
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
    final effectivePageSize = pageSize ??
        tenantAdminAccountProfilesRepoInt(
          50,
          defaultValue: 50,
        );
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
    List<TenantAdminAccountProfilesRepoString> allowedTaxonomies,
    required TenantAdminProfileTypeCapabilities capabilities,
  });
  Future<TenantAdminProfileTypeDefinition> createProfileTypeWithPoiVisual({
    required TenantAdminAccountProfilesRepoString type,
    required TenantAdminAccountProfilesRepoString label,
    List<TenantAdminAccountProfilesRepoString> allowedTaxonomies = const [],
    required TenantAdminProfileTypeCapabilities capabilities,
    TenantAdminPoiVisual? poiVisual,
  }) async {
    return createProfileType(
      type: type,
      label: label,
      allowedTaxonomies: allowedTaxonomies,
      capabilities: capabilities,
    );
  }

  Future<TenantAdminProfileTypeDefinition> updateProfileType({
    required TenantAdminAccountProfilesRepoString type,
    TenantAdminAccountProfilesRepoString? newType,
    TenantAdminAccountProfilesRepoString? label,
    List<TenantAdminAccountProfilesRepoString>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
  });
  Future<TenantAdminProfileTypeDefinition> updateProfileTypeWithPoiVisual({
    required TenantAdminAccountProfilesRepoString type,
    TenantAdminAccountProfilesRepoString? newType,
    TenantAdminAccountProfilesRepoString? label,
    List<TenantAdminAccountProfilesRepoString>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
    TenantAdminPoiVisual? poiVisual,
  }) async {
    return updateProfileType(
      type: type,
      newType: newType,
      label: label,
      allowedTaxonomies: allowedTaxonomies,
      capabilities: capabilities,
    );
  }

  Future<TenantAdminAccountProfilesRepoInt>
      fetchProfileTypeMapPoiProjectionImpact({
    required TenantAdminAccountProfilesRepoString type,
  }) async {
    return tenantAdminAccountProfilesRepoInt(
      0,
      defaultValue: 0,
    );
  }

  Future<void> deleteProfileType(TenantAdminAccountProfilesRepoString type);

  Future<void> _waitForProfileTypesFetch() async {
    while (_profileTypesPaginationState.isFetchingProfileTypesPage.value) {
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
        tenantAdminAccountProfilesRepoBool(
      true,
      defaultValue: true,
    );
    if (page.value > 1) {
      isProfileTypesPageLoadingStreamValue.addValue(
        tenantAdminAccountProfilesRepoBool(
          true,
          defaultValue: true,
        ),
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
      hasMoreProfileTypesStreamValue
          .addValue(_profileTypesPaginationState.hasMoreProfileTypes);
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
        profileTypesStreamValue
            .addValue(const <TenantAdminProfileTypeDefinition>[]);
      }
    } finally {
      _profileTypesPaginationState.isFetchingProfileTypesPage =
          tenantAdminAccountProfilesRepoBool(
        false,
        defaultValue: false,
      );
      isProfileTypesPageLoadingStreamValue.addValue(
        tenantAdminAccountProfilesRepoBool(
          false,
          defaultValue: false,
        ),
      );
    }
  }

  void _resetProfileTypesPagination() {
    _profileTypesPaginationState.cachedProfileTypes.clear();
    _profileTypesPaginationState.currentProfileTypesPage =
        tenantAdminAccountProfilesRepoInt(
      0,
      defaultValue: 0,
    );
    _profileTypesPaginationState.hasMoreProfileTypes =
        tenantAdminAccountProfilesRepoBool(
      true,
      defaultValue: true,
    );
    _profileTypesPaginationState.isFetchingProfileTypesPage =
        tenantAdminAccountProfilesRepoBool(
      false,
      defaultValue: false,
    );
    hasMoreProfileTypesStreamValue.addValue(
      tenantAdminAccountProfilesRepoBool(
        true,
        defaultValue: true,
      ),
    );
    isProfileTypesPageLoadingStreamValue.addValue(
      tenantAdminAccountProfilesRepoBool(
        false,
        defaultValue: false,
      ),
    );
  }
}

extension TenantAdminAccountProfilesRepositoryLookup
    on TenantAdminAccountProfilesRepositoryContract {
  Future<TenantAdminProfileTypeDefinition> fetchProfileType(
    TenantAdminAccountProfilesRepoString profileType,
  ) async {
    final normalizedType = profileType.value.trim();
    if (normalizedType.isEmpty) {
      throw ArgumentError.value(
        profileType,
        'profileType',
        'Profile type must not be empty',
      );
    }

    final profileTypes = await fetchProfileTypes();
    for (final definition in profileTypes) {
      if (definition.type == normalizedType) {
        return definition;
      }
    }

    throw StateError('Profile type not found for type: $normalizedType');
  }
}

mixin TenantAdminProfileTypesPaginationMixin
    implements TenantAdminAccountProfilesRepositoryContract {
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
  Future<void> loadProfileTypes(
      {TenantAdminAccountProfilesRepoInt? pageSize}) async {
    final effectivePageSize = pageSize ??
        tenantAdminAccountProfilesRepoInt(
          20,
          defaultValue: 20,
        );
    await _waitForProfileTypesFetchMixin();
    _resetProfileTypesPaginationMixin();
    profileTypesStreamValue.addValue(null);
    await _fetchProfileTypesPageMixin(
      page: tenantAdminAccountProfilesRepoInt(
        1,
        defaultValue: 1,
      ),
      pageSize: effectivePageSize,
    );
  }

  @override
  Future<void> loadNextProfileTypesPage(
      {TenantAdminAccountProfilesRepoInt? pageSize}) async {
    final effectivePageSize = pageSize ??
        tenantAdminAccountProfilesRepoInt(
          20,
          defaultValue: 20,
        );
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
  Future<void> loadAllProfileTypes(
      {TenantAdminAccountProfilesRepoInt? pageSize}) async {
    final effectivePageSize = pageSize ??
        tenantAdminAccountProfilesRepoInt(
          50,
          defaultValue: 50,
        );
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
  Future<TenantAdminProfileTypeDefinition> createProfileTypeWithPoiVisual({
    required TenantAdminAccountProfilesRepoString type,
    required TenantAdminAccountProfilesRepoString label,
    List<TenantAdminAccountProfilesRepoString> allowedTaxonomies = const [],
    required TenantAdminProfileTypeCapabilities capabilities,
    TenantAdminPoiVisual? poiVisual,
  }) {
    return createProfileType(
      type: type,
      label: label,
      allowedTaxonomies: allowedTaxonomies,
      capabilities: capabilities,
    );
  }

  @override
  Future<TenantAdminProfileTypeDefinition> updateProfileTypeWithPoiVisual({
    required TenantAdminAccountProfilesRepoString type,
    TenantAdminAccountProfilesRepoString? newType,
    TenantAdminAccountProfilesRepoString? label,
    List<TenantAdminAccountProfilesRepoString>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
    TenantAdminPoiVisual? poiVisual,
  }) {
    return updateProfileType(
      type: type,
      newType: newType,
      label: label,
      allowedTaxonomies: allowedTaxonomies,
      capabilities: capabilities,
    );
  }

  @override
  Future<TenantAdminAccountProfilesRepoInt>
      fetchProfileTypeMapPoiProjectionImpact({
    required TenantAdminAccountProfilesRepoString type,
  }) async {
    return tenantAdminAccountProfilesRepoInt(
      0,
      defaultValue: 0,
    );
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
        tenantAdminAccountProfilesRepoBool(
      true,
      defaultValue: true,
    );
    if (page.value > 1) {
      isProfileTypesPageLoadingStreamValue.addValue(
        tenantAdminAccountProfilesRepoBool(
          true,
          defaultValue: true,
        ),
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
      hasMoreProfileTypesStreamValue
          .addValue(_mixinProfileTypesState.hasMoreProfileTypes);
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
        profileTypesStreamValue
            .addValue(const <TenantAdminProfileTypeDefinition>[]);
      }
    } finally {
      _mixinProfileTypesState.isFetchingProfileTypesPage =
          tenantAdminAccountProfilesRepoBool(
        false,
        defaultValue: false,
      );
      isProfileTypesPageLoadingStreamValue.addValue(
        tenantAdminAccountProfilesRepoBool(
          false,
          defaultValue: false,
        ),
      );
    }
  }

  void _resetProfileTypesPaginationMixin() {
    _mixinProfileTypesState.cachedProfileTypes.clear();
    _mixinProfileTypesState.currentProfileTypesPage =
        tenantAdminAccountProfilesRepoInt(
      0,
      defaultValue: 0,
    );
    _mixinProfileTypesState.hasMoreProfileTypes =
        tenantAdminAccountProfilesRepoBool(
      true,
      defaultValue: true,
    );
    _mixinProfileTypesState.isFetchingProfileTypesPage =
        tenantAdminAccountProfilesRepoBool(
      false,
      defaultValue: false,
    );
    hasMoreProfileTypesStreamValue.addValue(
      tenantAdminAccountProfilesRepoBool(
        true,
        defaultValue: true,
      ),
    );
    isProfileTypesPageLoadingStreamValue.addValue(
      tenantAdminAccountProfilesRepoBool(
        false,
        defaultValue: false,
      ),
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
      tenantAdminAccountProfilesRepoBool(
    false,
    defaultValue: false,
  );
  TenantAdminAccountProfilesRepoBool hasMoreProfileTypes =
      tenantAdminAccountProfilesRepoBool(
    true,
    defaultValue: true,
  );
  TenantAdminAccountProfilesRepoInt currentProfileTypesPage =
      tenantAdminAccountProfilesRepoInt(
    0,
    defaultValue: 0,
  );
}
