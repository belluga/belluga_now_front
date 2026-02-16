import 'dart:math' as math;

import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_accounts_result.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class TenantAdminAccountsRepositoryContract {
  static final Expando<_TenantAdminAccountsPaginationState>
      _paginationStateByRepository =
      Expando<_TenantAdminAccountsPaginationState>();

  _TenantAdminAccountsPaginationState get _paginationState =>
      _paginationStateByRepository[this] ??=
          _TenantAdminAccountsPaginationState();

  StreamValue<List<TenantAdminAccount>?> get accountsStreamValue =>
      _paginationState.accountsStreamValue;

  StreamValue<bool> get hasMoreAccountsStreamValue =>
      _paginationState.hasMoreAccountsStreamValue;

  StreamValue<bool> get isAccountsPageLoadingStreamValue =>
      _paginationState.isAccountsPageLoadingStreamValue;

  StreamValue<String?> get accountsErrorStreamValue =>
      _paginationState.accountsErrorStreamValue;

  Future<void> loadAccounts({int pageSize = 20}) async {
    await _waitForAccountsFetch();
    _resetAccountsPagination();
    accountsStreamValue.addValue(null);
    await _fetchAccountsPage(page: 1, pageSize: pageSize);
  }

  Future<void> loadNextAccountsPage({int pageSize = 20}) async {
    if (_paginationState.isFetchingAccountsPage ||
        !_paginationState.hasMoreAccounts) {
      return;
    }
    await _fetchAccountsPage(
      page: _paginationState.currentAccountsPage + 1,
      pageSize: pageSize,
    );
  }

  void resetAccountsState() {
    _resetAccountsPagination();
    accountsStreamValue.addValue(null);
    accountsErrorStreamValue.addValue(null);
  }

  Future<List<TenantAdminAccount>> fetchAccounts();
  Future<TenantAdminPagedAccountsResult> fetchAccountsPage({
    required int page,
    required int pageSize,
  }) async {
    final accounts = await fetchAccounts();
    if (page <= 0 || pageSize <= 0) {
      return const TenantAdminPagedAccountsResult(
        accounts: <TenantAdminAccount>[],
        hasMore: false,
      );
    }
    final startIndex = (page - 1) * pageSize;
    if (startIndex >= accounts.length) {
      return const TenantAdminPagedAccountsResult(
        accounts: <TenantAdminAccount>[],
        hasMore: false,
      );
    }
    final endIndex = math.min(startIndex + pageSize, accounts.length);
    return TenantAdminPagedAccountsResult(
      accounts: accounts.sublist(startIndex, endIndex),
      hasMore: endIndex < accounts.length,
    );
  }

  Future<TenantAdminAccount> fetchAccountBySlug(String accountSlug);
  Future<TenantAdminAccount> createAccount({
    required String name,
    TenantAdminDocument? document,
    required TenantAdminOwnershipState ownershipState,
    String? organizationId,
  });
  Future<TenantAdminAccount> updateAccount({
    required String accountSlug,
    String? name,
    String? slug,
    TenantAdminDocument? document,
  });
  Future<void> deleteAccount(String accountSlug);
  Future<TenantAdminAccount> restoreAccount(String accountSlug);
  Future<void> forceDeleteAccount(String accountSlug);

  Future<void> _waitForAccountsFetch() async {
    while (_paginationState.isFetchingAccountsPage) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchAccountsPage({
    required int page,
    required int pageSize,
  }) async {
    if (_paginationState.isFetchingAccountsPage) return;
    if (page > 1 && !_paginationState.hasMoreAccounts) return;

    _paginationState.isFetchingAccountsPage = true;
    if (page > 1) {
      isAccountsPageLoadingStreamValue.addValue(true);
    }
    try {
      final result = await fetchAccountsPage(
        page: page,
        pageSize: pageSize,
      );
      if (page == 1) {
        _paginationState.cachedAccounts
          ..clear()
          ..addAll(result.accounts);
      } else {
        _paginationState.cachedAccounts.addAll(result.accounts);
      }
      _paginationState.currentAccountsPage = page;
      _paginationState.hasMoreAccounts = result.hasMore;
      hasMoreAccountsStreamValue.addValue(_paginationState.hasMoreAccounts);
      accountsStreamValue.addValue(
        List<TenantAdminAccount>.unmodifiable(_paginationState.cachedAccounts),
      );
      accountsErrorStreamValue.addValue(null);
    } catch (error) {
      accountsErrorStreamValue.addValue(error.toString());
      if (page == 1) {
        accountsStreamValue.addValue(const <TenantAdminAccount>[]);
      }
    } finally {
      _paginationState.isFetchingAccountsPage = false;
      isAccountsPageLoadingStreamValue.addValue(false);
    }
  }

  void _resetAccountsPagination() {
    _paginationState.cachedAccounts.clear();
    _paginationState.currentAccountsPage = 0;
    _paginationState.hasMoreAccounts = true;
    _paginationState.isFetchingAccountsPage = false;
    hasMoreAccountsStreamValue.addValue(true);
    isAccountsPageLoadingStreamValue.addValue(false);
  }
}

mixin TenantAdminAccountsRepositoryPaginationMixin
    implements TenantAdminAccountsRepositoryContract {
  static final Expando<_TenantAdminAccountsPaginationState>
      _paginationStateByRepository =
      Expando<_TenantAdminAccountsPaginationState>();

  _TenantAdminAccountsPaginationState get _mixinPaginationState =>
      _paginationStateByRepository[this] ??=
          _TenantAdminAccountsPaginationState();

  @override
  StreamValue<List<TenantAdminAccount>?> get accountsStreamValue =>
      _mixinPaginationState.accountsStreamValue;

  @override
  StreamValue<bool> get hasMoreAccountsStreamValue =>
      _mixinPaginationState.hasMoreAccountsStreamValue;

  @override
  StreamValue<bool> get isAccountsPageLoadingStreamValue =>
      _mixinPaginationState.isAccountsPageLoadingStreamValue;

  @override
  StreamValue<String?> get accountsErrorStreamValue =>
      _mixinPaginationState.accountsErrorStreamValue;

  @override
  Future<void> loadAccounts({int pageSize = 20}) async {
    await _waitForAccountsFetchMixin();
    _resetAccountsPaginationMixin();
    accountsStreamValue.addValue(null);
    await _fetchAccountsPageMixin(page: 1, pageSize: pageSize);
  }

  @override
  Future<void> loadNextAccountsPage({int pageSize = 20}) async {
    if (_mixinPaginationState.isFetchingAccountsPage ||
        !_mixinPaginationState.hasMoreAccounts) {
      return;
    }
    await _fetchAccountsPageMixin(
      page: _mixinPaginationState.currentAccountsPage + 1,
      pageSize: pageSize,
    );
  }

  @override
  void resetAccountsState() {
    _resetAccountsPaginationMixin();
    accountsStreamValue.addValue(null);
    accountsErrorStreamValue.addValue(null);
  }

  Future<void> _waitForAccountsFetchMixin() async {
    while (_mixinPaginationState.isFetchingAccountsPage) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchAccountsPageMixin({
    required int page,
    required int pageSize,
  }) async {
    if (_mixinPaginationState.isFetchingAccountsPage) return;
    if (page > 1 && !_mixinPaginationState.hasMoreAccounts) return;

    _mixinPaginationState.isFetchingAccountsPage = true;
    if (page > 1) {
      isAccountsPageLoadingStreamValue.addValue(true);
    }
    try {
      final result = await fetchAccountsPage(
        page: page,
        pageSize: pageSize,
      );
      if (page == 1) {
        _mixinPaginationState.cachedAccounts
          ..clear()
          ..addAll(result.accounts);
      } else {
        _mixinPaginationState.cachedAccounts.addAll(result.accounts);
      }
      _mixinPaginationState.currentAccountsPage = page;
      _mixinPaginationState.hasMoreAccounts = result.hasMore;
      hasMoreAccountsStreamValue
          .addValue(_mixinPaginationState.hasMoreAccounts);
      accountsStreamValue.addValue(
        List<TenantAdminAccount>.unmodifiable(
          _mixinPaginationState.cachedAccounts,
        ),
      );
      accountsErrorStreamValue.addValue(null);
    } catch (error) {
      accountsErrorStreamValue.addValue(error.toString());
      if (page == 1) {
        accountsStreamValue.addValue(const <TenantAdminAccount>[]);
      }
    } finally {
      _mixinPaginationState.isFetchingAccountsPage = false;
      isAccountsPageLoadingStreamValue.addValue(false);
    }
  }

  void _resetAccountsPaginationMixin() {
    _mixinPaginationState.cachedAccounts.clear();
    _mixinPaginationState.currentAccountsPage = 0;
    _mixinPaginationState.hasMoreAccounts = true;
    _mixinPaginationState.isFetchingAccountsPage = false;
    hasMoreAccountsStreamValue.addValue(true);
    isAccountsPageLoadingStreamValue.addValue(false);
  }
}

class _TenantAdminAccountsPaginationState {
  final List<TenantAdminAccount> cachedAccounts = <TenantAdminAccount>[];
  final StreamValue<List<TenantAdminAccount>?> accountsStreamValue =
      StreamValue<List<TenantAdminAccount>?>();
  final StreamValue<bool> hasMoreAccountsStreamValue =
      StreamValue<bool>(defaultValue: true);
  final StreamValue<bool> isAccountsPageLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> accountsErrorStreamValue = StreamValue<String?>();
  bool isFetchingAccountsPage = false;
  bool hasMoreAccounts = true;
  int currentAccountsPage = 0;
}
