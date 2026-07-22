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
    assert(maxSelections >= 1 && maxSelections <= 50);
    for (final selection in initialSelections) {
      if (_selectedById.length >= maxSelections) break;
      _selectedById.putIfAbsent(selection.id, () => selection);
    }
    selectedSummariesStreamValue.addValue(_selectedValues());
  }

  static const int pageSize = 20;

  final TenantAdminAccountProfileCandidateDiscoveryPageLoader pageLoader;
  final TenantAdminAccountProfileCandidateScope scope;
  final int maxSelections;
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

  final Map<String, TenantAdminAccountProfileCandidate> _candidatesById =
      <String, TenantAdminAccountProfileCandidate>{};
  final Map<String, TenantAdminAccountProfileSelectionSummary> _selectedById =
      <String, TenantAdminAccountProfileSelectionSummary>{};
  Timer? _debounceTimer;
  String _search = '';
  int _generation = 0;
  int _currentPage = 0;
  bool _isFetching = false;
  bool _queuedInitialRequest = false;
  bool _isDisposed = false;

  void updateSearch(String rawSearch) {
    if (_isDisposed) return;
    _generation += 1;
    _search = rawSearch.trim();
    _debounceTimer?.cancel();
    _candidatesById.clear();
    _currentPage = 0;
    candidatesStreamValue.addValue(const []);
    hasMoreStreamValue.addValue(false);
    browseLimitReachedStreamValue.addValue(false);
    errorStreamValue.addValue(null);

    if (_search.characters.length < 2) {
      isLoadingStreamValue.addValue(false);
      isPageLoadingStreamValue.addValue(false);
      return;
    }

    final expectedGeneration = _generation;
    _debounceTimer = Timer(searchDebounce, () {
      if (_isDisposed || expectedGeneration != _generation) return;
      unawaited(_requestInitialPage());
    });
  }

  Future<void> loadNextPage() async {
    if (_isDisposed ||
        _search.characters.length < 2 ||
        !hasMoreStreamValue.value ||
        _isFetching) {
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
    if (_selectedById.length >= maxSelections) return false;
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
    final requestedPage = reset ? 1 : _currentPage + 1;
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
        search: _search,
        pageNumber: requestedPage,
        pageSize: pageSize,
        excludeAccountProfileId: excludeAccountProfileId,
      );
      if (_isDisposed || generation != _generation) return;
      if (reset) _candidatesById.clear();
      for (final candidate in result.items) {
        _candidatesById.putIfAbsent(candidate.id, () => candidate);
      }
      _currentPage = result.page == 0 ? requestedPage : result.page;
      candidatesStreamValue.addValue(
        List<TenantAdminAccountProfileCandidate>.unmodifiable(
          _candidatesById.values,
        ),
      );
      hasMoreStreamValue.addValue(result.hasMore);
      browseLimitReachedStreamValue.addValue(result.browseLimitReached);
      errorStreamValue.addValue(null);
    } catch (error) {
      if (_isDisposed || generation != _generation) return;
      if (reset) {
        _candidatesById.clear();
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
