import 'dart:async';

import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
import 'package:stream_value/core/stream_value.dart';

class TenantAdminAccountProfilesListController implements Disposable {
  TenantAdminAccountProfilesListController({
    TenantAdminAccountProfilesRepositoryContract? profilesRepository,
    TenantAdminTenantScopeContract? tenantScope,
  }) : _profilesRepository =
           profilesRepository ??
           GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>(),
       _tenantScope =
           tenantScope ??
           (GetIt.I.isRegistered<TenantAdminTenantScopeContract>()
               ? GetIt.I.get<TenantAdminTenantScopeContract>()
               : null) {
    _bindTenantScope();
  }

  static const Duration _searchDebounceDuration = Duration(milliseconds: 350);
  static const int _pageSize = 20;

  final TenantAdminAccountProfilesRepositoryContract _profilesRepository;
  final TenantAdminTenantScopeContract? _tenantScope;

  final StreamValue<List<TenantAdminAccountProfile>?> profilesStreamValue =
      StreamValue<List<TenantAdminAccountProfile>?>(defaultValue: null);
  final StreamValue<bool> hasMoreProfilesStreamValue = StreamValue<bool>(
    defaultValue: false,
  );
  final StreamValue<bool> isProfilesPageLoadingStreamValue = StreamValue<bool>(
    defaultValue: false,
  );
  final StreamValue<String?> errorStreamValue = StreamValue<String?>(
    defaultValue: null,
  );
  final StreamValue<String> searchQueryStreamValue = StreamValue<String>(
    defaultValue: '',
  );
  final StreamValue<bool> showSearchFieldStreamValue = StreamValue<bool>(
    defaultValue: false,
  );
  final ScrollController profilesListScrollController = ScrollController();

  bool _isDisposed = false;
  bool _initialized = false;
  bool _profilesListScrollBound = false;
  bool _pageRequestInFlight = false;
  int _currentPage = 0;
  int _requestGeneration = 0;
  String? _initializedTenantDomain;
  StreamSubscription<String?>? _tenantScopeSubscription;
  Timer? _searchDebounceTimer;

  Future<void> init() async {
    final normalizedTenantDomain = _normalizeTenantDomain(
      _tenantScope?.selectedTenantDomain,
    );
    if (_initialized && _initializedTenantDomain == normalizedTenantDomain) {
      return;
    }
    _initialized = true;
    _initializedTenantDomain = normalizedTenantDomain;
    await loadProfiles();
  }

  Future<void> loadProfiles({String? searchQuery}) async {
    if (_isDisposed) return;
    final generation = ++_requestGeneration;
    _pageRequestInFlight = true;
    isProfilesPageLoadingStreamValue.addValue(true);
    profilesStreamValue.addValue(null);
    errorStreamValue.addValue(null);
    try {
      final normalizedSearch = (searchQuery ?? searchQueryStreamValue.value)
          .trim();
      final result = await _profilesRepository.fetchAccountProfilesPage(
        page: tenantAdminAccountProfilesRepoInt(1),
        pageSize: tenantAdminAccountProfilesRepoInt(_pageSize),
        search: normalizedSearch.isEmpty
            ? null
            : tenantAdminAccountProfilesRepoString(normalizedSearch),
      );
      if (_isDisposed || generation != _requestGeneration) return;
      profilesStreamValue.addValue(
        List<TenantAdminAccountProfile>.unmodifiable(result.items),
      );
      _currentPage = result.pagination?.currentPage ?? 1;
      hasMoreProfilesStreamValue.addValue(result.hasMore);
    } catch (error) {
      if (_isDisposed || generation != _requestGeneration) return;
      errorStreamValue.addValue(error.toString());
    } finally {
      if (!_isDisposed && generation == _requestGeneration) {
        _pageRequestInFlight = false;
        isProfilesPageLoadingStreamValue.addValue(false);
      }
    }
  }

  Future<void> loadNextProfilesPage() async {
    if (_isDisposed ||
        _pageRequestInFlight ||
        !hasMoreProfilesStreamValue.value ||
        profilesStreamValue.value == null) {
      return;
    }
    final generation = _requestGeneration;
    _pageRequestInFlight = true;
    isProfilesPageLoadingStreamValue.addValue(true);
    try {
      final requestedPage = _currentPage + 1;
      final normalizedSearch = searchQueryStreamValue.value.trim();
      final result = await _profilesRepository.fetchAccountProfilesPage(
        page: tenantAdminAccountProfilesRepoInt(requestedPage),
        pageSize: tenantAdminAccountProfilesRepoInt(_pageSize),
        search: normalizedSearch.isEmpty
            ? null
            : tenantAdminAccountProfilesRepoString(normalizedSearch),
      );
      if (_isDisposed || generation != _requestGeneration) return;
      final current = profilesStreamValue.value ?? const [];
      profilesStreamValue.addValue(
        List<TenantAdminAccountProfile>.unmodifiable([
          ...current,
          ...result.items,
        ]),
      );
      _currentPage = result.pagination?.currentPage ?? requestedPage;
      hasMoreProfilesStreamValue.addValue(result.hasMore);
    } catch (error) {
      if (_isDisposed || generation != _requestGeneration) return;
      errorStreamValue.addValue(error.toString());
    } finally {
      if (!_isDisposed && generation == _requestGeneration) {
        _pageRequestInFlight = false;
        isProfilesPageLoadingStreamValue.addValue(false);
      }
    }
  }

  void bindProfilesListScrollPagination() {
    if (_profilesListScrollBound) return;
    _profilesListScrollBound = true;
    profilesListScrollController.addListener(_handleProfilesListScroll);
  }

  void unbindProfilesListScrollPagination() {
    if (!_profilesListScrollBound) return;
    _profilesListScrollBound = false;
    profilesListScrollController.removeListener(_handleProfilesListScroll);
  }

  void _handleProfilesListScroll() {
    if (!profilesListScrollController.hasClients) return;
    const threshold = 320.0;
    final position = profilesListScrollController.position;
    if (position.pixels + threshold >= position.maxScrollExtent) {
      unawaited(loadNextProfilesPage());
    }
  }

  void updateSearchQuery(String query) {
    if (searchQueryStreamValue.value == query) return;
    searchQueryStreamValue.addValue(query);
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(_searchDebounceDuration, () {
      if (!_isDisposed) unawaited(loadProfiles());
    });
  }

  void toggleSearchFieldVisibility() {
    final next = !showSearchFieldStreamValue.value;
    showSearchFieldStreamValue.addValue(next);
    if (!next) updateSearchQuery('');
  }

  void resetProfilesState() {
    ++_requestGeneration;
    _pageRequestInFlight = false;
    _currentPage = 0;
    profilesStreamValue.addValue(null);
    hasMoreProfilesStreamValue.addValue(false);
    isProfilesPageLoadingStreamValue.addValue(false);
    errorStreamValue.addValue(null);
    searchQueryStreamValue.addValue('');
    showSearchFieldStreamValue.addValue(false);
  }

  void _bindTenantScope() {
    final tenantScope = _tenantScope;
    if (tenantScope == null) return;
    _tenantScopeSubscription = tenantScope
        .selectedTenantDomainStreamValue
        .stream
        .listen((domain) {
          if (_isDisposed) return;
          final normalized = _normalizeTenantDomain(domain);
          if (normalized == _initializedTenantDomain) return;
          _initializedTenantDomain = normalized;
          _initialized = normalized != null;
          resetProfilesState();
          if (normalized != null) unawaited(loadProfiles());
        });
  }

  String? _normalizeTenantDomain(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final uri = Uri.tryParse(
      trimmed.contains('://') ? trimmed : 'https://$trimmed',
    );
    return uri != null && uri.host.trim().isNotEmpty
        ? uri.host.trim()
        : trimmed;
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    unbindProfilesListScrollPagination();
    _tenantScopeSubscription?.cancel();
    _searchDebounceTimer?.cancel();
    profilesStreamValue.dispose();
    hasMoreProfilesStreamValue.dispose();
    isProfilesPageLoadingStreamValue.dispose();
    errorStreamValue.dispose();
    searchQueryStreamValue.dispose();
    showSearchFieldStreamValue.dispose();
    profilesListScrollController.dispose();
  }

  @override
  void onDispose() => dispose();
}
