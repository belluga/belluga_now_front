import 'dart:math' as math;

import 'package:belluga_now/domain/repositories/value_objects/tenant_admin_static_assets_repository_contract_values.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_asset.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_taxonomy_terms_value.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms.dart';

export 'package:belluga_now/domain/repositories/value_objects/tenant_admin_static_assets_repository_contract_values.dart';
export 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_taxonomy_terms_value.dart';

typedef TenantAdminStaticAssetsRepoString
    = TenantAdminStaticAssetsRepositoryContractTextValue;
typedef TenantAdminStaticAssetsRepoInt
    = TenantAdminStaticAssetsRepositoryContractIntValue;
typedef TenantAdminStaticAssetsRepoBool
    = TenantAdminStaticAssetsRepositoryContractBoolValue;

abstract class TenantAdminStaticAssetsRepositoryContract {
  static final TenantAdminStaticAssetsRepoInt _defaultPageSize =
      TenantAdminStaticAssetsRepoInt.fromRaw(20, defaultValue: 20);
  static final TenantAdminStaticAssetsRepoInt _defaultBulkPageSize =
      TenantAdminStaticAssetsRepoInt.fromRaw(50, defaultValue: 50);

  static final Expando<_TenantAdminStaticAssetsPaginationState>
      _paginationStateByRepository =
      Expando<_TenantAdminStaticAssetsPaginationState>();

  _TenantAdminStaticAssetsPaginationState get _paginationState =>
      _paginationStateByRepository[this] ??=
          _TenantAdminStaticAssetsPaginationState();

  StreamValue<List<TenantAdminStaticAsset>?> get staticAssetsStreamValue =>
      _paginationState.staticAssetsStreamValue;

  StreamValue<TenantAdminStaticAssetsRepoBool>
      get hasMoreStaticAssetsStreamValue =>
          _paginationState.hasMoreStaticAssetsStreamValue;

  StreamValue<TenantAdminStaticAssetsRepoBool>
      get isStaticAssetsPageLoadingStreamValue =>
          _paginationState.isStaticAssetsPageLoadingStreamValue;

  StreamValue<TenantAdminStaticAssetsRepoString?>
      get staticAssetsErrorStreamValue =>
          _paginationState.staticAssetsErrorStreamValue;

  Future<void> loadStaticAssets({
    TenantAdminStaticAssetsRepoInt? pageSize,
  }) async {
    final effectivePageSize = pageSize ?? _defaultPageSize;
    await _waitForStaticAssetsFetch();
    _resetStaticAssetsPagination();
    staticAssetsStreamValue.addValue(null);
    await _fetchStaticAssetsPage(
      page: TenantAdminStaticAssetsRepoInt.fromRaw(1, defaultValue: 1),
      pageSize: effectivePageSize,
    );
  }

  Future<void> loadNextStaticAssetsPage({
    TenantAdminStaticAssetsRepoInt? pageSize,
  }) async {
    final effectivePageSize = pageSize ?? _defaultPageSize;
    if (_paginationState.isFetchingStaticAssetsPage.value ||
        !_paginationState.hasMoreStaticAssets.value) {
      return;
    }
    await _fetchStaticAssetsPage(
      page: TenantAdminStaticAssetsRepoInt.fromRaw(
        _paginationState.currentStaticAssetsPage.value + 1,
        defaultValue: 1,
      ),
      pageSize: effectivePageSize,
    );
  }

  void resetStaticAssetsState() {
    _resetStaticAssetsPagination();
    staticAssetsStreamValue.addValue(null);
    staticAssetsErrorStreamValue.addValue(null);
  }

  Future<List<TenantAdminStaticAsset>> fetchStaticAssets();
  Future<TenantAdminPagedResult<TenantAdminStaticAsset>> fetchStaticAssetsPage({
    required TenantAdminStaticAssetsRepoInt page,
    required TenantAdminStaticAssetsRepoInt pageSize,
  }) async {
    final assets = await fetchStaticAssets();
    if (page.value <= 0 || pageSize.value <= 0) {
      return tenantAdminPagedResultFromRaw(
        items: <TenantAdminStaticAsset>[],
        hasMore: false,
      );
    }
    final startIndex = (page.value - 1) * pageSize.value;
    if (startIndex >= assets.length) {
      return tenantAdminPagedResultFromRaw(
        items: <TenantAdminStaticAsset>[],
        hasMore: false,
      );
    }
    final endIndex = math.min(startIndex + pageSize.value, assets.length);
    return tenantAdminPagedResultFromRaw(
      items: assets.sublist(startIndex, endIndex),
      hasMore: endIndex < assets.length,
    );
  }

  Future<TenantAdminStaticAsset> fetchStaticAsset(
      TenantAdminStaticAssetsRepoString assetId);

  Future<TenantAdminStaticAsset> createStaticAsset({
    required TenantAdminStaticAssetsRepoString profileType,
    required TenantAdminStaticAssetsRepoString displayName,
    TenantAdminLocation? location,
    TenantAdminTaxonomyTerms taxonomyTerms =
        const TenantAdminTaxonomyTerms.empty(),
    TenantAdminStaticAssetsRepoString? bio,
    TenantAdminStaticAssetsRepoString? content,
    TenantAdminStaticAssetsRepoString? avatarUrl,
    TenantAdminStaticAssetsRepoString? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  });

  Future<TenantAdminStaticAsset> updateStaticAsset({
    required TenantAdminStaticAssetsRepoString assetId,
    TenantAdminStaticAssetsRepoString? profileType,
    TenantAdminStaticAssetsRepoString? displayName,
    TenantAdminStaticAssetsRepoString? slug,
    TenantAdminLocation? location,
    TenantAdminTaxonomyTerms? taxonomyTerms,
    TenantAdminStaticAssetsRepoString? bio,
    TenantAdminStaticAssetsRepoString? content,
    TenantAdminStaticAssetsRepoString? avatarUrl,
    TenantAdminStaticAssetsRepoString? coverUrl,
    TenantAdminStaticAssetsRepoBool? removeAvatar,
    TenantAdminStaticAssetsRepoBool? removeCover,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  });

  Future<void> deleteStaticAsset(TenantAdminStaticAssetsRepoString assetId);

  Future<TenantAdminStaticAsset> restoreStaticAsset(
      TenantAdminStaticAssetsRepoString assetId);

  Future<void> forceDeleteStaticAsset(
      TenantAdminStaticAssetsRepoString assetId);

  StreamValue<List<TenantAdminStaticProfileTypeDefinition>?>
      get staticProfileTypesStreamValue =>
          _paginationState.staticProfileTypesStreamValue;

  StreamValue<TenantAdminStaticAssetsRepoBool>
      get hasMoreStaticProfileTypesStreamValue =>
          _paginationState.hasMoreStaticProfileTypesStreamValue;

  StreamValue<TenantAdminStaticAssetsRepoBool>
      get isStaticProfileTypesPageLoadingStreamValue =>
          _paginationState.isStaticProfileTypesPageLoadingStreamValue;

  StreamValue<TenantAdminStaticAssetsRepoString?>
      get staticProfileTypesErrorStreamValue =>
          _paginationState.staticProfileTypesErrorStreamValue;

  Future<void> loadStaticProfileTypes({
    TenantAdminStaticAssetsRepoInt? pageSize,
  }) async {
    final effectivePageSize = pageSize ?? _defaultPageSize;
    await _waitForStaticProfileTypesFetch();
    _resetStaticProfileTypesPagination();
    staticProfileTypesStreamValue.addValue(null);
    await _fetchStaticProfileTypesPage(
      page: TenantAdminStaticAssetsRepoInt.fromRaw(1, defaultValue: 1),
      pageSize: effectivePageSize,
    );
  }

  Future<void> loadNextStaticProfileTypesPage({
    TenantAdminStaticAssetsRepoInt? pageSize,
  }) async {
    final effectivePageSize = pageSize ?? _defaultPageSize;
    if (_paginationState.isFetchingStaticProfileTypesPage.value ||
        !_paginationState.hasMoreStaticProfileTypes.value) {
      return;
    }
    await _fetchStaticProfileTypesPage(
      page: TenantAdminStaticAssetsRepoInt.fromRaw(
        _paginationState.currentStaticProfileTypesPage.value + 1,
        defaultValue: 1,
      ),
      pageSize: effectivePageSize,
    );
  }

  Future<void> loadAllStaticProfileTypes({
    TenantAdminStaticAssetsRepoInt? pageSize,
  }) async {
    final effectivePageSize = pageSize ?? _defaultBulkPageSize;
    await loadStaticProfileTypes(pageSize: effectivePageSize);
    var safetyCounter = 0;
    while (hasMoreStaticProfileTypesStreamValue.value.value &&
        safetyCounter < 200) {
      safetyCounter += 1;
      await loadNextStaticProfileTypesPage(pageSize: effectivePageSize);
    }
  }

  void resetStaticProfileTypesState() {
    _resetStaticProfileTypesPagination();
    staticProfileTypesStreamValue.addValue(null);
    staticProfileTypesErrorStreamValue.addValue(null);
  }

  Future<List<TenantAdminStaticProfileTypeDefinition>>
      fetchStaticProfileTypes();
  Future<TenantAdminPagedResult<TenantAdminStaticProfileTypeDefinition>>
      fetchStaticProfileTypesPage({
    required TenantAdminStaticAssetsRepoInt page,
    required TenantAdminStaticAssetsRepoInt pageSize,
  }) async {
    final profileTypes = await fetchStaticProfileTypes();
    if (page.value <= 0 || pageSize.value <= 0) {
      return tenantAdminPagedResultFromRaw(
        items: <TenantAdminStaticProfileTypeDefinition>[],
        hasMore: false,
      );
    }
    final startIndex = (page.value - 1) * pageSize.value;
    if (startIndex >= profileTypes.length) {
      return tenantAdminPagedResultFromRaw(
        items: <TenantAdminStaticProfileTypeDefinition>[],
        hasMore: false,
      );
    }
    final endIndex = math.min(startIndex + pageSize.value, profileTypes.length);
    return tenantAdminPagedResultFromRaw(
      items: profileTypes.sublist(startIndex, endIndex),
      hasMore: endIndex < profileTypes.length,
    );
  }

  Future<TenantAdminStaticProfileTypeDefinition> createStaticProfileType({
    required TenantAdminStaticAssetsRepoString type,
    required TenantAdminStaticAssetsRepoString label,
    List<TenantAdminStaticAssetsRepoString>? allowedTaxonomies,
    required TenantAdminStaticProfileTypeCapabilities capabilities,
  });
  Future<TenantAdminStaticProfileTypeDefinition>
      createStaticProfileTypeWithVisual({
    required TenantAdminStaticAssetsRepoString type,
    required TenantAdminStaticAssetsRepoString label,
    List<TenantAdminStaticAssetsRepoString> allowedTaxonomies = const [],
    required TenantAdminStaticProfileTypeCapabilities capabilities,
    TenantAdminPoiVisual? visual,
    TenantAdminMediaUpload? typeAssetUpload,
  }) async {
    return createStaticProfileType(
      type: type,
      label: label,
      allowedTaxonomies: allowedTaxonomies.isEmpty ? null : allowedTaxonomies,
      capabilities: capabilities,
    );
  }

  Future<TenantAdminStaticProfileTypeDefinition> updateStaticProfileType({
    required TenantAdminStaticAssetsRepoString type,
    TenantAdminStaticAssetsRepoString? newType,
    TenantAdminStaticAssetsRepoString? label,
    List<TenantAdminStaticAssetsRepoString>? allowedTaxonomies,
    TenantAdminStaticProfileTypeCapabilities? capabilities,
  });
  Future<TenantAdminStaticProfileTypeDefinition>
      updateStaticProfileTypeWithVisual({
    required TenantAdminStaticAssetsRepoString type,
    TenantAdminStaticAssetsRepoString? newType,
    TenantAdminStaticAssetsRepoString? label,
    List<TenantAdminStaticAssetsRepoString>? allowedTaxonomies,
    TenantAdminStaticProfileTypeCapabilities? capabilities,
    TenantAdminPoiVisual? visual,
    TenantAdminMediaUpload? typeAssetUpload,
    TenantAdminStaticAssetsRepoBool? removeTypeAsset,
  }) async {
    return updateStaticProfileType(
      type: type,
      newType: newType,
      label: label,
      allowedTaxonomies: allowedTaxonomies,
      capabilities: capabilities,
    );
  }

  Future<TenantAdminStaticAssetsRepoInt>
      fetchStaticProfileTypeMapPoiProjectionImpact({
    required TenantAdminStaticAssetsRepoString type,
  }) async {
    return TenantAdminStaticAssetsRepoInt.fromRaw(0, defaultValue: 0);
  }

  Future<void> deleteStaticProfileType(TenantAdminStaticAssetsRepoString type);

  Future<void> _waitForStaticAssetsFetch() async {
    while (_paginationState.isFetchingStaticAssetsPage.value) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchStaticAssetsPage({
    required TenantAdminStaticAssetsRepoInt page,
    required TenantAdminStaticAssetsRepoInt pageSize,
  }) async {
    if (_paginationState.isFetchingStaticAssetsPage.value) return;
    if (page.value > 1 && !_paginationState.hasMoreStaticAssets.value) return;

    _paginationState.isFetchingStaticAssetsPage =
        TenantAdminStaticAssetsRepoBool.fromRaw(true, defaultValue: true);
    if (page.value > 1) {
      isStaticAssetsPageLoadingStreamValue.addValue(
        TenantAdminStaticAssetsRepoBool.fromRaw(true, defaultValue: true),
      );
    }
    try {
      final result = await fetchStaticAssetsPage(
        page: page,
        pageSize: pageSize,
      );
      if (page.value == 1) {
        _paginationState.cachedStaticAssets
          ..clear()
          ..addAll(result.items);
      } else {
        _paginationState.cachedStaticAssets.addAll(result.items);
      }
      _paginationState.currentStaticAssetsPage = page;
      _paginationState.hasMoreStaticAssets =
          TenantAdminStaticAssetsRepoBool.fromRaw(
        result.hasMore,
        defaultValue: result.hasMore,
      );
      hasMoreStaticAssetsStreamValue
          .addValue(_paginationState.hasMoreStaticAssets);
      staticAssetsStreamValue.addValue(
        List<TenantAdminStaticAsset>.unmodifiable(
          _paginationState.cachedStaticAssets,
        ),
      );
      staticAssetsErrorStreamValue.addValue(null);
    } catch (error) {
      staticAssetsErrorStreamValue.addValue(
        TenantAdminStaticAssetsRepoString.fromRaw(error.toString()),
      );
      if (page.value == 1) {
        staticAssetsStreamValue.addValue(const <TenantAdminStaticAsset>[]);
      }
    } finally {
      _paginationState.isFetchingStaticAssetsPage =
          TenantAdminStaticAssetsRepoBool.fromRaw(
        false,
        defaultValue: false,
      );
      isStaticAssetsPageLoadingStreamValue.addValue(
        TenantAdminStaticAssetsRepoBool.fromRaw(
          false,
          defaultValue: false,
        ),
      );
    }
  }

  void _resetStaticAssetsPagination() {
    _paginationState.cachedStaticAssets.clear();
    _paginationState.currentStaticAssetsPage =
        TenantAdminStaticAssetsRepoInt.fromRaw(0, defaultValue: 0);
    _paginationState.hasMoreStaticAssets =
        TenantAdminStaticAssetsRepoBool.fromRaw(
      true,
      defaultValue: true,
    );
    _paginationState.isFetchingStaticAssetsPage =
        TenantAdminStaticAssetsRepoBool.fromRaw(
      false,
      defaultValue: false,
    );
    hasMoreStaticAssetsStreamValue.addValue(
      TenantAdminStaticAssetsRepoBool.fromRaw(true, defaultValue: true),
    );
    isStaticAssetsPageLoadingStreamValue.addValue(
      TenantAdminStaticAssetsRepoBool.fromRaw(false, defaultValue: false),
    );
  }

  Future<void> _waitForStaticProfileTypesFetch() async {
    while (_paginationState.isFetchingStaticProfileTypesPage.value) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchStaticProfileTypesPage({
    required TenantAdminStaticAssetsRepoInt page,
    required TenantAdminStaticAssetsRepoInt pageSize,
  }) async {
    if (_paginationState.isFetchingStaticProfileTypesPage.value) return;
    if (page.value > 1 && !_paginationState.hasMoreStaticProfileTypes.value) {
      return;
    }

    _paginationState.isFetchingStaticProfileTypesPage =
        TenantAdminStaticAssetsRepoBool.fromRaw(true, defaultValue: true);
    if (page.value > 1) {
      isStaticProfileTypesPageLoadingStreamValue.addValue(
        TenantAdminStaticAssetsRepoBool.fromRaw(true, defaultValue: true),
      );
    }
    try {
      final result = await fetchStaticProfileTypesPage(
        page: page,
        pageSize: pageSize,
      );
      if (page.value == 1) {
        _paginationState.cachedStaticProfileTypes
          ..clear()
          ..addAll(result.items);
      } else {
        _paginationState.cachedStaticProfileTypes.addAll(result.items);
      }
      _paginationState.currentStaticProfileTypesPage = page;
      _paginationState.hasMoreStaticProfileTypes =
          TenantAdminStaticAssetsRepoBool.fromRaw(
        result.hasMore,
        defaultValue: result.hasMore,
      );
      hasMoreStaticProfileTypesStreamValue
          .addValue(_paginationState.hasMoreStaticProfileTypes);
      staticProfileTypesStreamValue.addValue(
        List<TenantAdminStaticProfileTypeDefinition>.unmodifiable(
          _paginationState.cachedStaticProfileTypes,
        ),
      );
      staticProfileTypesErrorStreamValue.addValue(null);
    } catch (error) {
      staticProfileTypesErrorStreamValue.addValue(
        TenantAdminStaticAssetsRepoString.fromRaw(error.toString()),
      );
      if (page.value == 1) {
        staticProfileTypesStreamValue.addValue(
          const <TenantAdminStaticProfileTypeDefinition>[],
        );
      }
    } finally {
      _paginationState.isFetchingStaticProfileTypesPage =
          TenantAdminStaticAssetsRepoBool.fromRaw(
        false,
        defaultValue: false,
      );
      isStaticProfileTypesPageLoadingStreamValue.addValue(
        TenantAdminStaticAssetsRepoBool.fromRaw(false, defaultValue: false),
      );
    }
  }

  void _resetStaticProfileTypesPagination() {
    _paginationState.cachedStaticProfileTypes.clear();
    _paginationState.currentStaticProfileTypesPage =
        TenantAdminStaticAssetsRepoInt.fromRaw(0, defaultValue: 0);
    _paginationState.hasMoreStaticProfileTypes =
        TenantAdminStaticAssetsRepoBool.fromRaw(
      true,
      defaultValue: true,
    );
    _paginationState.isFetchingStaticProfileTypesPage =
        TenantAdminStaticAssetsRepoBool.fromRaw(
      false,
      defaultValue: false,
    );
    hasMoreStaticProfileTypesStreamValue.addValue(
      TenantAdminStaticAssetsRepoBool.fromRaw(true, defaultValue: true),
    );
    isStaticProfileTypesPageLoadingStreamValue.addValue(
      TenantAdminStaticAssetsRepoBool.fromRaw(false, defaultValue: false),
    );
  }
}

extension TenantAdminStaticAssetsRepositoryLookup
    on TenantAdminStaticAssetsRepositoryContract {
  Future<TenantAdminStaticProfileTypeDefinition> fetchStaticProfileType(
    TenantAdminStaticAssetsRepoString profileType,
  ) async {
    final normalizedType = profileType.value.trim();
    if (normalizedType.isEmpty) {
      throw ArgumentError.value(
        profileType,
        'profileType',
        'Static profile type must not be empty',
      );
    }

    final profileTypes = await fetchStaticProfileTypes();
    for (final definition in profileTypes) {
      if (definition.type == normalizedType) {
        return definition;
      }
    }

    throw StateError('Static profile type not found for type: $normalizedType');
  }
}

mixin TenantAdminStaticAssetsPaginationMixin
    implements TenantAdminStaticAssetsRepositoryContract {
  static final TenantAdminStaticAssetsRepoInt _defaultPageSize =
      TenantAdminStaticAssetsRepoInt.fromRaw(20, defaultValue: 20);
  static final TenantAdminStaticAssetsRepoInt _defaultBulkPageSize =
      TenantAdminStaticAssetsRepoInt.fromRaw(50, defaultValue: 50);

  static final Expando<_TenantAdminStaticAssetsPaginationState>
      _paginationStateByRepository =
      Expando<_TenantAdminStaticAssetsPaginationState>();

  @override
  _TenantAdminStaticAssetsPaginationState get _paginationState =>
      _paginationStateByRepository[this] ??=
          _TenantAdminStaticAssetsPaginationState();

  @override
  StreamValue<List<TenantAdminStaticAsset>?> get staticAssetsStreamValue =>
      _paginationState.staticAssetsStreamValue;

  @override
  StreamValue<TenantAdminStaticAssetsRepoBool>
      get hasMoreStaticAssetsStreamValue =>
          _paginationState.hasMoreStaticAssetsStreamValue;

  @override
  StreamValue<TenantAdminStaticAssetsRepoBool>
      get isStaticAssetsPageLoadingStreamValue =>
          _paginationState.isStaticAssetsPageLoadingStreamValue;

  @override
  StreamValue<TenantAdminStaticAssetsRepoString?>
      get staticAssetsErrorStreamValue =>
          _paginationState.staticAssetsErrorStreamValue;

  @override
  Future<void> loadStaticAssets({
    TenantAdminStaticAssetsRepoInt? pageSize,
  }) async {
    final effectivePageSize = pageSize ?? _defaultPageSize;
    await _waitForStaticAssetsFetch();
    _resetStaticAssetsPagination();
    staticAssetsStreamValue.addValue(null);
    await _fetchStaticAssetsPage(
      page: TenantAdminStaticAssetsRepoInt.fromRaw(1, defaultValue: 1),
      pageSize: effectivePageSize,
    );
  }

  @override
  Future<void> loadNextStaticAssetsPage({
    TenantAdminStaticAssetsRepoInt? pageSize,
  }) async {
    final effectivePageSize = pageSize ?? _defaultPageSize;
    if (_paginationState.isFetchingStaticAssetsPage.value ||
        !_paginationState.hasMoreStaticAssets.value) {
      return;
    }
    await _fetchStaticAssetsPage(
      page: TenantAdminStaticAssetsRepoInt.fromRaw(
        _paginationState.currentStaticAssetsPage.value + 1,
        defaultValue: 1,
      ),
      pageSize: effectivePageSize,
    );
  }

  @override
  void resetStaticAssetsState() {
    _resetStaticAssetsPagination();
    staticAssetsStreamValue.addValue(null);
    staticAssetsErrorStreamValue.addValue(null);
  }

  @override
  StreamValue<List<TenantAdminStaticProfileTypeDefinition>?>
      get staticProfileTypesStreamValue =>
          _paginationState.staticProfileTypesStreamValue;

  @override
  StreamValue<TenantAdminStaticAssetsRepoBool>
      get hasMoreStaticProfileTypesStreamValue =>
          _paginationState.hasMoreStaticProfileTypesStreamValue;

  @override
  StreamValue<TenantAdminStaticAssetsRepoBool>
      get isStaticProfileTypesPageLoadingStreamValue =>
          _paginationState.isStaticProfileTypesPageLoadingStreamValue;

  @override
  StreamValue<TenantAdminStaticAssetsRepoString?>
      get staticProfileTypesErrorStreamValue =>
          _paginationState.staticProfileTypesErrorStreamValue;

  @override
  Future<void> loadStaticProfileTypes({
    TenantAdminStaticAssetsRepoInt? pageSize,
  }) async {
    final effectivePageSize = pageSize ?? _defaultPageSize;
    await _waitForStaticProfileTypesFetch();
    _resetStaticProfileTypesPagination();
    staticProfileTypesStreamValue.addValue(null);
    await _fetchStaticProfileTypesPage(
      page: TenantAdminStaticAssetsRepoInt.fromRaw(1, defaultValue: 1),
      pageSize: effectivePageSize,
    );
  }

  @override
  Future<void> loadNextStaticProfileTypesPage({
    TenantAdminStaticAssetsRepoInt? pageSize,
  }) async {
    final effectivePageSize = pageSize ?? _defaultPageSize;
    if (_paginationState.isFetchingStaticProfileTypesPage.value ||
        !_paginationState.hasMoreStaticProfileTypes.value) {
      return;
    }
    await _fetchStaticProfileTypesPage(
      page: TenantAdminStaticAssetsRepoInt.fromRaw(
        _paginationState.currentStaticProfileTypesPage.value + 1,
        defaultValue: 1,
      ),
      pageSize: effectivePageSize,
    );
  }

  @override
  Future<void> loadAllStaticProfileTypes({
    TenantAdminStaticAssetsRepoInt? pageSize,
  }) async {
    final effectivePageSize = pageSize ?? _defaultBulkPageSize;
    await loadStaticProfileTypes(pageSize: effectivePageSize);
    var safetyCounter = 0;
    while (hasMoreStaticProfileTypesStreamValue.value.value &&
        safetyCounter < 200) {
      safetyCounter += 1;
      await loadNextStaticProfileTypesPage(pageSize: effectivePageSize);
    }
  }

  @override
  void resetStaticProfileTypesState() {
    _resetStaticProfileTypesPagination();
    staticProfileTypesStreamValue.addValue(null);
    staticProfileTypesErrorStreamValue.addValue(null);
  }

  @override
  Future<TenantAdminStaticProfileTypeDefinition>
      createStaticProfileTypeWithVisual({
    required TenantAdminStaticAssetsRepoString type,
    required TenantAdminStaticAssetsRepoString label,
    List<TenantAdminStaticAssetsRepoString>? allowedTaxonomies,
    required TenantAdminStaticProfileTypeCapabilities capabilities,
    TenantAdminPoiVisual? visual,
    TenantAdminMediaUpload? typeAssetUpload,
  }) {
    return createStaticProfileType(
      type: type,
      label: label,
      allowedTaxonomies: allowedTaxonomies,
      capabilities: capabilities,
    );
  }

  @override
  Future<TenantAdminStaticProfileTypeDefinition>
      updateStaticProfileTypeWithVisual({
    required TenantAdminStaticAssetsRepoString type,
    TenantAdminStaticAssetsRepoString? newType,
    TenantAdminStaticAssetsRepoString? label,
    List<TenantAdminStaticAssetsRepoString>? allowedTaxonomies,
    TenantAdminStaticProfileTypeCapabilities? capabilities,
    TenantAdminPoiVisual? visual,
    TenantAdminMediaUpload? typeAssetUpload,
    TenantAdminStaticAssetsRepoBool? removeTypeAsset,
  }) {
    return updateStaticProfileType(
      type: type,
      newType: newType,
      label: label,
      allowedTaxonomies: allowedTaxonomies,
      capabilities: capabilities,
    );
  }

  @override
  Future<TenantAdminStaticAssetsRepoInt>
      fetchStaticProfileTypeMapPoiProjectionImpact({
    required TenantAdminStaticAssetsRepoString type,
  }) async {
    return TenantAdminStaticAssetsRepoInt.fromRaw(0, defaultValue: 0);
  }

  @override
  Future<void> _waitForStaticAssetsFetch() async {
    while (_paginationState.isFetchingStaticAssetsPage.value) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  @override
  Future<void> _fetchStaticAssetsPage({
    required TenantAdminStaticAssetsRepoInt page,
    required TenantAdminStaticAssetsRepoInt pageSize,
  }) async {
    if (_paginationState.isFetchingStaticAssetsPage.value) return;
    if (page.value > 1 && !_paginationState.hasMoreStaticAssets.value) return;

    _paginationState.isFetchingStaticAssetsPage =
        TenantAdminStaticAssetsRepoBool.fromRaw(true, defaultValue: true);
    if (page.value > 1) {
      isStaticAssetsPageLoadingStreamValue.addValue(
        TenantAdminStaticAssetsRepoBool.fromRaw(true, defaultValue: true),
      );
    }
    try {
      final result = await fetchStaticAssetsPage(
        page: page,
        pageSize: pageSize,
      );
      if (page.value == 1) {
        _paginationState.cachedStaticAssets
          ..clear()
          ..addAll(result.items);
      } else {
        _paginationState.cachedStaticAssets.addAll(result.items);
      }
      _paginationState.currentStaticAssetsPage = page;
      _paginationState.hasMoreStaticAssets =
          TenantAdminStaticAssetsRepoBool.fromRaw(
        result.hasMore,
        defaultValue: result.hasMore,
      );
      hasMoreStaticAssetsStreamValue
          .addValue(_paginationState.hasMoreStaticAssets);
      staticAssetsStreamValue.addValue(
        List<TenantAdminStaticAsset>.unmodifiable(
          _paginationState.cachedStaticAssets,
        ),
      );
      staticAssetsErrorStreamValue.addValue(null);
    } catch (error) {
      staticAssetsErrorStreamValue.addValue(
        TenantAdminStaticAssetsRepoString.fromRaw(error.toString()),
      );
      if (page.value == 1) {
        staticAssetsStreamValue.addValue(const <TenantAdminStaticAsset>[]);
      }
    } finally {
      _paginationState.isFetchingStaticAssetsPage =
          TenantAdminStaticAssetsRepoBool.fromRaw(
        false,
        defaultValue: false,
      );
      isStaticAssetsPageLoadingStreamValue.addValue(
        TenantAdminStaticAssetsRepoBool.fromRaw(false, defaultValue: false),
      );
    }
  }

  @override
  void _resetStaticAssetsPagination() {
    _paginationState.cachedStaticAssets.clear();
    _paginationState.currentStaticAssetsPage =
        TenantAdminStaticAssetsRepoInt.fromRaw(0, defaultValue: 0);
    _paginationState.hasMoreStaticAssets =
        TenantAdminStaticAssetsRepoBool.fromRaw(
      true,
      defaultValue: true,
    );
    _paginationState.isFetchingStaticAssetsPage =
        TenantAdminStaticAssetsRepoBool.fromRaw(
      false,
      defaultValue: false,
    );
    hasMoreStaticAssetsStreamValue.addValue(
      TenantAdminStaticAssetsRepoBool.fromRaw(true, defaultValue: true),
    );
    isStaticAssetsPageLoadingStreamValue.addValue(
      TenantAdminStaticAssetsRepoBool.fromRaw(false, defaultValue: false),
    );
  }

  @override
  Future<void> _waitForStaticProfileTypesFetch() async {
    while (_paginationState.isFetchingStaticProfileTypesPage.value) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  @override
  Future<void> _fetchStaticProfileTypesPage({
    required TenantAdminStaticAssetsRepoInt page,
    required TenantAdminStaticAssetsRepoInt pageSize,
  }) async {
    if (_paginationState.isFetchingStaticProfileTypesPage.value) return;
    if (page.value > 1 && !_paginationState.hasMoreStaticProfileTypes.value) {
      return;
    }

    _paginationState.isFetchingStaticProfileTypesPage =
        TenantAdminStaticAssetsRepoBool.fromRaw(true, defaultValue: true);
    if (page.value > 1) {
      isStaticProfileTypesPageLoadingStreamValue.addValue(
        TenantAdminStaticAssetsRepoBool.fromRaw(true, defaultValue: true),
      );
    }
    try {
      final result = await fetchStaticProfileTypesPage(
        page: page,
        pageSize: pageSize,
      );
      if (page.value == 1) {
        _paginationState.cachedStaticProfileTypes
          ..clear()
          ..addAll(result.items);
      } else {
        _paginationState.cachedStaticProfileTypes.addAll(result.items);
      }
      _paginationState.currentStaticProfileTypesPage = page;
      _paginationState.hasMoreStaticProfileTypes =
          TenantAdminStaticAssetsRepoBool.fromRaw(
        result.hasMore,
        defaultValue: result.hasMore,
      );
      hasMoreStaticProfileTypesStreamValue
          .addValue(_paginationState.hasMoreStaticProfileTypes);
      staticProfileTypesStreamValue.addValue(
        List<TenantAdminStaticProfileTypeDefinition>.unmodifiable(
          _paginationState.cachedStaticProfileTypes,
        ),
      );
      staticProfileTypesErrorStreamValue.addValue(null);
    } catch (error) {
      staticProfileTypesErrorStreamValue.addValue(
        TenantAdminStaticAssetsRepoString.fromRaw(error.toString()),
      );
      if (page.value == 1) {
        staticProfileTypesStreamValue.addValue(
          const <TenantAdminStaticProfileTypeDefinition>[],
        );
      }
    } finally {
      _paginationState.isFetchingStaticProfileTypesPage =
          TenantAdminStaticAssetsRepoBool.fromRaw(
        false,
        defaultValue: false,
      );
      isStaticProfileTypesPageLoadingStreamValue.addValue(
        TenantAdminStaticAssetsRepoBool.fromRaw(false, defaultValue: false),
      );
    }
  }

  @override
  void _resetStaticProfileTypesPagination() {
    _paginationState.cachedStaticProfileTypes.clear();
    _paginationState.currentStaticProfileTypesPage =
        TenantAdminStaticAssetsRepoInt.fromRaw(0, defaultValue: 0);
    _paginationState.hasMoreStaticProfileTypes =
        TenantAdminStaticAssetsRepoBool.fromRaw(
      true,
      defaultValue: true,
    );
    _paginationState.isFetchingStaticProfileTypesPage =
        TenantAdminStaticAssetsRepoBool.fromRaw(
      false,
      defaultValue: false,
    );
    hasMoreStaticProfileTypesStreamValue.addValue(
      TenantAdminStaticAssetsRepoBool.fromRaw(true, defaultValue: true),
    );
    isStaticProfileTypesPageLoadingStreamValue.addValue(
      TenantAdminStaticAssetsRepoBool.fromRaw(false, defaultValue: false),
    );
  }
}

class _TenantAdminStaticAssetsPaginationState {
  final List<TenantAdminStaticAsset> cachedStaticAssets =
      <TenantAdminStaticAsset>[];
  final List<TenantAdminStaticProfileTypeDefinition> cachedStaticProfileTypes =
      <TenantAdminStaticProfileTypeDefinition>[];
  final StreamValue<List<TenantAdminStaticAsset>?> staticAssetsStreamValue =
      StreamValue<List<TenantAdminStaticAsset>?>();
  final StreamValue<TenantAdminStaticAssetsRepoBool>
      hasMoreStaticAssetsStreamValue =
      StreamValue<TenantAdminStaticAssetsRepoBool>(
    defaultValue: TenantAdminStaticAssetsRepoBool.fromRaw(
      true,
      defaultValue: true,
    ),
  );
  final StreamValue<TenantAdminStaticAssetsRepoBool>
      isStaticAssetsPageLoadingStreamValue =
      StreamValue<TenantAdminStaticAssetsRepoBool>(
    defaultValue: TenantAdminStaticAssetsRepoBool.fromRaw(
      false,
      defaultValue: false,
    ),
  );
  final StreamValue<TenantAdminStaticAssetsRepoString?>
      staticAssetsErrorStreamValue =
      StreamValue<TenantAdminStaticAssetsRepoString?>();
  final StreamValue<List<TenantAdminStaticProfileTypeDefinition>?>
      staticProfileTypesStreamValue =
      StreamValue<List<TenantAdminStaticProfileTypeDefinition>?>();
  final StreamValue<TenantAdminStaticAssetsRepoBool>
      hasMoreStaticProfileTypesStreamValue =
      StreamValue<TenantAdminStaticAssetsRepoBool>(
    defaultValue: TenantAdminStaticAssetsRepoBool.fromRaw(
      true,
      defaultValue: true,
    ),
  );
  final StreamValue<TenantAdminStaticAssetsRepoBool>
      isStaticProfileTypesPageLoadingStreamValue =
      StreamValue<TenantAdminStaticAssetsRepoBool>(
    defaultValue: TenantAdminStaticAssetsRepoBool.fromRaw(
      false,
      defaultValue: false,
    ),
  );
  final StreamValue<TenantAdminStaticAssetsRepoString?>
      staticProfileTypesErrorStreamValue =
      StreamValue<TenantAdminStaticAssetsRepoString?>();
  TenantAdminStaticAssetsRepoBool isFetchingStaticAssetsPage =
      TenantAdminStaticAssetsRepoBool.fromRaw(
    false,
    defaultValue: false,
  );
  TenantAdminStaticAssetsRepoBool hasMoreStaticAssets =
      TenantAdminStaticAssetsRepoBool.fromRaw(
    true,
    defaultValue: true,
  );
  TenantAdminStaticAssetsRepoInt currentStaticAssetsPage =
      TenantAdminStaticAssetsRepoInt.fromRaw(
    0,
    defaultValue: 0,
  );
  TenantAdminStaticAssetsRepoBool isFetchingStaticProfileTypesPage =
      TenantAdminStaticAssetsRepoBool.fromRaw(
    false,
    defaultValue: false,
  );
  TenantAdminStaticAssetsRepoBool hasMoreStaticProfileTypes =
      TenantAdminStaticAssetsRepoBool.fromRaw(
    true,
    defaultValue: true,
  );
  TenantAdminStaticAssetsRepoInt currentStaticProfileTypesPage =
      TenantAdminStaticAssetsRepoInt.fromRaw(
    0,
    defaultValue: 0,
  );
}
