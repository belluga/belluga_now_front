import 'dart:math' as math;

import 'package:belluga_now/domain/tenant_admin/tenant_admin_organization.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class TenantAdminOrganizationsRepositoryContract {
  static final Expando<_TenantAdminOrganizationsPaginationState>
      _paginationStateByRepository =
      Expando<_TenantAdminOrganizationsPaginationState>();

  _TenantAdminOrganizationsPaginationState get _paginationState =>
      _paginationStateByRepository[this] ??=
          _TenantAdminOrganizationsPaginationState();

  StreamValue<List<TenantAdminOrganization>?> get organizationsStreamValue =>
      _paginationState.organizationsStreamValue;

  StreamValue<bool> get hasMoreOrganizationsStreamValue =>
      _paginationState.hasMoreOrganizationsStreamValue;

  StreamValue<bool> get isOrganizationsPageLoadingStreamValue =>
      _paginationState.isOrganizationsPageLoadingStreamValue;

  StreamValue<String?> get organizationsErrorStreamValue =>
      _paginationState.organizationsErrorStreamValue;

  Future<void> loadOrganizations({int pageSize = 20}) async {
    await _waitForOrganizationsFetch();
    _resetOrganizationsPagination();
    organizationsStreamValue.addValue(null);
    await _fetchOrganizationsPage(page: 1, pageSize: pageSize);
  }

  Future<void> loadNextOrganizationsPage({int pageSize = 20}) async {
    if (_paginationState.isFetchingOrganizationsPage ||
        !_paginationState.hasMoreOrganizations) {
      return;
    }
    await _fetchOrganizationsPage(
      page: _paginationState.currentOrganizationsPage + 1,
      pageSize: pageSize,
    );
  }

  void resetOrganizationsState() {
    _resetOrganizationsPagination();
    organizationsStreamValue.addValue(null);
    organizationsErrorStreamValue.addValue(null);
  }

  Future<List<TenantAdminOrganization>> fetchOrganizations();
  Future<TenantAdminPagedResult<TenantAdminOrganization>>
      fetchOrganizationsPage({
    required int page,
    required int pageSize,
  }) async {
    final organizations = await fetchOrganizations();
    if (page <= 0 || pageSize <= 0) {
      return const TenantAdminPagedResult<TenantAdminOrganization>(
        items: <TenantAdminOrganization>[],
        hasMore: false,
      );
    }
    final startIndex = (page - 1) * pageSize;
    if (startIndex >= organizations.length) {
      return const TenantAdminPagedResult<TenantAdminOrganization>(
        items: <TenantAdminOrganization>[],
        hasMore: false,
      );
    }
    final endIndex = math.min(startIndex + pageSize, organizations.length);
    return TenantAdminPagedResult<TenantAdminOrganization>(
      items: organizations.sublist(startIndex, endIndex),
      hasMore: endIndex < organizations.length,
    );
  }

  Future<TenantAdminOrganization> fetchOrganization(String organizationId);
  Future<TenantAdminOrganization> createOrganization({
    required String name,
    String? description,
  });
  Future<TenantAdminOrganization> updateOrganization({
    required String organizationId,
    String? name,
    String? slug,
    String? description,
  });
  Future<void> deleteOrganization(String organizationId);
  Future<TenantAdminOrganization> restoreOrganization(String organizationId);
  Future<void> forceDeleteOrganization(String organizationId);

  Future<void> _waitForOrganizationsFetch() async {
    while (_paginationState.isFetchingOrganizationsPage) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchOrganizationsPage({
    required int page,
    required int pageSize,
  }) async {
    if (_paginationState.isFetchingOrganizationsPage) return;
    if (page > 1 && !_paginationState.hasMoreOrganizations) return;

    _paginationState.isFetchingOrganizationsPage = true;
    if (page > 1) {
      isOrganizationsPageLoadingStreamValue.addValue(true);
    }
    try {
      final result = await fetchOrganizationsPage(
        page: page,
        pageSize: pageSize,
      );
      if (page == 1) {
        _paginationState.cachedOrganizations
          ..clear()
          ..addAll(result.items);
      } else {
        _paginationState.cachedOrganizations.addAll(result.items);
      }
      _paginationState.currentOrganizationsPage = page;
      _paginationState.hasMoreOrganizations = result.hasMore;
      hasMoreOrganizationsStreamValue
          .addValue(_paginationState.hasMoreOrganizations);
      organizationsStreamValue.addValue(
        List<TenantAdminOrganization>.unmodifiable(
          _paginationState.cachedOrganizations,
        ),
      );
      organizationsErrorStreamValue.addValue(null);
    } catch (error) {
      organizationsErrorStreamValue.addValue(error.toString());
      if (page == 1) {
        organizationsStreamValue.addValue(const <TenantAdminOrganization>[]);
      }
    } finally {
      _paginationState.isFetchingOrganizationsPage = false;
      isOrganizationsPageLoadingStreamValue.addValue(false);
    }
  }

  void _resetOrganizationsPagination() {
    _paginationState.cachedOrganizations.clear();
    _paginationState.currentOrganizationsPage = 0;
    _paginationState.hasMoreOrganizations = true;
    _paginationState.isFetchingOrganizationsPage = false;
    hasMoreOrganizationsStreamValue.addValue(true);
    isOrganizationsPageLoadingStreamValue.addValue(false);
  }
}

mixin TenantAdminOrganizationsPaginationMixin
    implements TenantAdminOrganizationsRepositoryContract {
  static final Expando<_TenantAdminOrganizationsPaginationState>
      _paginationStateByRepository =
      Expando<_TenantAdminOrganizationsPaginationState>();

  _TenantAdminOrganizationsPaginationState get _mixinPaginationState =>
      _paginationStateByRepository[this] ??=
          _TenantAdminOrganizationsPaginationState();

  @override
  StreamValue<List<TenantAdminOrganization>?> get organizationsStreamValue =>
      _mixinPaginationState.organizationsStreamValue;

  @override
  StreamValue<bool> get hasMoreOrganizationsStreamValue =>
      _mixinPaginationState.hasMoreOrganizationsStreamValue;

  @override
  StreamValue<bool> get isOrganizationsPageLoadingStreamValue =>
      _mixinPaginationState.isOrganizationsPageLoadingStreamValue;

  @override
  StreamValue<String?> get organizationsErrorStreamValue =>
      _mixinPaginationState.organizationsErrorStreamValue;

  @override
  Future<void> loadOrganizations({int pageSize = 20}) async {
    await _waitForOrganizationsFetchMixin();
    _resetOrganizationsPaginationMixin();
    organizationsStreamValue.addValue(null);
    await _fetchOrganizationsPageMixin(page: 1, pageSize: pageSize);
  }

  @override
  Future<void> loadNextOrganizationsPage({int pageSize = 20}) async {
    if (_mixinPaginationState.isFetchingOrganizationsPage ||
        !_mixinPaginationState.hasMoreOrganizations) {
      return;
    }
    await _fetchOrganizationsPageMixin(
      page: _mixinPaginationState.currentOrganizationsPage + 1,
      pageSize: pageSize,
    );
  }

  @override
  void resetOrganizationsState() {
    _resetOrganizationsPaginationMixin();
    organizationsStreamValue.addValue(null);
    organizationsErrorStreamValue.addValue(null);
  }

  Future<void> _waitForOrganizationsFetchMixin() async {
    while (_mixinPaginationState.isFetchingOrganizationsPage) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchOrganizationsPageMixin({
    required int page,
    required int pageSize,
  }) async {
    if (_mixinPaginationState.isFetchingOrganizationsPage) return;
    if (page > 1 && !_mixinPaginationState.hasMoreOrganizations) return;

    _mixinPaginationState.isFetchingOrganizationsPage = true;
    if (page > 1) {
      isOrganizationsPageLoadingStreamValue.addValue(true);
    }
    try {
      final result = await fetchOrganizationsPage(
        page: page,
        pageSize: pageSize,
      );
      if (page == 1) {
        _mixinPaginationState.cachedOrganizations
          ..clear()
          ..addAll(result.items);
      } else {
        _mixinPaginationState.cachedOrganizations.addAll(result.items);
      }
      _mixinPaginationState.currentOrganizationsPage = page;
      _mixinPaginationState.hasMoreOrganizations = result.hasMore;
      hasMoreOrganizationsStreamValue
          .addValue(_mixinPaginationState.hasMoreOrganizations);
      organizationsStreamValue.addValue(
        List<TenantAdminOrganization>.unmodifiable(
          _mixinPaginationState.cachedOrganizations,
        ),
      );
      organizationsErrorStreamValue.addValue(null);
    } catch (error) {
      organizationsErrorStreamValue.addValue(error.toString());
      if (page == 1) {
        organizationsStreamValue.addValue(const <TenantAdminOrganization>[]);
      }
    } finally {
      _mixinPaginationState.isFetchingOrganizationsPage = false;
      isOrganizationsPageLoadingStreamValue.addValue(false);
    }
  }

  void _resetOrganizationsPaginationMixin() {
    _mixinPaginationState.cachedOrganizations.clear();
    _mixinPaginationState.currentOrganizationsPage = 0;
    _mixinPaginationState.hasMoreOrganizations = true;
    _mixinPaginationState.isFetchingOrganizationsPage = false;
    hasMoreOrganizationsStreamValue.addValue(true);
    isOrganizationsPageLoadingStreamValue.addValue(false);
  }
}

class _TenantAdminOrganizationsPaginationState {
  final List<TenantAdminOrganization> cachedOrganizations =
      <TenantAdminOrganization>[];
  final StreamValue<List<TenantAdminOrganization>?> organizationsStreamValue =
      StreamValue<List<TenantAdminOrganization>?>();
  final StreamValue<bool> hasMoreOrganizationsStreamValue =
      StreamValue<bool>(defaultValue: true);
  final StreamValue<bool> isOrganizationsPageLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> organizationsErrorStreamValue =
      StreamValue<String?>();
  bool isFetchingOrganizationsPage = false;
  bool hasMoreOrganizations = true;
  int currentOrganizationsPage = 0;
}
