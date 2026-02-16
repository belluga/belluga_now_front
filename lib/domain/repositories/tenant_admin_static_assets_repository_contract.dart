import 'dart:math' as math;

import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_asset.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class TenantAdminStaticAssetsRepositoryContract {
  static final Expando<_TenantAdminStaticAssetsPaginationState>
      _paginationStateByRepository =
      Expando<_TenantAdminStaticAssetsPaginationState>();

  _TenantAdminStaticAssetsPaginationState get _paginationState =>
      _paginationStateByRepository[this] ??=
          _TenantAdminStaticAssetsPaginationState();

  StreamValue<List<TenantAdminStaticAsset>?> get staticAssetsStreamValue =>
      _paginationState.staticAssetsStreamValue;

  StreamValue<bool> get hasMoreStaticAssetsStreamValue =>
      _paginationState.hasMoreStaticAssetsStreamValue;

  StreamValue<bool> get isStaticAssetsPageLoadingStreamValue =>
      _paginationState.isStaticAssetsPageLoadingStreamValue;

  StreamValue<String?> get staticAssetsErrorStreamValue =>
      _paginationState.staticAssetsErrorStreamValue;

  Future<void> loadStaticAssets({int pageSize = 20}) async {
    await _waitForStaticAssetsFetch();
    _resetStaticAssetsPagination();
    staticAssetsStreamValue.addValue(null);
    await _fetchStaticAssetsPage(page: 1, pageSize: pageSize);
  }

  Future<void> loadNextStaticAssetsPage({int pageSize = 20}) async {
    if (_paginationState.isFetchingStaticAssetsPage ||
        !_paginationState.hasMoreStaticAssets) {
      return;
    }
    await _fetchStaticAssetsPage(
      page: _paginationState.currentStaticAssetsPage + 1,
      pageSize: pageSize,
    );
  }

  void resetStaticAssetsState() {
    _resetStaticAssetsPagination();
    staticAssetsStreamValue.addValue(null);
    staticAssetsErrorStreamValue.addValue(null);
  }

  Future<List<TenantAdminStaticAsset>> fetchStaticAssets();
  Future<TenantAdminPagedResult<TenantAdminStaticAsset>> fetchStaticAssetsPage({
    required int page,
    required int pageSize,
  }) async {
    final assets = await fetchStaticAssets();
    if (page <= 0 || pageSize <= 0) {
      return const TenantAdminPagedResult<TenantAdminStaticAsset>(
        items: <TenantAdminStaticAsset>[],
        hasMore: false,
      );
    }
    final startIndex = (page - 1) * pageSize;
    if (startIndex >= assets.length) {
      return const TenantAdminPagedResult<TenantAdminStaticAsset>(
        items: <TenantAdminStaticAsset>[],
        hasMore: false,
      );
    }
    final endIndex = math.min(startIndex + pageSize, assets.length);
    return TenantAdminPagedResult<TenantAdminStaticAsset>(
      items: assets.sublist(startIndex, endIndex),
      hasMore: endIndex < assets.length,
    );
  }

  Future<TenantAdminStaticAsset> fetchStaticAsset(String assetId);

  Future<TenantAdminStaticAsset> createStaticAsset({
    required String profileType,
    required String displayName,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm> taxonomyTerms = const [],
    List<String> tags = const [],
    String? bio,
    String? content,
    String? avatarUrl,
    String? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  });

  Future<TenantAdminStaticAsset> updateStaticAsset({
    required String assetId,
    String? profileType,
    String? displayName,
    String? slug,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm>? taxonomyTerms,
    List<String>? tags,
    String? bio,
    String? content,
    String? avatarUrl,
    String? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  });

  Future<void> deleteStaticAsset(String assetId);

  Future<TenantAdminStaticAsset> restoreStaticAsset(String assetId);

  Future<void> forceDeleteStaticAsset(String assetId);

  StreamValue<List<TenantAdminStaticProfileTypeDefinition>?>
      get staticProfileTypesStreamValue =>
          _paginationState.staticProfileTypesStreamValue;

  StreamValue<bool> get hasMoreStaticProfileTypesStreamValue =>
      _paginationState.hasMoreStaticProfileTypesStreamValue;

  StreamValue<bool> get isStaticProfileTypesPageLoadingStreamValue =>
      _paginationState.isStaticProfileTypesPageLoadingStreamValue;

  StreamValue<String?> get staticProfileTypesErrorStreamValue =>
      _paginationState.staticProfileTypesErrorStreamValue;

  Future<void> loadStaticProfileTypes({int pageSize = 20}) async {
    await _waitForStaticProfileTypesFetch();
    _resetStaticProfileTypesPagination();
    staticProfileTypesStreamValue.addValue(null);
    await _fetchStaticProfileTypesPage(page: 1, pageSize: pageSize);
  }

  Future<void> loadNextStaticProfileTypesPage({int pageSize = 20}) async {
    if (_paginationState.isFetchingStaticProfileTypesPage ||
        !_paginationState.hasMoreStaticProfileTypes) {
      return;
    }
    await _fetchStaticProfileTypesPage(
      page: _paginationState.currentStaticProfileTypesPage + 1,
      pageSize: pageSize,
    );
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
    required int page,
    required int pageSize,
  }) async {
    final profileTypes = await fetchStaticProfileTypes();
    if (page <= 0 || pageSize <= 0) {
      return const TenantAdminPagedResult<
          TenantAdminStaticProfileTypeDefinition>(
        items: <TenantAdminStaticProfileTypeDefinition>[],
        hasMore: false,
      );
    }
    final startIndex = (page - 1) * pageSize;
    if (startIndex >= profileTypes.length) {
      return const TenantAdminPagedResult<
          TenantAdminStaticProfileTypeDefinition>(
        items: <TenantAdminStaticProfileTypeDefinition>[],
        hasMore: false,
      );
    }
    final endIndex = math.min(startIndex + pageSize, profileTypes.length);
    return TenantAdminPagedResult<TenantAdminStaticProfileTypeDefinition>(
      items: profileTypes.sublist(startIndex, endIndex),
      hasMore: endIndex < profileTypes.length,
    );
  }

  Future<TenantAdminStaticProfileTypeDefinition> createStaticProfileType({
    required String type,
    required String label,
    List<String> allowedTaxonomies = const [],
    required TenantAdminStaticProfileTypeCapabilities capabilities,
  });

  Future<TenantAdminStaticProfileTypeDefinition> updateStaticProfileType({
    required String type,
    String? newType,
    String? label,
    List<String>? allowedTaxonomies,
    TenantAdminStaticProfileTypeCapabilities? capabilities,
  });

  Future<void> deleteStaticProfileType(String type);

  Future<void> _waitForStaticAssetsFetch() async {
    while (_paginationState.isFetchingStaticAssetsPage) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchStaticAssetsPage({
    required int page,
    required int pageSize,
  }) async {
    if (_paginationState.isFetchingStaticAssetsPage) return;
    if (page > 1 && !_paginationState.hasMoreStaticAssets) return;

    _paginationState.isFetchingStaticAssetsPage = true;
    if (page > 1) {
      isStaticAssetsPageLoadingStreamValue.addValue(true);
    }
    try {
      final result = await fetchStaticAssetsPage(
        page: page,
        pageSize: pageSize,
      );
      if (page == 1) {
        _paginationState.cachedStaticAssets
          ..clear()
          ..addAll(result.items);
      } else {
        _paginationState.cachedStaticAssets.addAll(result.items);
      }
      _paginationState.currentStaticAssetsPage = page;
      _paginationState.hasMoreStaticAssets = result.hasMore;
      hasMoreStaticAssetsStreamValue
          .addValue(_paginationState.hasMoreStaticAssets);
      staticAssetsStreamValue.addValue(
        List<TenantAdminStaticAsset>.unmodifiable(
          _paginationState.cachedStaticAssets,
        ),
      );
      staticAssetsErrorStreamValue.addValue(null);
    } catch (error) {
      staticAssetsErrorStreamValue.addValue(error.toString());
      if (page == 1) {
        staticAssetsStreamValue.addValue(const <TenantAdminStaticAsset>[]);
      }
    } finally {
      _paginationState.isFetchingStaticAssetsPage = false;
      isStaticAssetsPageLoadingStreamValue.addValue(false);
    }
  }

  void _resetStaticAssetsPagination() {
    _paginationState.cachedStaticAssets.clear();
    _paginationState.currentStaticAssetsPage = 0;
    _paginationState.hasMoreStaticAssets = true;
    _paginationState.isFetchingStaticAssetsPage = false;
    hasMoreStaticAssetsStreamValue.addValue(true);
    isStaticAssetsPageLoadingStreamValue.addValue(false);
  }

  Future<void> _waitForStaticProfileTypesFetch() async {
    while (_paginationState.isFetchingStaticProfileTypesPage) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchStaticProfileTypesPage({
    required int page,
    required int pageSize,
  }) async {
    if (_paginationState.isFetchingStaticProfileTypesPage) return;
    if (page > 1 && !_paginationState.hasMoreStaticProfileTypes) return;

    _paginationState.isFetchingStaticProfileTypesPage = true;
    if (page > 1) {
      isStaticProfileTypesPageLoadingStreamValue.addValue(true);
    }
    try {
      final result = await fetchStaticProfileTypesPage(
        page: page,
        pageSize: pageSize,
      );
      if (page == 1) {
        _paginationState.cachedStaticProfileTypes
          ..clear()
          ..addAll(result.items);
      } else {
        _paginationState.cachedStaticProfileTypes.addAll(result.items);
      }
      _paginationState.currentStaticProfileTypesPage = page;
      _paginationState.hasMoreStaticProfileTypes = result.hasMore;
      hasMoreStaticProfileTypesStreamValue
          .addValue(_paginationState.hasMoreStaticProfileTypes);
      staticProfileTypesStreamValue.addValue(
        List<TenantAdminStaticProfileTypeDefinition>.unmodifiable(
          _paginationState.cachedStaticProfileTypes,
        ),
      );
      staticProfileTypesErrorStreamValue.addValue(null);
    } catch (error) {
      staticProfileTypesErrorStreamValue.addValue(error.toString());
      if (page == 1) {
        staticProfileTypesStreamValue.addValue(
          const <TenantAdminStaticProfileTypeDefinition>[],
        );
      }
    } finally {
      _paginationState.isFetchingStaticProfileTypesPage = false;
      isStaticProfileTypesPageLoadingStreamValue.addValue(false);
    }
  }

  void _resetStaticProfileTypesPagination() {
    _paginationState.cachedStaticProfileTypes.clear();
    _paginationState.currentStaticProfileTypesPage = 0;
    _paginationState.hasMoreStaticProfileTypes = true;
    _paginationState.isFetchingStaticProfileTypesPage = false;
    hasMoreStaticProfileTypesStreamValue.addValue(true);
    isStaticProfileTypesPageLoadingStreamValue.addValue(false);
  }
}

mixin TenantAdminStaticAssetsPaginationMixin
    implements TenantAdminStaticAssetsRepositoryContract {
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
  StreamValue<bool> get hasMoreStaticAssetsStreamValue =>
      _paginationState.hasMoreStaticAssetsStreamValue;

  @override
  StreamValue<bool> get isStaticAssetsPageLoadingStreamValue =>
      _paginationState.isStaticAssetsPageLoadingStreamValue;

  @override
  StreamValue<String?> get staticAssetsErrorStreamValue =>
      _paginationState.staticAssetsErrorStreamValue;

  @override
  Future<void> loadStaticAssets({int pageSize = 20}) async {
    await _waitForStaticAssetsFetch();
    _resetStaticAssetsPagination();
    staticAssetsStreamValue.addValue(null);
    await _fetchStaticAssetsPage(page: 1, pageSize: pageSize);
  }

  @override
  Future<void> loadNextStaticAssetsPage({int pageSize = 20}) async {
    if (_paginationState.isFetchingStaticAssetsPage ||
        !_paginationState.hasMoreStaticAssets) {
      return;
    }
    await _fetchStaticAssetsPage(
      page: _paginationState.currentStaticAssetsPage + 1,
      pageSize: pageSize,
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
  StreamValue<bool> get hasMoreStaticProfileTypesStreamValue =>
      _paginationState.hasMoreStaticProfileTypesStreamValue;

  @override
  StreamValue<bool> get isStaticProfileTypesPageLoadingStreamValue =>
      _paginationState.isStaticProfileTypesPageLoadingStreamValue;

  @override
  StreamValue<String?> get staticProfileTypesErrorStreamValue =>
      _paginationState.staticProfileTypesErrorStreamValue;

  @override
  Future<void> loadStaticProfileTypes({int pageSize = 20}) async {
    await _waitForStaticProfileTypesFetch();
    _resetStaticProfileTypesPagination();
    staticProfileTypesStreamValue.addValue(null);
    await _fetchStaticProfileTypesPage(page: 1, pageSize: pageSize);
  }

  @override
  Future<void> loadNextStaticProfileTypesPage({int pageSize = 20}) async {
    if (_paginationState.isFetchingStaticProfileTypesPage ||
        !_paginationState.hasMoreStaticProfileTypes) {
      return;
    }
    await _fetchStaticProfileTypesPage(
      page: _paginationState.currentStaticProfileTypesPage + 1,
      pageSize: pageSize,
    );
  }

  @override
  void resetStaticProfileTypesState() {
    _resetStaticProfileTypesPagination();
    staticProfileTypesStreamValue.addValue(null);
    staticProfileTypesErrorStreamValue.addValue(null);
  }

  @override
  Future<void> _waitForStaticAssetsFetch() async {
    while (_paginationState.isFetchingStaticAssetsPage) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  @override
  Future<void> _fetchStaticAssetsPage({
    required int page,
    required int pageSize,
  }) async {
    if (_paginationState.isFetchingStaticAssetsPage) return;
    if (page > 1 && !_paginationState.hasMoreStaticAssets) return;

    _paginationState.isFetchingStaticAssetsPage = true;
    if (page > 1) {
      isStaticAssetsPageLoadingStreamValue.addValue(true);
    }
    try {
      final result = await fetchStaticAssetsPage(
        page: page,
        pageSize: pageSize,
      );
      if (page == 1) {
        _paginationState.cachedStaticAssets
          ..clear()
          ..addAll(result.items);
      } else {
        _paginationState.cachedStaticAssets.addAll(result.items);
      }
      _paginationState.currentStaticAssetsPage = page;
      _paginationState.hasMoreStaticAssets = result.hasMore;
      hasMoreStaticAssetsStreamValue
          .addValue(_paginationState.hasMoreStaticAssets);
      staticAssetsStreamValue.addValue(
        List<TenantAdminStaticAsset>.unmodifiable(
          _paginationState.cachedStaticAssets,
        ),
      );
      staticAssetsErrorStreamValue.addValue(null);
    } catch (error) {
      staticAssetsErrorStreamValue.addValue(error.toString());
      if (page == 1) {
        staticAssetsStreamValue.addValue(const <TenantAdminStaticAsset>[]);
      }
    } finally {
      _paginationState.isFetchingStaticAssetsPage = false;
      isStaticAssetsPageLoadingStreamValue.addValue(false);
    }
  }

  @override
  void _resetStaticAssetsPagination() {
    _paginationState.cachedStaticAssets.clear();
    _paginationState.currentStaticAssetsPage = 0;
    _paginationState.hasMoreStaticAssets = true;
    _paginationState.isFetchingStaticAssetsPage = false;
    hasMoreStaticAssetsStreamValue.addValue(true);
    isStaticAssetsPageLoadingStreamValue.addValue(false);
  }

  @override
  Future<void> _waitForStaticProfileTypesFetch() async {
    while (_paginationState.isFetchingStaticProfileTypesPage) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  @override
  Future<void> _fetchStaticProfileTypesPage({
    required int page,
    required int pageSize,
  }) async {
    if (_paginationState.isFetchingStaticProfileTypesPage) return;
    if (page > 1 && !_paginationState.hasMoreStaticProfileTypes) return;

    _paginationState.isFetchingStaticProfileTypesPage = true;
    if (page > 1) {
      isStaticProfileTypesPageLoadingStreamValue.addValue(true);
    }
    try {
      final result = await fetchStaticProfileTypesPage(
        page: page,
        pageSize: pageSize,
      );
      if (page == 1) {
        _paginationState.cachedStaticProfileTypes
          ..clear()
          ..addAll(result.items);
      } else {
        _paginationState.cachedStaticProfileTypes.addAll(result.items);
      }
      _paginationState.currentStaticProfileTypesPage = page;
      _paginationState.hasMoreStaticProfileTypes = result.hasMore;
      hasMoreStaticProfileTypesStreamValue
          .addValue(_paginationState.hasMoreStaticProfileTypes);
      staticProfileTypesStreamValue.addValue(
        List<TenantAdminStaticProfileTypeDefinition>.unmodifiable(
          _paginationState.cachedStaticProfileTypes,
        ),
      );
      staticProfileTypesErrorStreamValue.addValue(null);
    } catch (error) {
      staticProfileTypesErrorStreamValue.addValue(error.toString());
      if (page == 1) {
        staticProfileTypesStreamValue.addValue(
          const <TenantAdminStaticProfileTypeDefinition>[],
        );
      }
    } finally {
      _paginationState.isFetchingStaticProfileTypesPage = false;
      isStaticProfileTypesPageLoadingStreamValue.addValue(false);
    }
  }

  @override
  void _resetStaticProfileTypesPagination() {
    _paginationState.cachedStaticProfileTypes.clear();
    _paginationState.currentStaticProfileTypesPage = 0;
    _paginationState.hasMoreStaticProfileTypes = true;
    _paginationState.isFetchingStaticProfileTypesPage = false;
    hasMoreStaticProfileTypesStreamValue.addValue(true);
    isStaticProfileTypesPageLoadingStreamValue.addValue(false);
  }
}

class _TenantAdminStaticAssetsPaginationState {
  final List<TenantAdminStaticAsset> cachedStaticAssets =
      <TenantAdminStaticAsset>[];
  final List<TenantAdminStaticProfileTypeDefinition> cachedStaticProfileTypes =
      <TenantAdminStaticProfileTypeDefinition>[];
  final StreamValue<List<TenantAdminStaticAsset>?> staticAssetsStreamValue =
      StreamValue<List<TenantAdminStaticAsset>?>();
  final StreamValue<bool> hasMoreStaticAssetsStreamValue =
      StreamValue<bool>(defaultValue: true);
  final StreamValue<bool> isStaticAssetsPageLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> staticAssetsErrorStreamValue =
      StreamValue<String?>();
  final StreamValue<List<TenantAdminStaticProfileTypeDefinition>?>
      staticProfileTypesStreamValue =
      StreamValue<List<TenantAdminStaticProfileTypeDefinition>?>();
  final StreamValue<bool> hasMoreStaticProfileTypesStreamValue =
      StreamValue<bool>(defaultValue: true);
  final StreamValue<bool> isStaticProfileTypesPageLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> staticProfileTypesErrorStreamValue =
      StreamValue<String?>();
  bool isFetchingStaticAssetsPage = false;
  bool hasMoreStaticAssets = true;
  int currentStaticAssetsPage = 0;
  bool isFetchingStaticProfileTypesPage = false;
  bool hasMoreStaticProfileTypes = true;
  int currentStaticProfileTypesPage = 0;
}
