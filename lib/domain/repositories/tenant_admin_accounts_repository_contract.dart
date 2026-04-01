export 'tenant_admin_loaded_account_watch.dart';
export 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_taxonomy_terms_value.dart';

import 'dart:async';
import 'dart:math' as math;

import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_onboarding_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_accounts_result.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_taxonomy_terms_value.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_loaded_account_watch.dart';
import 'package:belluga_now/domain/repositories/value_objects/tenant_admin_accounts_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_loaded_account_dispose_action.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms.dart';

typedef TenantAdminAccountsRepositoryContractPrimString
    = TenantAdminAccountsRepositoryContractTextValue;
typedef TenantAdminAccountsRepositoryContractPrimInt
    = TenantAdminAccountsRepositoryContractIntValue;
typedef TenantAdminAccountsRepositoryContractPrimBool
    = TenantAdminAccountsRepositoryContractBoolValue;

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
    TenantAdminAccountsRepositoryContractPrimInt? pageSize,
    TenantAdminOwnershipState? ownershipState,
    TenantAdminAccountsRepositoryContractPrimString? searchQuery,
  }) async {
    final effectivePageSize = pageSize ??
        TenantAdminAccountsRepositoryContractPrimInt.fromRaw(
          20,
          defaultValue: 20,
        );
    await _waitForAccountsFetch();
    _resetAccountsPagination();
    accountsStreamValue.addValue(null);
    await _fetchAccountsPage(
      page: TenantAdminAccountsRepositoryContractPrimInt.fromRaw(
        1,
        defaultValue: 1,
      ),
      pageSize: effectivePageSize,
      ownershipState: ownershipState,
      searchQuery: searchQuery,
    );
  }

  Future<void> loadNextAccountsPage({
    TenantAdminAccountsRepositoryContractPrimInt? pageSize,
    TenantAdminOwnershipState? ownershipState,
    TenantAdminAccountsRepositoryContractPrimString? searchQuery,
  }) async {
    final effectivePageSize = pageSize ??
        TenantAdminAccountsRepositoryContractPrimInt.fromRaw(
          20,
          defaultValue: 20,
        );
    if (_paginationState.isFetchingAccountsPage.value ||
        !_paginationState.hasMoreAccounts.value) {
      return;
    }
    await _fetchAccountsPage(
      page: TenantAdminAccountsRepositoryContractPrimInt.fromRaw(
        _paginationState.currentAccountsPage.value + 1,
        defaultValue: 1,
      ),
      pageSize: effectivePageSize,
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
    final normalizedSearch = searchQuery?.value.trim().toLowerCase() ?? '';
    final filteredAccounts = normalizedSearch.isEmpty
        ? filteredByOwnership
        : filteredByOwnership.where((account) {
            return account.name.toLowerCase().contains(normalizedSearch) ||
                account.slug.toLowerCase().contains(normalizedSearch) ||
                account.document.number
                    .toLowerCase()
                    .contains(normalizedSearch);
          }).toList(growable: false);
    if (page.value <= 0 || pageSize.value <= 0) {
      return tenantAdminPagedAccountsResultFromRaw(
        accounts: <TenantAdminAccount>[],
        hasMore: false,
      );
    }
    final startIndex = (page.value - 1) * pageSize.value;
    if (startIndex >= filteredAccounts.length) {
      return tenantAdminPagedAccountsResultFromRaw(
        accounts: <TenantAdminAccount>[],
        hasMore: false,
      );
    }
    final endIndex =
        math.min(startIndex + pageSize.value, filteredAccounts.length);
    return tenantAdminPagedAccountsResultFromRaw(
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
    final normalizedId = accountId?.value.trim();
    if (normalizedId != null && normalizedId.isNotEmpty) {
      for (final account in loadedAccounts) {
        if (account.id == normalizedId) {
          return account;
        }
      }
    }
    final normalizedSlug = accountSlug?.value.trim();
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
    final normalizedId = accountId?.value.trim();
    final normalizedSlug = accountSlug?.value.trim();
    final watchedAccountStreamValue = StreamValue<TenantAdminAccount?>(
      defaultValue: findLoadedAccount(
        accountId: normalizedId == null
            ? null
            : TenantAdminAccountsRepositoryContractPrimString.fromRaw(
                normalizedId,
              ),
        accountSlug: normalizedSlug == null
            ? null
            : TenantAdminAccountsRepositoryContractPrimString.fromRaw(
                normalizedSlug,
              ),
      ),
    );
    final subscription = accountsStreamValue.stream.listen((_) {
      watchedAccountStreamValue.addValue(
        findLoadedAccount(
          accountId: normalizedId == null
              ? null
              : TenantAdminAccountsRepositoryContractPrimString.fromRaw(
                  normalizedId,
                ),
          accountSlug: normalizedSlug == null
              ? null
              : TenantAdminAccountsRepositoryContractPrimString.fromRaw(
                  normalizedSlug,
                ),
        ),
      );
    });
    return TenantAdminLoadedAccountWatch(
      streamValue: watchedAccountStreamValue,
      onDispose: TenantAdminLoadedAccountDisposeAction(() {
        unawaited(subscription.cancel());
      }),
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
    TenantAdminTaxonomyTerms taxonomyTerms =
        const TenantAdminTaxonomyTerms.empty(),
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
    while (_paginationState.isFetchingAccountsPage.value) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchAccountsPage({
    required TenantAdminAccountsRepositoryContractPrimInt page,
    required TenantAdminAccountsRepositoryContractPrimInt pageSize,
    TenantAdminOwnershipState? ownershipState,
    TenantAdminAccountsRepositoryContractPrimString? searchQuery,
  }) async {
    if (_paginationState.isFetchingAccountsPage.value) return;
    if (page.value > 1 && !_paginationState.hasMoreAccounts.value) return;

    _paginationState.isFetchingAccountsPage =
        TenantAdminAccountsRepositoryContractPrimBool.fromRaw(
      true,
      defaultValue: true,
    );
    if (page.value > 1) {
      isAccountsPageLoadingStreamValue.addValue(
        TenantAdminAccountsRepositoryContractPrimBool.fromRaw(
          true,
          defaultValue: true,
        ),
      );
    }
    try {
      final result = await fetchAccountsPage(
        page: page,
        pageSize: pageSize,
        ownershipState: ownershipState,
        searchQuery: searchQuery,
      );
      if (page.value == 1) {
        _paginationState.loadedAccounts
          ..clear()
          ..addAll(result.accounts);
      } else {
        _paginationState.loadedAccounts.addAll(result.accounts);
      }
      _paginationState.currentAccountsPage = page;
      _paginationState.hasMoreAccounts =
          TenantAdminAccountsRepositoryContractPrimBool.fromRaw(
        result.hasMore,
        defaultValue: true,
      );
      hasMoreAccountsStreamValue.addValue(_paginationState.hasMoreAccounts);
      accountsStreamValue.addValue(
        List<TenantAdminAccount>.unmodifiable(_paginationState.loadedAccounts),
      );
      accountsErrorStreamValue.addValue(null);
    } catch (error) {
      accountsErrorStreamValue.addValue(
        TenantAdminAccountsRepositoryContractPrimString.fromRaw(
          error.toString(),
        ),
      );
      if (page.value == 1) {
        accountsStreamValue.addValue(const <TenantAdminAccount>[]);
      }
    } finally {
      _paginationState.isFetchingAccountsPage =
          TenantAdminAccountsRepositoryContractPrimBool.fromRaw(
        false,
        defaultValue: false,
      );
      isAccountsPageLoadingStreamValue.addValue(
        TenantAdminAccountsRepositoryContractPrimBool.fromRaw(
          false,
          defaultValue: false,
        ),
      );
    }
  }

  void _resetAccountsPagination() {
    _paginationState.loadedAccounts.clear();
    _paginationState.currentAccountsPage =
        TenantAdminAccountsRepositoryContractPrimInt.fromRaw(
      0,
      defaultValue: 0,
    );
    _paginationState.hasMoreAccounts =
        TenantAdminAccountsRepositoryContractPrimBool.fromRaw(
      true,
      defaultValue: true,
    );
    _paginationState.isFetchingAccountsPage =
        TenantAdminAccountsRepositoryContractPrimBool.fromRaw(
      false,
      defaultValue: false,
    );
    hasMoreAccountsStreamValue.addValue(
      TenantAdminAccountsRepositoryContractPrimBool.fromRaw(
        true,
        defaultValue: true,
      ),
    );
    isAccountsPageLoadingStreamValue.addValue(
      TenantAdminAccountsRepositoryContractPrimBool.fromRaw(
        false,
        defaultValue: false,
      ),
    );
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
    TenantAdminAccountsRepositoryContractPrimInt? pageSize,
    TenantAdminOwnershipState? ownershipState,
    TenantAdminAccountsRepositoryContractPrimString? searchQuery,
  }) async {
    final effectivePageSize = pageSize ??
        TenantAdminAccountsRepositoryContractPrimInt.fromRaw(
          20,
          defaultValue: 20,
        );
    await _waitForAccountsFetchMixin();
    _resetAccountsPaginationMixin();
    accountsStreamValue.addValue(null);
    await _fetchAccountsPageMixin(
      page: TenantAdminAccountsRepositoryContractPrimInt.fromRaw(
        1,
        defaultValue: 1,
      ),
      pageSize: effectivePageSize,
      ownershipState: ownershipState,
      searchQuery: searchQuery,
    );
  }

  @override
  Future<void> loadNextAccountsPage({
    TenantAdminAccountsRepositoryContractPrimInt? pageSize,
    TenantAdminOwnershipState? ownershipState,
    TenantAdminAccountsRepositoryContractPrimString? searchQuery,
  }) async {
    final effectivePageSize = pageSize ??
        TenantAdminAccountsRepositoryContractPrimInt.fromRaw(
          20,
          defaultValue: 20,
        );
    if (_mixinPaginationState.isFetchingAccountsPage.value ||
        !_mixinPaginationState.hasMoreAccounts.value) {
      return;
    }
    await _fetchAccountsPageMixin(
      page: TenantAdminAccountsRepositoryContractPrimInt.fromRaw(
        _mixinPaginationState.currentAccountsPage.value + 1,
        defaultValue: 1,
      ),
      pageSize: effectivePageSize,
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
    final normalizedId = accountId?.value.trim();
    if (normalizedId != null && normalizedId.isNotEmpty) {
      for (final account in loadedAccounts) {
        if (account.id == normalizedId) {
          return account;
        }
      }
    }
    final normalizedSlug = accountSlug?.value.trim();
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
    final normalizedId = accountId?.value.trim();
    final normalizedSlug = accountSlug?.value.trim();
    final watchedAccountStreamValue = StreamValue<TenantAdminAccount?>(
      defaultValue: findLoadedAccount(
        accountId: normalizedId == null
            ? null
            : TenantAdminAccountsRepositoryContractPrimString.fromRaw(
                normalizedId,
              ),
        accountSlug: normalizedSlug == null
            ? null
            : TenantAdminAccountsRepositoryContractPrimString.fromRaw(
                normalizedSlug,
              ),
      ),
    );
    final subscription = accountsStreamValue.stream.listen((_) {
      watchedAccountStreamValue.addValue(
        findLoadedAccount(
          accountId: normalizedId == null
              ? null
              : TenantAdminAccountsRepositoryContractPrimString.fromRaw(
                  normalizedId,
                ),
          accountSlug: normalizedSlug == null
              ? null
              : TenantAdminAccountsRepositoryContractPrimString.fromRaw(
                  normalizedSlug,
                ),
        ),
      );
    });
    return TenantAdminLoadedAccountWatch(
      streamValue: watchedAccountStreamValue,
      onDispose: TenantAdminLoadedAccountDisposeAction(() {
        unawaited(subscription.cancel());
      }),
    );
  }

  Future<void> _waitForAccountsFetchMixin() async {
    while (_mixinPaginationState.isFetchingAccountsPage.value) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _fetchAccountsPageMixin({
    required TenantAdminAccountsRepositoryContractPrimInt page,
    required TenantAdminAccountsRepositoryContractPrimInt pageSize,
    TenantAdminOwnershipState? ownershipState,
    TenantAdminAccountsRepositoryContractPrimString? searchQuery,
  }) async {
    if (_mixinPaginationState.isFetchingAccountsPage.value) return;
    if (page.value > 1 && !_mixinPaginationState.hasMoreAccounts.value) return;

    _mixinPaginationState.isFetchingAccountsPage =
        TenantAdminAccountsRepositoryContractPrimBool.fromRaw(
      true,
      defaultValue: true,
    );
    if (page.value > 1) {
      isAccountsPageLoadingStreamValue.addValue(
        TenantAdminAccountsRepositoryContractPrimBool.fromRaw(
          true,
          defaultValue: true,
        ),
      );
    }
    try {
      final result = await fetchAccountsPage(
        page: page,
        pageSize: pageSize,
        ownershipState: ownershipState,
        searchQuery: searchQuery,
      );
      if (page.value == 1) {
        _mixinPaginationState.loadedAccounts
          ..clear()
          ..addAll(result.accounts);
      } else {
        _mixinPaginationState.loadedAccounts.addAll(result.accounts);
      }
      _mixinPaginationState.currentAccountsPage = page;
      _mixinPaginationState.hasMoreAccounts =
          TenantAdminAccountsRepositoryContractPrimBool.fromRaw(
        result.hasMore,
        defaultValue: true,
      );
      hasMoreAccountsStreamValue
          .addValue(_mixinPaginationState.hasMoreAccounts);
      accountsStreamValue.addValue(
        List<TenantAdminAccount>.unmodifiable(
          _mixinPaginationState.loadedAccounts,
        ),
      );
      accountsErrorStreamValue.addValue(null);
    } catch (error) {
      accountsErrorStreamValue.addValue(
        TenantAdminAccountsRepositoryContractPrimString.fromRaw(
          error.toString(),
        ),
      );
      if (page.value == 1) {
        accountsStreamValue.addValue(const <TenantAdminAccount>[]);
      }
    } finally {
      _mixinPaginationState.isFetchingAccountsPage =
          TenantAdminAccountsRepositoryContractPrimBool.fromRaw(
        false,
        defaultValue: false,
      );
      isAccountsPageLoadingStreamValue.addValue(
        TenantAdminAccountsRepositoryContractPrimBool.fromRaw(
          false,
          defaultValue: false,
        ),
      );
    }
  }

  void _resetAccountsPaginationMixin() {
    _mixinPaginationState.loadedAccounts.clear();
    _mixinPaginationState.currentAccountsPage =
        TenantAdminAccountsRepositoryContractPrimInt.fromRaw(
      0,
      defaultValue: 0,
    );
    _mixinPaginationState.hasMoreAccounts =
        TenantAdminAccountsRepositoryContractPrimBool.fromRaw(
      true,
      defaultValue: true,
    );
    _mixinPaginationState.isFetchingAccountsPage =
        TenantAdminAccountsRepositoryContractPrimBool.fromRaw(
      false,
      defaultValue: false,
    );
    hasMoreAccountsStreamValue.addValue(
      TenantAdminAccountsRepositoryContractPrimBool.fromRaw(
        true,
        defaultValue: true,
      ),
    );
    isAccountsPageLoadingStreamValue.addValue(
      TenantAdminAccountsRepositoryContractPrimBool.fromRaw(
        false,
        defaultValue: false,
      ),
    );
  }
}

class _TenantAdminAccountsPaginationState {
  final List<TenantAdminAccount> loadedAccounts = <TenantAdminAccount>[];
  final StreamValue<List<TenantAdminAccount>?> accountsStreamValue =
      StreamValue<List<TenantAdminAccount>?>();
  final StreamValue<TenantAdminAccountsRepositoryContractPrimBool>
      hasMoreAccountsStreamValue =
      StreamValue<TenantAdminAccountsRepositoryContractPrimBool>(
          defaultValue: TenantAdminAccountsRepositoryContractPrimBool.fromRaw(
    true,
    defaultValue: true,
  ));
  final StreamValue<TenantAdminAccountsRepositoryContractPrimBool>
      isAccountsPageLoadingStreamValue =
      StreamValue<TenantAdminAccountsRepositoryContractPrimBool>(
          defaultValue: TenantAdminAccountsRepositoryContractPrimBool.fromRaw(
    false,
    defaultValue: false,
  ));
  final StreamValue<TenantAdminAccountsRepositoryContractPrimString?>
      accountsErrorStreamValue =
      StreamValue<TenantAdminAccountsRepositoryContractPrimString?>();
  TenantAdminAccountsRepositoryContractPrimBool isFetchingAccountsPage =
      TenantAdminAccountsRepositoryContractPrimBool.fromRaw(
    false,
    defaultValue: false,
  );
  TenantAdminAccountsRepositoryContractPrimBool hasMoreAccounts =
      TenantAdminAccountsRepositoryContractPrimBool.fromRaw(
    true,
    defaultValue: true,
  );
  TenantAdminAccountsRepositoryContractPrimInt currentAccountsPage =
      TenantAdminAccountsRepositoryContractPrimInt.fromRaw(
    0,
    defaultValue: 0,
  );
}
