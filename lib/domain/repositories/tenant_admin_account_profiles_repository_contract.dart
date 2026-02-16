import 'dart:math' as math;

import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class TenantAdminAccountProfilesRepositoryContract {
  static final Expando<_TenantAdminProfileTypesPaginationState>
      _profileTypesStateByRepository =
      Expando<_TenantAdminProfileTypesPaginationState>();

  _TenantAdminProfileTypesPaginationState get _profileTypesPaginationState =>
      _profileTypesStateByRepository[this] ??=
          _TenantAdminProfileTypesPaginationState();

  Future<List<TenantAdminAccountProfile>> fetchAccountProfiles({
    String? accountId,
  });
  Future<TenantAdminAccountProfile> fetchAccountProfile(
      String accountProfileId);
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
  });
  Future<TenantAdminAccountProfile> updateAccountProfile({
    required String accountProfileId,
    String? profileType,
    String? displayName,
    String? slug,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm>? taxonomyTerms,
    String? bio,
    String? avatarUrl,
    String? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  });
  Future<void> deleteAccountProfile(String accountProfileId);
  Future<TenantAdminAccountProfile> restoreAccountProfile(
      String accountProfileId);
  Future<void> forceDeleteAccountProfile(String accountProfileId);
  StreamValue<List<TenantAdminProfileTypeDefinition>?>
      get profileTypesStreamValue =>
          _profileTypesPaginationState.profileTypesStreamValue;

  StreamValue<bool> get hasMoreProfileTypesStreamValue =>
      _profileTypesPaginationState.hasMoreProfileTypesStreamValue;

  StreamValue<bool> get isProfileTypesPageLoadingStreamValue =>
      _profileTypesPaginationState.isProfileTypesPageLoadingStreamValue;

  StreamValue<String?> get profileTypesErrorStreamValue =>
      _profileTypesPaginationState.profileTypesErrorStreamValue;

  Future<void> loadProfileTypes({int pageSize = 20}) async {
    await _waitForProfileTypesFetch();
    _resetProfileTypesPagination();
    profileTypesStreamValue.addValue(null);
    await _fetchProfileTypesPage(page: 1, pageSize: pageSize);
  }

  Future<void> loadNextProfileTypesPage({int pageSize = 20}) async {
    if (_profileTypesPaginationState.isFetchingProfileTypesPage ||
        !_profileTypesPaginationState.hasMoreProfileTypes) {
      return;
    }
    await _fetchProfileTypesPage(
      page: _profileTypesPaginationState.currentProfileTypesPage + 1,
      pageSize: pageSize,
    );
  }

  void resetProfileTypesState() {
    _resetProfileTypesPagination();
    profileTypesStreamValue.addValue(null);
    profileTypesErrorStreamValue.addValue(null);
  }

  Future<List<TenantAdminProfileTypeDefinition>> fetchProfileTypes();
  Future<TenantAdminPagedResult<TenantAdminProfileTypeDefinition>>
      fetchProfileTypesPage({
    required int page,
    required int pageSize,
  }) async {
    final profileTypes = await fetchProfileTypes();
    if (page <= 0 || pageSize <= 0) {
      return const TenantAdminPagedResult<TenantAdminProfileTypeDefinition>(
        items: <TenantAdminProfileTypeDefinition>[],
        hasMore: false,
      );
    }
    final startIndex = (page - 1) * pageSize;
    if (startIndex >= profileTypes.length) {
      return const TenantAdminPagedResult<TenantAdminProfileTypeDefinition>(
        items: <TenantAdminProfileTypeDefinition>[],
        hasMore: false,
      );
    }
    final endIndex = math.min(startIndex + pageSize, profileTypes.length);
    return TenantAdminPagedResult<TenantAdminProfileTypeDefinition>(
      items: profileTypes.sublist(startIndex, endIndex),
      hasMore: endIndex < profileTypes.length,
    );
  }

  Future<TenantAdminProfileTypeDefinition> createProfileType({
    required String type,
    required String label,
    List<String> allowedTaxonomies,
    required TenantAdminProfileTypeCapabilities capabilities,
  });
  Future<TenantAdminProfileTypeDefinition> updateProfileType({
    required String type,
    String? newType,
    String? label,
    List<String>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
  });
  Future<void> deleteProfileType(String type);

  Future<void> _waitForProfileTypesFetch() async {
    while (_profileTypesPaginationState.isFetchingProfileTypesPage) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchProfileTypesPage({
    required int page,
    required int pageSize,
  }) async {
    if (_profileTypesPaginationState.isFetchingProfileTypesPage) return;
    if (page > 1 && !_profileTypesPaginationState.hasMoreProfileTypes) return;

    _profileTypesPaginationState.isFetchingProfileTypesPage = true;
    if (page > 1) {
      isProfileTypesPageLoadingStreamValue.addValue(true);
    }
    try {
      final result = await fetchProfileTypesPage(
        page: page,
        pageSize: pageSize,
      );
      if (page == 1) {
        _profileTypesPaginationState.cachedProfileTypes
          ..clear()
          ..addAll(result.items);
      } else {
        _profileTypesPaginationState.cachedProfileTypes.addAll(result.items);
      }
      _profileTypesPaginationState.currentProfileTypesPage = page;
      _profileTypesPaginationState.hasMoreProfileTypes = result.hasMore;
      hasMoreProfileTypesStreamValue
          .addValue(_profileTypesPaginationState.hasMoreProfileTypes);
      profileTypesStreamValue.addValue(
        List<TenantAdminProfileTypeDefinition>.unmodifiable(
          _profileTypesPaginationState.cachedProfileTypes,
        ),
      );
      profileTypesErrorStreamValue.addValue(null);
    } catch (error) {
      profileTypesErrorStreamValue.addValue(error.toString());
      if (page == 1) {
        profileTypesStreamValue
            .addValue(const <TenantAdminProfileTypeDefinition>[]);
      }
    } finally {
      _profileTypesPaginationState.isFetchingProfileTypesPage = false;
      isProfileTypesPageLoadingStreamValue.addValue(false);
    }
  }

  void _resetProfileTypesPagination() {
    _profileTypesPaginationState.cachedProfileTypes.clear();
    _profileTypesPaginationState.currentProfileTypesPage = 0;
    _profileTypesPaginationState.hasMoreProfileTypes = true;
    _profileTypesPaginationState.isFetchingProfileTypesPage = false;
    hasMoreProfileTypesStreamValue.addValue(true);
    isProfileTypesPageLoadingStreamValue.addValue(false);
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
  StreamValue<bool> get hasMoreProfileTypesStreamValue =>
      _mixinProfileTypesState.hasMoreProfileTypesStreamValue;

  @override
  StreamValue<bool> get isProfileTypesPageLoadingStreamValue =>
      _mixinProfileTypesState.isProfileTypesPageLoadingStreamValue;

  @override
  StreamValue<String?> get profileTypesErrorStreamValue =>
      _mixinProfileTypesState.profileTypesErrorStreamValue;

  @override
  Future<void> loadProfileTypes({int pageSize = 20}) async {
    await _waitForProfileTypesFetchMixin();
    _resetProfileTypesPaginationMixin();
    profileTypesStreamValue.addValue(null);
    await _fetchProfileTypesPageMixin(page: 1, pageSize: pageSize);
  }

  @override
  Future<void> loadNextProfileTypesPage({int pageSize = 20}) async {
    if (_mixinProfileTypesState.isFetchingProfileTypesPage ||
        !_mixinProfileTypesState.hasMoreProfileTypes) {
      return;
    }
    await _fetchProfileTypesPageMixin(
      page: _mixinProfileTypesState.currentProfileTypesPage + 1,
      pageSize: pageSize,
    );
  }

  @override
  void resetProfileTypesState() {
    _resetProfileTypesPaginationMixin();
    profileTypesStreamValue.addValue(null);
    profileTypesErrorStreamValue.addValue(null);
  }

  Future<void> _waitForProfileTypesFetchMixin() async {
    while (_mixinProfileTypesState.isFetchingProfileTypesPage) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchProfileTypesPageMixin({
    required int page,
    required int pageSize,
  }) async {
    if (_mixinProfileTypesState.isFetchingProfileTypesPage) return;
    if (page > 1 && !_mixinProfileTypesState.hasMoreProfileTypes) return;

    _mixinProfileTypesState.isFetchingProfileTypesPage = true;
    if (page > 1) {
      isProfileTypesPageLoadingStreamValue.addValue(true);
    }
    try {
      final result = await fetchProfileTypesPage(
        page: page,
        pageSize: pageSize,
      );
      if (page == 1) {
        _mixinProfileTypesState.cachedProfileTypes
          ..clear()
          ..addAll(result.items);
      } else {
        _mixinProfileTypesState.cachedProfileTypes.addAll(result.items);
      }
      _mixinProfileTypesState.currentProfileTypesPage = page;
      _mixinProfileTypesState.hasMoreProfileTypes = result.hasMore;
      hasMoreProfileTypesStreamValue
          .addValue(_mixinProfileTypesState.hasMoreProfileTypes);
      profileTypesStreamValue.addValue(
        List<TenantAdminProfileTypeDefinition>.unmodifiable(
          _mixinProfileTypesState.cachedProfileTypes,
        ),
      );
      profileTypesErrorStreamValue.addValue(null);
    } catch (error) {
      profileTypesErrorStreamValue.addValue(error.toString());
      if (page == 1) {
        profileTypesStreamValue
            .addValue(const <TenantAdminProfileTypeDefinition>[]);
      }
    } finally {
      _mixinProfileTypesState.isFetchingProfileTypesPage = false;
      isProfileTypesPageLoadingStreamValue.addValue(false);
    }
  }

  void _resetProfileTypesPaginationMixin() {
    _mixinProfileTypesState.cachedProfileTypes.clear();
    _mixinProfileTypesState.currentProfileTypesPage = 0;
    _mixinProfileTypesState.hasMoreProfileTypes = true;
    _mixinProfileTypesState.isFetchingProfileTypesPage = false;
    hasMoreProfileTypesStreamValue.addValue(true);
    isProfileTypesPageLoadingStreamValue.addValue(false);
  }
}

class _TenantAdminProfileTypesPaginationState {
  final List<TenantAdminProfileTypeDefinition> cachedProfileTypes =
      <TenantAdminProfileTypeDefinition>[];
  final StreamValue<List<TenantAdminProfileTypeDefinition>?>
      profileTypesStreamValue =
      StreamValue<List<TenantAdminProfileTypeDefinition>?>();
  final StreamValue<bool> hasMoreProfileTypesStreamValue =
      StreamValue<bool>(defaultValue: true);
  final StreamValue<bool> isProfileTypesPageLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> profileTypesErrorStreamValue =
      StreamValue<String?>();
  bool isFetchingProfileTypesPage = false;
  bool hasMoreProfileTypes = true;
  int currentProfileTypesPage = 0;
}
