import 'dart:async';

import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
import 'package:stream_value/core/stream_value.dart';

class TenantAdminAccountsController implements Disposable {
  TenantAdminAccountsController({
    TenantAdminAccountsRepositoryContract? accountsRepository,
    TenantAdminTenantScopeContract? tenantScope,
  })  : _accountsRepository = accountsRepository ??
            GetIt.I.get<TenantAdminAccountsRepositoryContract>(),
        _tenantScope = tenantScope ??
            (GetIt.I.isRegistered<TenantAdminTenantScopeContract>()
                ? GetIt.I.get<TenantAdminTenantScopeContract>()
                : null);

  final TenantAdminAccountsRepositoryContract _accountsRepository;
  final TenantAdminTenantScopeContract? _tenantScope;

  static const int _accountsPageSize = 20;
  static const Duration _searchDebounceDuration = Duration(milliseconds: 350);

  StreamValue<List<TenantAdminAccount>?> get accountsStreamValue =>
      _accountsRepository.accountsStreamValue;
  StreamValue<bool> get hasMoreAccountsStreamValue =>
      _accountsRepository.hasMoreAccountsStreamValue;
  StreamValue<bool> get isAccountsPageLoadingStreamValue =>
      _accountsRepository.isAccountsPageLoadingStreamValue;
  StreamValue<String?> get errorStreamValue =>
      _accountsRepository.accountsErrorStreamValue;

  final StreamValue<TenantAdminOwnershipState> selectedOwnershipStreamValue =
      StreamValue<TenantAdminOwnershipState>(
    defaultValue: TenantAdminOwnershipState.tenantOwned,
  );
  final StreamValue<String> searchQueryStreamValue =
      StreamValue<String>(defaultValue: '');
  final StreamValue<bool> showSearchFieldStreamValue =
      StreamValue<bool>(defaultValue: false);
  final ScrollController accountsListScrollController = ScrollController();

  bool _isDisposed = false;
  bool _initialized = false;
  bool _accountsListScrollBound = false;
  String? _initializedTenantDomain;
  StreamSubscription<String?>? _tenantScopeSubscription;
  Timer? _searchDebounceTimer;

  Future<void> init() async {
    _bindTenantScope();
    final normalizedTenantDomain =
        _normalizeTenantDomain(_tenantScope?.selectedTenantDomain);
    if (_initialized && _initializedTenantDomain == normalizedTenantDomain) {
      return;
    }
    if (_initialized && _initializedTenantDomain != normalizedTenantDomain) {
      _resetTenantScopedState();
    }
    _initialized = true;
    _initializedTenantDomain = normalizedTenantDomain;
    await loadAccounts(ownershipState: selectedOwnershipStreamValue.value);
  }

  void _bindTenantScope() {
    if (_tenantScopeSubscription != null || _tenantScope == null) {
      return;
    }
    final tenantScope = _tenantScope;
    _tenantScopeSubscription =
        tenantScope.selectedTenantDomainStreamValue.stream.listen(
      (tenantDomain) {
        if (_isDisposed) return;
        final normalized = _normalizeTenantDomain(tenantDomain);
        if (normalized == _initializedTenantDomain) {
          return;
        }
        _initializedTenantDomain = normalized;
        _initialized = normalized != null;
        _resetTenantScopedState();
        if (normalized != null) {
          unawaited(_loadTenantScopedData());
        }
      },
    );
  }

  Future<void> _loadTenantScopedData() async {
    await loadAccounts(ownershipState: selectedOwnershipStreamValue.value);
  }

  Future<void> loadAccounts({
    TenantAdminOwnershipState? ownershipState,
    String? searchQuery,
  }) async {
    if (_isDisposed) {
      return;
    }
    await _accountsRepository.loadAccounts(
      pageSize: _accountsPageSize,
      ownershipState: ownershipState ?? selectedOwnershipStreamValue.value,
      searchQuery: _normalizeSearchQuery(
        searchQuery ?? searchQueryStreamValue.value,
      ),
    );
  }

  Future<void> loadNextAccountsPage({
    TenantAdminOwnershipState? ownershipState,
    String? searchQuery,
  }) async {
    if (_isDisposed) {
      return;
    }
    await _accountsRepository.loadNextAccountsPage(
      pageSize: _accountsPageSize,
      ownershipState: ownershipState ?? selectedOwnershipStreamValue.value,
      searchQuery: _normalizeSearchQuery(
        searchQuery ?? searchQueryStreamValue.value,
      ),
    );
  }

  void bindAccountsListScrollPagination() {
    if (_accountsListScrollBound) {
      return;
    }
    _accountsListScrollBound = true;
    accountsListScrollController.addListener(_handleAccountsListScroll);
  }

  void unbindAccountsListScrollPagination() {
    if (!_accountsListScrollBound) {
      return;
    }
    _accountsListScrollBound = false;
    accountsListScrollController.removeListener(_handleAccountsListScroll);
  }

  void _handleAccountsListScroll() {
    if (!accountsListScrollController.hasClients) {
      return;
    }
    final position = accountsListScrollController.position;
    const threshold = 320.0;
    if (position.pixels + threshold >= position.maxScrollExtent) {
      unawaited(loadNextAccountsPage());
    }
  }

  void updateSelectedOwnership(TenantAdminOwnershipState ownershipState) {
    if (selectedOwnershipStreamValue.value == ownershipState) {
      return;
    }
    _searchDebounceTimer?.cancel();
    selectedOwnershipStreamValue.addValue(ownershipState);
    unawaited(loadAccounts(ownershipState: ownershipState));
  }

  void updateSearchQuery(String query) {
    if (searchQueryStreamValue.value == query) {
      return;
    }
    searchQueryStreamValue.addValue(query);
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounceDuration, () {
      if (_isDisposed) {
        return;
      }
      unawaited(loadAccounts());
    });
  }

  void toggleSearchFieldVisibility() {
    final next = !showSearchFieldStreamValue.value;
    showSearchFieldStreamValue.addValue(next);
    if (!next) {
      updateSearchQuery('');
    }
  }

  void _resetTenantScopedState() {
    _searchDebounceTimer?.cancel();
    _accountsRepository.resetAccountsState();
    searchQueryStreamValue.addValue('');
    showSearchFieldStreamValue.addValue(false);
  }

  String? _normalizeSearchQuery(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  String? _normalizeTenantDomain(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    final uri =
        Uri.tryParse(trimmed.contains('://') ? trimmed : 'https://$trimmed');
    if (uri != null && uri.host.trim().isNotEmpty) {
      return uri.host.trim();
    }
    return trimmed;
  }

  void dispose() {
    _isDisposed = true;
    unbindAccountsListScrollPagination();
    _tenantScopeSubscription?.cancel();
    _searchDebounceTimer?.cancel();
    selectedOwnershipStreamValue.dispose();
    searchQueryStreamValue.dispose();
    showSearchFieldStreamValue.dispose();
    accountsListScrollController.dispose();
  }

  @override
  void onDispose() {
    dispose();
  }
}
