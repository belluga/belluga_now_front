import 'dart:math' as math;

import 'package:belluga_now/domain/repositories/value_objects/tenant_admin_organizations_repository_contract_values.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_organization.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:stream_value/core/stream_value.dart';

typedef TenantAdminOrganizationsRepositoryContractPrimString
    = TenantAdminOrganizationsRepositoryContractTextValue;
typedef TenantAdminOrganizationsRepositoryContractPrimInt
    = TenantAdminOrganizationsRepositoryContractIntValue;
typedef TenantAdminOrganizationsRepositoryContractPrimBool
    = TenantAdminOrganizationsRepositoryContractBoolValue;

abstract class TenantAdminOrganizationsRepositoryContract {
  static final Expando<_TenantAdminOrganizationsPaginationState>
      _paginationStateByRepository =
      Expando<_TenantAdminOrganizationsPaginationState>();

  _TenantAdminOrganizationsPaginationState get _paginationState =>
      _paginationStateByRepository[this] ??=
          _TenantAdminOrganizationsPaginationState();

  StreamValue<List<TenantAdminOrganization>?> get organizationsStreamValue =>
      _paginationState.organizationsStreamValue;

  StreamValue<TenantAdminOrganizationsRepositoryContractPrimBool>
      get hasMoreOrganizationsStreamValue =>
          _paginationState.hasMoreOrganizationsStreamValue;

  StreamValue<TenantAdminOrganizationsRepositoryContractPrimBool>
      get isOrganizationsPageLoadingStreamValue =>
          _paginationState.isOrganizationsPageLoadingStreamValue;

  StreamValue<TenantAdminOrganizationsRepositoryContractPrimString?>
      get organizationsErrorStreamValue =>
          _paginationState.organizationsErrorStreamValue;

  Future<void> loadOrganizations({
    TenantAdminOrganizationsRepositoryContractPrimInt? pageSize,
  }) async {
    final effectivePageSize = pageSize ??
        TenantAdminOrganizationsRepositoryContractPrimInt.fromRaw(
          20,
          defaultValue: 20,
        );
    await _waitForOrganizationsFetch();
    _resetOrganizationsPagination();
    organizationsStreamValue.addValue(null);
    await _fetchOrganizationsPage(
      page: TenantAdminOrganizationsRepositoryContractPrimInt.fromRaw(
        1,
        defaultValue: 1,
      ),
      pageSize: effectivePageSize,
    );
  }

  Future<void> loadNextOrganizationsPage({
    TenantAdminOrganizationsRepositoryContractPrimInt? pageSize,
  }) async {
    final effectivePageSize = pageSize ??
        TenantAdminOrganizationsRepositoryContractPrimInt.fromRaw(
          20,
          defaultValue: 20,
        );
    if (_paginationState.isFetchingOrganizationsPage.value ||
        !_paginationState.hasMoreOrganizations.value) {
      return;
    }
    await _fetchOrganizationsPage(
      page: TenantAdminOrganizationsRepositoryContractPrimInt.fromRaw(
        _paginationState.currentOrganizationsPage.value + 1,
        defaultValue: 1,
      ),
      pageSize: effectivePageSize,
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
    required TenantAdminOrganizationsRepositoryContractPrimInt page,
    required TenantAdminOrganizationsRepositoryContractPrimInt pageSize,
  }) async {
    final organizations = await fetchOrganizations();
    if (page.value <= 0 || pageSize.value <= 0) {
      return TenantAdminPagedResult<TenantAdminOrganization>(
        items: <TenantAdminOrganization>[],
        hasMore: false,
      );
    }
    final startIndex = (page.value - 1) * pageSize.value;
    if (startIndex >= organizations.length) {
      return TenantAdminPagedResult<TenantAdminOrganization>(
        items: <TenantAdminOrganization>[],
        hasMore: false,
      );
    }
    final endIndex =
        math.min(startIndex + pageSize.value, organizations.length);
    return TenantAdminPagedResult<TenantAdminOrganization>(
      items: organizations.sublist(startIndex, endIndex),
      hasMore: endIndex < organizations.length,
    );
  }

  Future<TenantAdminOrganization> fetchOrganization(
      TenantAdminOrganizationsRepositoryContractPrimString organizationId);
  Future<TenantAdminOrganization> createOrganization({
    required TenantAdminOrganizationsRepositoryContractPrimString name,
    TenantAdminOrganizationsRepositoryContractPrimString? description,
  });
  Future<TenantAdminOrganization> updateOrganization({
    required TenantAdminOrganizationsRepositoryContractPrimString
        organizationId,
    TenantAdminOrganizationsRepositoryContractPrimString? name,
    TenantAdminOrganizationsRepositoryContractPrimString? slug,
    TenantAdminOrganizationsRepositoryContractPrimString? description,
  });
  Future<void> deleteOrganization(
      TenantAdminOrganizationsRepositoryContractPrimString organizationId);
  Future<TenantAdminOrganization> restoreOrganization(
      TenantAdminOrganizationsRepositoryContractPrimString organizationId);
  Future<void> forceDeleteOrganization(
      TenantAdminOrganizationsRepositoryContractPrimString organizationId);

  Future<void> _waitForOrganizationsFetch() async {
    while (_paginationState.isFetchingOrganizationsPage.value) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchOrganizationsPage({
    required TenantAdminOrganizationsRepositoryContractPrimInt page,
    required TenantAdminOrganizationsRepositoryContractPrimInt pageSize,
  }) async {
    if (_paginationState.isFetchingOrganizationsPage.value) return;
    if (page.value > 1 && !_paginationState.hasMoreOrganizations.value) return;

    _paginationState.isFetchingOrganizationsPage =
        TenantAdminOrganizationsRepositoryContractPrimBool.fromRaw(
      true,
      defaultValue: true,
    );
    if (page.value > 1) {
      isOrganizationsPageLoadingStreamValue.addValue(
        TenantAdminOrganizationsRepositoryContractPrimBool.fromRaw(
          true,
          defaultValue: true,
        ),
      );
    }
    try {
      final result = await fetchOrganizationsPage(
        page: page,
        pageSize: pageSize,
      );
      if (page.value == 1) {
        _paginationState.cachedOrganizations
          ..clear()
          ..addAll(result.items);
      } else {
        _paginationState.cachedOrganizations.addAll(result.items);
      }
      _paginationState.currentOrganizationsPage = page;
      _paginationState.hasMoreOrganizations =
          TenantAdminOrganizationsRepositoryContractPrimBool.fromRaw(
        result.hasMore,
        defaultValue: true,
      );
      hasMoreOrganizationsStreamValue
          .addValue(_paginationState.hasMoreOrganizations);
      organizationsStreamValue.addValue(
        List<TenantAdminOrganization>.unmodifiable(
          _paginationState.cachedOrganizations,
        ),
      );
      organizationsErrorStreamValue.addValue(null);
    } catch (error) {
      organizationsErrorStreamValue.addValue(
        TenantAdminOrganizationsRepositoryContractPrimString.fromRaw(
          error.toString(),
        ),
      );
      if (page.value == 1) {
        organizationsStreamValue.addValue(const <TenantAdminOrganization>[]);
      }
    } finally {
      _paginationState.isFetchingOrganizationsPage =
          TenantAdminOrganizationsRepositoryContractPrimBool.fromRaw(
        false,
        defaultValue: false,
      );
      isOrganizationsPageLoadingStreamValue.addValue(
        TenantAdminOrganizationsRepositoryContractPrimBool.fromRaw(
          false,
          defaultValue: false,
        ),
      );
    }
  }

  void _resetOrganizationsPagination() {
    _paginationState.cachedOrganizations.clear();
    _paginationState.currentOrganizationsPage =
        TenantAdminOrganizationsRepositoryContractPrimInt.fromRaw(
      0,
      defaultValue: 0,
    );
    _paginationState.hasMoreOrganizations =
        TenantAdminOrganizationsRepositoryContractPrimBool.fromRaw(
      true,
      defaultValue: true,
    );
    _paginationState.isFetchingOrganizationsPage =
        TenantAdminOrganizationsRepositoryContractPrimBool.fromRaw(
      false,
      defaultValue: false,
    );
    hasMoreOrganizationsStreamValue.addValue(
      TenantAdminOrganizationsRepositoryContractPrimBool.fromRaw(
        true,
        defaultValue: true,
      ),
    );
    isOrganizationsPageLoadingStreamValue.addValue(
      TenantAdminOrganizationsRepositoryContractPrimBool.fromRaw(
        false,
        defaultValue: false,
      ),
    );
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
  StreamValue<TenantAdminOrganizationsRepositoryContractPrimBool>
      get hasMoreOrganizationsStreamValue =>
          _mixinPaginationState.hasMoreOrganizationsStreamValue;

  @override
  StreamValue<TenantAdminOrganizationsRepositoryContractPrimBool>
      get isOrganizationsPageLoadingStreamValue =>
          _mixinPaginationState.isOrganizationsPageLoadingStreamValue;

  @override
  StreamValue<TenantAdminOrganizationsRepositoryContractPrimString?>
      get organizationsErrorStreamValue =>
          _mixinPaginationState.organizationsErrorStreamValue;

  @override
  Future<void> loadOrganizations({
    TenantAdminOrganizationsRepositoryContractPrimInt? pageSize,
  }) async {
    final effectivePageSize = pageSize ??
        TenantAdminOrganizationsRepositoryContractPrimInt.fromRaw(
          20,
          defaultValue: 20,
        );
    await _waitForOrganizationsFetchMixin();
    _resetOrganizationsPaginationMixin();
    organizationsStreamValue.addValue(null);
    await _fetchOrganizationsPageMixin(
      page: TenantAdminOrganizationsRepositoryContractPrimInt.fromRaw(
        1,
        defaultValue: 1,
      ),
      pageSize: effectivePageSize,
    );
  }

  @override
  Future<void> loadNextOrganizationsPage({
    TenantAdminOrganizationsRepositoryContractPrimInt? pageSize,
  }) async {
    final effectivePageSize = pageSize ??
        TenantAdminOrganizationsRepositoryContractPrimInt.fromRaw(
          20,
          defaultValue: 20,
        );
    if (_mixinPaginationState.isFetchingOrganizationsPage.value ||
        !_mixinPaginationState.hasMoreOrganizations.value) {
      return;
    }
    await _fetchOrganizationsPageMixin(
      page: TenantAdminOrganizationsRepositoryContractPrimInt.fromRaw(
        _mixinPaginationState.currentOrganizationsPage.value + 1,
        defaultValue: 1,
      ),
      pageSize: effectivePageSize,
    );
  }

  @override
  void resetOrganizationsState() {
    _resetOrganizationsPaginationMixin();
    organizationsStreamValue.addValue(null);
    organizationsErrorStreamValue.addValue(null);
  }

  Future<void> _waitForOrganizationsFetchMixin() async {
    while (_mixinPaginationState.isFetchingOrganizationsPage.value) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchOrganizationsPageMixin({
    required TenantAdminOrganizationsRepositoryContractPrimInt page,
    required TenantAdminOrganizationsRepositoryContractPrimInt pageSize,
  }) async {
    if (_mixinPaginationState.isFetchingOrganizationsPage.value) return;
    if (page.value > 1 && !_mixinPaginationState.hasMoreOrganizations.value) {
      return;
    }

    _mixinPaginationState.isFetchingOrganizationsPage =
        TenantAdminOrganizationsRepositoryContractPrimBool.fromRaw(
      true,
      defaultValue: true,
    );
    if (page.value > 1) {
      isOrganizationsPageLoadingStreamValue.addValue(
        TenantAdminOrganizationsRepositoryContractPrimBool.fromRaw(
          true,
          defaultValue: true,
        ),
      );
    }
    try {
      final result = await fetchOrganizationsPage(
        page: page,
        pageSize: pageSize,
      );
      if (page.value == 1) {
        _mixinPaginationState.cachedOrganizations
          ..clear()
          ..addAll(result.items);
      } else {
        _mixinPaginationState.cachedOrganizations.addAll(result.items);
      }
      _mixinPaginationState.currentOrganizationsPage = page;
      _mixinPaginationState.hasMoreOrganizations =
          TenantAdminOrganizationsRepositoryContractPrimBool.fromRaw(
        result.hasMore,
        defaultValue: true,
      );
      hasMoreOrganizationsStreamValue
          .addValue(_mixinPaginationState.hasMoreOrganizations);
      organizationsStreamValue.addValue(
        List<TenantAdminOrganization>.unmodifiable(
          _mixinPaginationState.cachedOrganizations,
        ),
      );
      organizationsErrorStreamValue.addValue(null);
    } catch (error) {
      organizationsErrorStreamValue.addValue(
        TenantAdminOrganizationsRepositoryContractPrimString.fromRaw(
          error.toString(),
        ),
      );
      if (page.value == 1) {
        organizationsStreamValue.addValue(const <TenantAdminOrganization>[]);
      }
    } finally {
      _mixinPaginationState.isFetchingOrganizationsPage =
          TenantAdminOrganizationsRepositoryContractPrimBool.fromRaw(
        false,
        defaultValue: false,
      );
      isOrganizationsPageLoadingStreamValue.addValue(
        TenantAdminOrganizationsRepositoryContractPrimBool.fromRaw(
          false,
          defaultValue: false,
        ),
      );
    }
  }

  void _resetOrganizationsPaginationMixin() {
    _mixinPaginationState.cachedOrganizations.clear();
    _mixinPaginationState.currentOrganizationsPage =
        TenantAdminOrganizationsRepositoryContractPrimInt.fromRaw(
      0,
      defaultValue: 0,
    );
    _mixinPaginationState.hasMoreOrganizations =
        TenantAdminOrganizationsRepositoryContractPrimBool.fromRaw(
      true,
      defaultValue: true,
    );
    _mixinPaginationState.isFetchingOrganizationsPage =
        TenantAdminOrganizationsRepositoryContractPrimBool.fromRaw(
      false,
      defaultValue: false,
    );
    hasMoreOrganizationsStreamValue.addValue(
      TenantAdminOrganizationsRepositoryContractPrimBool.fromRaw(
        true,
        defaultValue: true,
      ),
    );
    isOrganizationsPageLoadingStreamValue.addValue(
      TenantAdminOrganizationsRepositoryContractPrimBool.fromRaw(
        false,
        defaultValue: false,
      ),
    );
  }
}

class _TenantAdminOrganizationsPaginationState {
  final List<TenantAdminOrganization> cachedOrganizations =
      <TenantAdminOrganization>[];
  final StreamValue<List<TenantAdminOrganization>?> organizationsStreamValue =
      StreamValue<List<TenantAdminOrganization>?>();
  final StreamValue<TenantAdminOrganizationsRepositoryContractPrimBool>
      hasMoreOrganizationsStreamValue =
      StreamValue<TenantAdminOrganizationsRepositoryContractPrimBool>(
          defaultValue:
              TenantAdminOrganizationsRepositoryContractPrimBool.fromRaw(
    true,
    defaultValue: true,
  ));
  final StreamValue<TenantAdminOrganizationsRepositoryContractPrimBool>
      isOrganizationsPageLoadingStreamValue =
      StreamValue<TenantAdminOrganizationsRepositoryContractPrimBool>(
          defaultValue:
              TenantAdminOrganizationsRepositoryContractPrimBool.fromRaw(
    false,
    defaultValue: false,
  ));
  final StreamValue<TenantAdminOrganizationsRepositoryContractPrimString?>
      organizationsErrorStreamValue =
      StreamValue<TenantAdminOrganizationsRepositoryContractPrimString?>();
  TenantAdminOrganizationsRepositoryContractPrimBool
      isFetchingOrganizationsPage =
      TenantAdminOrganizationsRepositoryContractPrimBool.fromRaw(
    false,
    defaultValue: false,
  );
  TenantAdminOrganizationsRepositoryContractPrimBool hasMoreOrganizations =
      TenantAdminOrganizationsRepositoryContractPrimBool.fromRaw(
    true,
    defaultValue: true,
  );
  TenantAdminOrganizationsRepositoryContractPrimInt currentOrganizationsPage =
      TenantAdminOrganizationsRepositoryContractPrimInt.fromRaw(
    0,
    defaultValue: 0,
  );
}
