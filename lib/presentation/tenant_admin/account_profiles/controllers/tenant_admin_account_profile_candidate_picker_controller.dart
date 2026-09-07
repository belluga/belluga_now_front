import 'dart:async';

import 'package:characters/characters.dart';
import 'package:belluga_now/application/tenant_admin/tenant_admin_account_profile_candidate_discovery_page_loader.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_candidate.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_account_profile_id_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:stream_value/core/stream_value.dart';

class TenantAdminAccountProfileCandidatePickerController {
  TenantAdminAccountProfileCandidatePickerController({
    required this.pageLoader,
    required this.scope,
    required this.maxSelections,
    this.excludeAccountProfileId,
    List<TenantAdminAccountProfileSelectionSummary> initialSelections =
        const <TenantAdminAccountProfileSelectionSummary>[],
    this.searchDebounce = const Duration(milliseconds: 250),
  }) {
    assert(maxSelections == null || maxSelections! >= 1);
    for (final selection in initialSelections) {
      if (maxSelections != null && _selectedById.length >= maxSelections!) {
        break;
      }
      _selectedById.putIfAbsent(selection.id, () => selection);
    }
    selectedSummariesStreamValue.addValue(_selectedValues());
  }

  static const int pageSize = 20;
  static const int maxGroupMemberSelectionsPerOperation = 1000;

  final TenantAdminAccountProfileCandidateDiscoveryPageLoader pageLoader;
  final TenantAdminAccountProfileCandidateScope scope;
  final int? maxSelections;
  final String? excludeAccountProfileId;
  final Duration searchDebounce;

  final StreamValue<List<TenantAdminAccountProfileCandidate>>
  candidatesStreamValue = StreamValue<List<TenantAdminAccountProfileCandidate>>(
    defaultValue: const [],
  );
  final StreamValue<List<TenantAdminAccountProfileSelectionSummary>>
  selectedSummariesStreamValue =
      StreamValue<List<TenantAdminAccountProfileSelectionSummary>>(
        defaultValue: const [],
      );
  final StreamValue<bool> isLoadingStreamValue = StreamValue<bool>(
    defaultValue: false,
  );
  final StreamValue<bool> isPageLoadingStreamValue = StreamValue<bool>(
    defaultValue: false,
  );
  final StreamValue<bool> hasMoreStreamValue = StreamValue<bool>(
    defaultValue: false,
  );
  final StreamValue<bool> browseLimitReachedStreamValue = StreamValue<bool>(
    defaultValue: false,
  );
  final StreamValue<String?> errorStreamValue = StreamValue<String?>();

  final Map<String, TenantAdminAccountProfileCandidate> _browseCandidatesById =
      <String, TenantAdminAccountProfileCandidate>{};
  final Map<String, TenantAdminAccountProfileCandidate> _searchCandidatesById =
      <String, TenantAdminAccountProfileCandidate>{};
  final Map<String, TenantAdminAccountProfileSelectionSummary> _selectedById =
      <String, TenantAdminAccountProfileSelectionSummary>{};
  Timer? _debounceTimer;
  String _search = '';
  int _generation = 0;
  int _browseCurrentPage = 0;
  int _searchCurrentPage = 0;
  bool _browseHasMore = false;
  bool _searchHasMore = false;
  bool _browseLimitReached = false;
  bool _searchLimitReached = false;
  bool _isFetching = false;
  bool _queuedInitialRequest = false;
  bool _initialized = false;
  bool _isDisposed = false;

  Future<void> initialize() async {
    if (_isDisposed || _initialized) return;
    _initialized = true;
    await _requestPage(reset: true);
  }

  void updateSearch(String rawSearch) {
    if (_isDisposed) return;
    _generation += 1;
    final normalizedSearch = rawSearch.trim();
    _search = normalizedSearch.characters.length >= 2 ? normalizedSearch : '';
    _debounceTimer?.cancel();
    errorStreamValue.addValue(null);
    _queuedInitialRequest = false;

    if (!_isSearchMode) {
      _publishActiveSnapshot();
      isLoadingStreamValue.addValue(false);
      isPageLoadingStreamValue.addValue(false);
      if (_initialized && _browseCurrentPage == 0) {
        unawaited(_requestInitialPage());
      }
      return;
    }

    _searchCandidatesById.clear();
    _searchCurrentPage = 0;
    _searchHasMore = false;
    _searchLimitReached = false;
    _publishActiveSnapshot();

    final expectedGeneration = _generation;
    _debounceTimer = Timer(searchDebounce, () {
      if (_isDisposed || expectedGeneration != _generation) return;
      unawaited(_requestInitialPage());
    });
  }

  Future<void> loadNextPage() async {
    if (_isDisposed || !_activeHasMore || _isFetching) {
      return;
    }
    await _requestPage(reset: false);
  }

  bool toggleSelection(TenantAdminAccountProfileCandidate candidate) {
    if (_isDisposed) return false;
    if (_selectedById.remove(candidate.id) != null) {
      selectedSummariesStreamValue.addValue(_selectedValues());
      return true;
    }
    if (maxSelections != null && _selectedById.length >= maxSelections!) {
      return false;
    }
    _selectedById[candidate.id] = TenantAdminAccountProfileSelectionSummary(
      idValue: TenantAdminAccountProfileIdValue(candidate.id),
      displayNameValue: TenantAdminOptionalTextValue()
        ..parse(candidate.displayName),
      isQueryableCandidateValue: TenantAdminFlagValue(
        scope == TenantAdminAccountProfileCandidateScope.queryable,
      ),
      isContactCapableCandidateValue: TenantAdminFlagValue(
        scope == TenantAdminAccountProfileCandidateScope.contactCapable,
      ),
    );
    selectedSummariesStreamValue.addValue(_selectedValues());
    return true;
  }

  bool isSelected(String accountProfileId) =>
      _selectedById.containsKey(accountProfileId);

  void removeSelection(String accountProfileId) {
    if (_isDisposed || _selectedById.remove(accountProfileId) == null) return;
    selectedSummariesStreamValue.addValue(_selectedValues());
  }

  List<TenantAdminAccountProfileSelectionSummary> get selectedSummaries =>
      _selectedValues();

  Future<void> _requestInitialPage() async {
    if (_isFetching) {
      _queuedInitialRequest = true;
      return;
    }
    await _requestPage(reset: true);
  }

  Future<void> _requestPage({required bool reset}) async {
    if (_isDisposed || _isFetching) return;
    final generation = _generation;
    final searchMode = _isSearchMode;
    final requestSearch = searchMode ? _search : '';
    final requestedPage = reset
        ? 1
        : (searchMode ? _searchCurrentPage : _browseCurrentPage) + 1;
    _isFetching = true;
    if (reset) {
      isLoadingStreamValue.addValue(true);
      isPageLoadingStreamValue.addValue(false);
    } else {
      isPageLoadingStreamValue.addValue(true);
    }
    try {
      final result = await pageLoader.loadPage(
        scope: scope,
        search: requestSearch,
        pageNumber: requestedPage,
        pageSize: pageSize,
        excludeAccountProfileId: excludeAccountProfileId,
      );
      if (_isDisposed ||
          generation != _generation ||
          searchMode != _isSearchMode ||
          requestSearch != (_isSearchMode ? _search : '')) {
        return;
      }
      final candidatesById = searchMode
          ? _searchCandidatesById
          : _browseCandidatesById;
      if (reset) candidatesById.clear();
      for (final candidate in result.items) {
        candidatesById.putIfAbsent(candidate.id, () => candidate);
      }
      if (searchMode) {
        _searchCurrentPage = result.page == 0 ? requestedPage : result.page;
        _searchHasMore = result.hasMore;
        _searchLimitReached = result.browseLimitReached;
      } else {
        _browseCurrentPage = result.page == 0 ? requestedPage : result.page;
        _browseHasMore = result.hasMore;
        _browseLimitReached = result.browseLimitReached;
      }
      _publishActiveSnapshot();
      errorStreamValue.addValue(null);
    } catch (error) {
      if (_isDisposed || generation != _generation) return;
      if (reset) {
        final candidatesById = searchMode
            ? _searchCandidatesById
            : _browseCandidatesById;
        candidatesById.clear();
        candidatesStreamValue.addValue(const []);
      }
      hasMoreStreamValue.addValue(false);
      errorStreamValue.addValue(error.toString());
    } finally {
      _isFetching = false;
      if (!_isDisposed && generation == _generation) {
        isLoadingStreamValue.addValue(false);
        isPageLoadingStreamValue.addValue(false);
      }
      if (!_isDisposed && _queuedInitialRequest) {
        _queuedInitialRequest = false;
        unawaited(_requestInitialPage());
      }
    }
  }

  bool get _isSearchMode => _search.characters.length >= 2;

  bool get _activeHasMore => _isSearchMode ? _searchHasMore : _browseHasMore;

  void _publishActiveSnapshot() {
    final candidatesById = _isSearchMode
        ? _searchCandidatesById
        : _browseCandidatesById;
    candidatesStreamValue.addValue(
      List<TenantAdminAccountProfileCandidate>.unmodifiable(
        candidatesById.values,
      ),
    );
    hasMoreStreamValue.addValue(_activeHasMore);
    browseLimitReachedStreamValue.addValue(
      _isSearchMode ? _searchLimitReached : _browseLimitReached,
    );
  }

  List<TenantAdminAccountProfileSelectionSummary> _selectedValues() {
    return List<TenantAdminAccountProfileSelectionSummary>.unmodifiable(
      _selectedById.values,
    );
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _generation += 1;
    _debounceTimer?.cancel();
    candidatesStreamValue.dispose();
    selectedSummariesStreamValue.dispose();
    isLoadingStreamValue.dispose();
    isPageLoadingStreamValue.dispose();
    hasMoreStreamValue.dispose();
    browseLimitReachedStreamValue.dispose();
    errorStreamValue.dispose();
  }
}
