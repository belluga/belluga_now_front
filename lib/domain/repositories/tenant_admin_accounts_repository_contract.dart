export 'tenant_admin_loaded_account_watch.dart';

import 'dart:async';
import 'dart:math' as math;

import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_onboarding_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_accounts_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_loaded_account_watch.dart';
import 'package:stream_value/core/stream_value.dart';

typedef TenantAdminAccountsRepositoryContractPrimString = String;
typedef TenantAdminAccountsRepositoryContractPrimInt = int;
typedef TenantAdminAccountsRepositoryContractPrimBool = bool;
typedef TenantAdminAccountsRepositoryContractPrimDouble = double;
typedef TenantAdminAccountsRepositoryContractPrimDateTime = DateTime;
typedef TenantAdminAccountsRepositoryContractPrimDynamic = dynamic;

abstract class TenantAdminAccountsRepositoryContract {
  static final Expando<_TenantAdminAccountsPaginationState>
      _paginationStateByRepository =
      Expando<_TenantAdminAccountsPaginationState>();

  _TenantAdminAccountsPaginationState get _paginationState =>
      _paginationStateByRepository[this] ??=
          _TenantAdminAccountsPaginationState();

  StreamValue<List<TenantAdminAccount>?> get accountsStreamValue =>
      _paginationState.accountsStreamValue;

  StreamValue<TenantAdminAccountsRepositoryContractPrimBool>
      get hasMoreAccountsStreamValue =>
          _paginationState.hasMoreAccountsStreamValue;

  StreamValue<TenantAdminAccountsRepositoryContractPrimBool>
      get isAccountsPageLoadingStreamValue =>
          _paginationState.isAccountsPageLoadingStreamValue;

  StreamValue<TenantAdminAccountsRepositoryContractPrimString?>
      get accountsErrorStreamValue => _paginationState.accountsErrorStreamValue;

  Future<void> loadAccounts({
    TenantAdminAccountsRepositoryContractPrimInt pageSize = 20,
    TenantAdminOwnershipState? ownershipState,
    TenantAdminAccountsRepositoryContractPrimString? searchQuery,
  }) async {
    await _waitForAccountsFetch();
    _resetAccountsPagination();
    accountsStreamValue.addValue(null);
    await _fetchAccountsPage(
      page: 1,
      pageSize: pageSize,
      ownershipState: ownershipState,
      searchQuery: searchQuery,
    );
  }

  Future<void> loadNextAccountsPage({
    TenantAdminAccountsRepositoryContractPrimInt pageSize = 20,
    TenantAdminOwnershipState? ownershipState,
    TenantAdminAccountsRepositoryContractPrimString? searchQuery,
  }) async {
    if (_paginationState.isFetchingAccountsPage ||
        !_paginationState.hasMoreAccounts) {
      return;
    }
    await _fetchAccountsPage(
      page: _paginationState.currentAccountsPage + 1,
      pageSize: pageSize,
      ownershipState: ownershipState,
      searchQuery: searchQuery,
    );
  }

  void resetAccountsState() {
    _resetAccountsPagination();
    accountsStreamValue.addValue(null);
    accountsErrorStreamValue.addValue(null);
  }

  Future<List<TenantAdminAccount>> fetchAccounts();
  Future<TenantAdminPagedAccountsResult> fetchAccountsPage({
    required TenantAdminAccountsRepositoryContractPrimInt page,
    required TenantAdminAccountsRepositoryContractPrimInt pageSize,
    TenantAdminOwnershipState? ownershipState,
    TenantAdminAccountsRepositoryContractPrimString? searchQuery,
  }) async {
    final accounts = await fetchAccounts();
    final filteredByOwnership = ownershipState == null
        ? accounts
        : accounts.where((account) {
            return account.ownershipState == ownershipState;
          }).toList(growable: false);
    final normalizedSearch = searchQuery?.trim().toLowerCase() ?? '';
    final filteredAccounts = normalizedSearch.isEmpty
        ? filteredByOwnership
        : filteredByOwnership.where((account) {
            return account.name.toLowerCase().contains(normalizedSearch) ||
                account.slug.toLowerCase().contains(normalizedSearch) ||
                account.document.number
                    .toLowerCase()
                    .contains(normalizedSearch);
          }).toList(growable: false);
    if (page <= 0 || pageSize <= 0) {
      return TenantAdminPagedAccountsResult(
        accounts: <TenantAdminAccount>[],
        hasMore: false,
      );
    }
    final startIndex = (page - 1) * pageSize;
    if (startIndex >= filteredAccounts.length) {
      return TenantAdminPagedAccountsResult(
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

  Future<TenantAdminAccount> fetchAccountBySlug(
      TenantAdminAccountsRepositoryContractPrimString accountSlug);
  TenantAdminAccount? findLoadedAccount({
    TenantAdminAccountsRepositoryContractPrimString? accountId,
    TenantAdminAccountsRepositoryContractPrimString? accountSlug,
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
    TenantAdminAccountsRepositoryContractPrimString? accountId,
    TenantAdminAccountsRepositoryContractPrimString? accountSlug,
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
    required TenantAdminAccountsRepositoryContractPrimString name,
    TenantAdminDocument? document,
    required TenantAdminOwnershipState ownershipState,
    TenantAdminAccountsRepositoryContractPrimString? organizationId,
  });
  Future<TenantAdminAccountOnboardingResult> createAccountOnboarding({
    required TenantAdminAccountsRepositoryContractPrimString name,
    required TenantAdminOwnershipState ownershipState,
    required TenantAdminAccountsRepositoryContractPrimString profileType,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm> taxonomyTerms = const [],
    TenantAdminAccountsRepositoryContractPrimString? bio,
    TenantAdminAccountsRepositoryContractPrimString? content,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  });
  Future<TenantAdminAccount> updateAccount({
    required TenantAdminAccountsRepositoryContractPrimString accountSlug,
    TenantAdminAccountsRepositoryContractPrimString? name,
    TenantAdminAccountsRepositoryContractPrimString? slug,
    TenantAdminDocument? document,
    TenantAdminOwnershipState? ownershipState,
  });
  Future<void> deleteAccount(
      TenantAdminAccountsRepositoryContractPrimString accountSlug);
  Future<TenantAdminAccount> restoreAccount(
      TenantAdminAccountsRepositoryContractPrimString accountSlug);
  Future<void> forceDeleteAccount(
      TenantAdminAccountsRepositoryContractPrimString accountSlug);

  Future<void> _waitForAccountsFetch() async {
    while (_paginationState.isFetchingAccountsPage) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchAccountsPage({
    required TenantAdminAccountsRepositoryContractPrimInt page,
    required TenantAdminAccountsRepositoryContractPrimInt pageSize,
    TenantAdminOwnershipState? ownershipState,
    TenantAdminAccountsRepositoryContractPrimString? searchQuery,
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
        searchQuery: searchQuery,
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
  StreamValue<TenantAdminAccountsRepositoryContractPrimBool>
      get hasMoreAccountsStreamValue =>
          _mixinPaginationState.hasMoreAccountsStreamValue;

  @override
  StreamValue<TenantAdminAccountsRepositoryContractPrimBool>
      get isAccountsPageLoadingStreamValue =>
          _mixinPaginationState.isAccountsPageLoadingStreamValue;

  @override
  StreamValue<TenantAdminAccountsRepositoryContractPrimString?>
      get accountsErrorStreamValue =>
          _mixinPaginationState.accountsErrorStreamValue;

  @override
  Future<void> loadAccounts({
    TenantAdminAccountsRepositoryContractPrimInt pageSize = 20,
    TenantAdminOwnershipState? ownershipState,
    TenantAdminAccountsRepositoryContractPrimString? searchQuery,
  }) async {
    await _waitForAccountsFetchMixin();
    _resetAccountsPaginationMixin();
    accountsStreamValue.addValue(null);
    await _fetchAccountsPageMixin(
      page: 1,
      pageSize: pageSize,
      ownershipState: ownershipState,
      searchQuery: searchQuery,
    );
  }

  @override
  Future<void> loadNextAccountsPage({
    TenantAdminAccountsRepositoryContractPrimInt pageSize = 20,
    TenantAdminOwnershipState? ownershipState,
    TenantAdminAccountsRepositoryContractPrimString? searchQuery,
  }) async {
    if (_mixinPaginationState.isFetchingAccountsPage ||
        !_mixinPaginationState.hasMoreAccounts) {
      return;
    }
    await _fetchAccountsPageMixin(
      page: _mixinPaginationState.currentAccountsPage + 1,
      pageSize: pageSize,
      ownershipState: ownershipState,
      searchQuery: searchQuery,
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
    TenantAdminAccountsRepositoryContractPrimString? accountId,
    TenantAdminAccountsRepositoryContractPrimString? accountSlug,
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
    TenantAdminAccountsRepositoryContractPrimString? accountId,
    TenantAdminAccountsRepositoryContractPrimString? accountSlug,
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
    required TenantAdminAccountsRepositoryContractPrimInt page,
    required TenantAdminAccountsRepositoryContractPrimInt pageSize,
    TenantAdminOwnershipState? ownershipState,
    TenantAdminAccountsRepositoryContractPrimString? searchQuery,
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
        searchQuery: searchQuery,
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
  final StreamValue<TenantAdminAccountsRepositoryContractPrimBool>
      hasMoreAccountsStreamValue =
      StreamValue<TenantAdminAccountsRepositoryContractPrimBool>(
          defaultValue: true);
  final StreamValue<TenantAdminAccountsRepositoryContractPrimBool>
      isAccountsPageLoadingStreamValue =
      StreamValue<TenantAdminAccountsRepositoryContractPrimBool>(
          defaultValue: false);
  final StreamValue<TenantAdminAccountsRepositoryContractPrimString?>
      accountsErrorStreamValue =
      StreamValue<TenantAdminAccountsRepositoryContractPrimString?>();
  TenantAdminAccountsRepositoryContractPrimBool isFetchingAccountsPage = false;
  TenantAdminAccountsRepositoryContractPrimBool hasMoreAccounts = true;
  TenantAdminAccountsRepositoryContractPrimInt currentAccountsPage = 0;
}
