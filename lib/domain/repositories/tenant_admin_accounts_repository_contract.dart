import 'dart:async';
import 'dart:math' as math;

import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_accounts_result.dart';
import 'package:stream_value/core/stream_value.dart';

class TenantAdminLoadedAccountWatch {
  TenantAdminLoadedAccountWatch({
    required this.streamValue,
    required void Function() onDispose,
  }) : _onDispose = onDispose;

  final StreamValue<TenantAdminAccount?> streamValue;
  final void Function() _onDispose;
  bool _disposed = false;

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _onDispose();
    streamValue.dispose();
  }
}

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

  Future<void> loadAccounts({
    int pageSize = 20,
    TenantAdminOwnershipState? ownershipState,
  }) async {
    await _waitForAccountsFetch();
    _resetAccountsPagination();
    accountsStreamValue.addValue(null);
    await _fetchAccountsPage(
      page: 1,
      pageSize: pageSize,
      ownershipState: ownershipState,
    );
  }

  Future<void> loadNextAccountsPage({
    int pageSize = 20,
    TenantAdminOwnershipState? ownershipState,
  }) async {
    if (_paginationState.isFetchingAccountsPage ||
        !_paginationState.hasMoreAccounts) {
      return;
    }
    await _fetchAccountsPage(
      page: _paginationState.currentAccountsPage + 1,
      pageSize: pageSize,
      ownershipState: ownershipState,
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
    TenantAdminOwnershipState? ownershipState,
  }) async {
    final accounts = await fetchAccounts();
    final filteredAccounts = ownershipState == null
        ? accounts
        : accounts.where((account) {
            return account.ownershipState == ownershipState;
          }).toList(growable: false);
    if (page <= 0 || pageSize <= 0) {
      return const TenantAdminPagedAccountsResult(
        accounts: <TenantAdminAccount>[],
        hasMore: false,
      );
    }
    final startIndex = (page - 1) * pageSize;
    if (startIndex >= filteredAccounts.length) {
      return const TenantAdminPagedAccountsResult(
        accounts: <TenantAdminAccount>[],
        hasMore: false,
      );
    }
    final endIndex = math.min(startIndex + pageSize, filteredAccounts.length);
    return TenantAdminPagedAccountsResult(
      accounts: filteredAccounts.sublist(startIndex, endIndex),
      hasMore: endIndex < filteredAccounts.length,
    );
  }

  Future<TenantAdminAccount> fetchAccountBySlug(String accountSlug);
  TenantAdminAccount? findLoadedAccount({
    String? accountId,
    String? accountSlug,
  }) {
    final loadedAccounts = accountsStreamValue.value;
    if (loadedAccounts == null || loadedAccounts.isEmpty) {
      return null;
    }
    final normalizedId = accountId?.trim();
    if (normalizedId != null && normalizedId.isNotEmpty) {
      for (final account in loadedAccounts) {
        if (account.id == normalizedId) {
          return account;
        }
      }
    }
    final normalizedSlug = accountSlug?.trim();
    if (normalizedSlug != null && normalizedSlug.isNotEmpty) {
      for (final account in loadedAccounts) {
        if (account.slug == normalizedSlug) {
          return account;
        }
      }
    }
    return null;
  }

  TenantAdminLoadedAccountWatch watchLoadedAccount({
    String? accountId,
    String? accountSlug,
  }) {
    final normalizedId = accountId?.trim();
    final normalizedSlug = accountSlug?.trim();
    final watchedAccountStreamValue = StreamValue<TenantAdminAccount?>(
      defaultValue: findLoadedAccount(
        accountId: normalizedId,
        accountSlug: normalizedSlug,
      ),
    );
    final subscription = accountsStreamValue.stream.listen((_) {
      watchedAccountStreamValue.addValue(
        findLoadedAccount(
          accountId: normalizedId,
          accountSlug: normalizedSlug,
        ),
      );
    });
    return TenantAdminLoadedAccountWatch(
      streamValue: watchedAccountStreamValue,
      onDispose: () {
        unawaited(subscription.cancel());
      },
    );
  }

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
    TenantAdminOwnershipState? ownershipState,
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
        ownershipState: ownershipState,
      );
      if (page == 1) {
        _paginationState.loadedAccounts
          ..clear()
          ..addAll(result.accounts);
      } else {
        _paginationState.loadedAccounts.addAll(result.accounts);
      }
      _paginationState.currentAccountsPage = page;
      _paginationState.hasMoreAccounts = result.hasMore;
      hasMoreAccountsStreamValue.addValue(_paginationState.hasMoreAccounts);
      accountsStreamValue.addValue(
        List<TenantAdminAccount>.unmodifiable(_paginationState.loadedAccounts),
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
    _paginationState.loadedAccounts.clear();
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
  Future<void> loadAccounts({
    int pageSize = 20,
    TenantAdminOwnershipState? ownershipState,
  }) async {
    await _waitForAccountsFetchMixin();
    _resetAccountsPaginationMixin();
    accountsStreamValue.addValue(null);
    await _fetchAccountsPageMixin(
      page: 1,
      pageSize: pageSize,
      ownershipState: ownershipState,
    );
  }

  @override
  Future<void> loadNextAccountsPage({
    int pageSize = 20,
    TenantAdminOwnershipState? ownershipState,
  }) async {
    if (_mixinPaginationState.isFetchingAccountsPage ||
        !_mixinPaginationState.hasMoreAccounts) {
      return;
    }
    await _fetchAccountsPageMixin(
      page: _mixinPaginationState.currentAccountsPage + 1,
      pageSize: pageSize,
      ownershipState: ownershipState,
    );
  }

  @override
  void resetAccountsState() {
    _resetAccountsPaginationMixin();
    accountsStreamValue.addValue(null);
    accountsErrorStreamValue.addValue(null);
  }

  @override
  TenantAdminAccount? findLoadedAccount({
    String? accountId,
    String? accountSlug,
  }) {
    final loadedAccounts = accountsStreamValue.value;
    if (loadedAccounts == null || loadedAccounts.isEmpty) {
      return null;
    }
    final normalizedId = accountId?.trim();
    if (normalizedId != null && normalizedId.isNotEmpty) {
      for (final account in loadedAccounts) {
        if (account.id == normalizedId) {
          return account;
        }
      }
    }
    final normalizedSlug = accountSlug?.trim();
    if (normalizedSlug != null && normalizedSlug.isNotEmpty) {
      for (final account in loadedAccounts) {
        if (account.slug == normalizedSlug) {
          return account;
        }
      }
    }
    return null;
  }

  @override
  TenantAdminLoadedAccountWatch watchLoadedAccount({
    String? accountId,
    String? accountSlug,
  }) {
    final normalizedId = accountId?.trim();
    final normalizedSlug = accountSlug?.trim();
    final watchedAccountStreamValue = StreamValue<TenantAdminAccount?>(
      defaultValue: findLoadedAccount(
        accountId: normalizedId,
        accountSlug: normalizedSlug,
      ),
    );
    final subscription = accountsStreamValue.stream.listen((_) {
      watchedAccountStreamValue.addValue(
        findLoadedAccount(
          accountId: normalizedId,
          accountSlug: normalizedSlug,
        ),
      );
    });
    return TenantAdminLoadedAccountWatch(
      streamValue: watchedAccountStreamValue,
      onDispose: () {
        unawaited(subscription.cancel());
      },
    );
  }

  Future<void> _waitForAccountsFetchMixin() async {
    while (_mixinPaginationState.isFetchingAccountsPage) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchAccountsPageMixin({
    required int page,
    required int pageSize,
    TenantAdminOwnershipState? ownershipState,
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
        ownershipState: ownershipState,
      );
      if (page == 1) {
        _mixinPaginationState.loadedAccounts
          ..clear()
          ..addAll(result.accounts);
      } else {
        _mixinPaginationState.loadedAccounts.addAll(result.accounts);
      }
      _mixinPaginationState.currentAccountsPage = page;
      _mixinPaginationState.hasMoreAccounts = result.hasMore;
      hasMoreAccountsStreamValue
          .addValue(_mixinPaginationState.hasMoreAccounts);
      accountsStreamValue.addValue(
        List<TenantAdminAccount>.unmodifiable(
          _mixinPaginationState.loadedAccounts,
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
    _mixinPaginationState.loadedAccounts.clear();
    _mixinPaginationState.currentAccountsPage = 0;
    _mixinPaginationState.hasMoreAccounts = true;
    _mixinPaginationState.isFetchingAccountsPage = false;
    hasMoreAccountsStreamValue.addValue(true);
    isAccountsPageLoadingStreamValue.addValue(false);
  }
}

class _TenantAdminAccountsPaginationState {
  final List<TenantAdminAccount> loadedAccounts = <TenantAdminAccount>[];
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
