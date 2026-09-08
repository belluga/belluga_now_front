import 'dart:async';

import 'package:characters/characters.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_candidate_selection_summary.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_group_member_page.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/controllers/tenant_admin_group_members_page_state.dart';
import 'package:stream_value/core/stream_value.dart';

typedef TenantAdminGroupMembersPageLoader =
    Future<TenantAdminNestedGroupMemberPage> Function({
      String? cursor,
      String? search,
    });
typedef TenantAdminGroupMembersMutation =
    Future<void> Function(List<String> profileIds);

final class TenantAdminGroupMembersPageController {
  TenantAdminGroupMembersPageController({
    required this.loadPage,
    required this.addMembers,
    required this.removeMembers,
    this.searchDebounce = const Duration(milliseconds: 350),
  });

  final TenantAdminGroupMembersPageLoader loadPage;
  final TenantAdminGroupMembersMutation addMembers;
  final TenantAdminGroupMembersMutation removeMembers;
  final Duration searchDebounce;

  final StreamValue<TenantAdminGroupMembersPageState> stateStreamValue =
      StreamValue<TenantAdminGroupMembersPageState>(
        defaultValue: const TenantAdminGroupMembersPageState(),
      );

  final Map<String, TenantAdminAccountProfileSelectionSummary> _itemsById = {};
  Timer? _searchTimer;
  String? _cursor;
  String? _errorMessage;
  String _search = '';
  bool _initialLoading = true;
  bool _pageLoading = false;
  bool _mutationLoading = false;
  bool _searchAvailable = false;
  bool _isFetching = false;
  bool _queuedReset = false;
  bool _isDisposed = false;
  int _generation = 0;

  Future<void> initialize() => _requestPage(reset: true);

  void updateSearch(String rawSearch) {
    if (_isDisposed) return;
    _searchTimer?.cancel();
    _generation += 1;
    _search = rawSearch.trim();
    _errorMessage = null;
    if (_search.isNotEmpty && _search.characters.length < 2) {
      _itemsById.clear();
      _cursor = null;
      _initialLoading = false;
      _pageLoading = false;
      _emit();
      return;
    }
    final generation = _generation;
    _searchTimer = Timer(searchDebounce, () {
      if (_isDisposed || generation != _generation) return;
      unawaited(_requestPage(reset: true));
    });
    _emit();
  }

  void loadMoreIfNeeded(double extentAfter) {
    if (extentAfter > 200 ||
        _initialLoading ||
        _pageLoading ||
        _mutationLoading) {
      return;
    }
    if (_cursor == null) return;
    unawaited(_requestPage(reset: false));
  }

  Future<void> add(List<String> profileIds) => _mutate(addMembers, profileIds);

  Future<void> remove(String profileId) =>
      _mutate(removeMembers, <String>[profileId]);

  Future<void> _mutate(
    TenantAdminGroupMembersMutation mutation,
    List<String> profileIds,
  ) async {
    if (_isDisposed || _mutationLoading || profileIds.isEmpty) return;
    _mutationLoading = true;
    _errorMessage = null;
    _emit();
    try {
      await mutation(profileIds);
      if (_isDisposed) return;
      await _requestPage(reset: true);
    } catch (error) {
      if (!_isDisposed) {
        _errorMessage = error.toString();
      }
    } finally {
      if (!_isDisposed) {
        _mutationLoading = false;
        _emit();
      }
    }
  }

  Future<void> _requestPage({required bool reset}) async {
    if (_isDisposed) return;
    if (_isFetching) {
      if (reset) _queuedReset = true;
      return;
    }
    if (!reset && _cursor == null) return;

    final generation = _generation;
    _isFetching = true;
    _errorMessage = null;
    if (reset) {
      _initialLoading = true;
      _pageLoading = false;
    } else {
      _pageLoading = true;
    }
    _emit();

    try {
      final page = await loadPage(
        cursor: reset ? null : _cursor,
        search: _search.isEmpty ? null : _search,
      );
      if (_isDisposed || generation != _generation) return;
      if (reset) _itemsById.clear();
      for (final item in page.items) {
        _itemsById.putIfAbsent(item.id, () => item);
      }
      _cursor = page.nextCursor;
      if (reset && _search.isEmpty) {
        _searchAvailable = _cursor != null;
      }
    } catch (error) {
      if (_isDisposed || generation != _generation) return;
      if (reset) {
        _itemsById.clear();
        _cursor = null;
      }
      _errorMessage = error.toString();
    } finally {
      _isFetching = false;
      if (!_isDisposed && generation == _generation) {
        _initialLoading = false;
        _pageLoading = false;
        _emit();
      }
      if (!_isDisposed && _queuedReset) {
        _queuedReset = false;
        unawaited(_requestPage(reset: true));
      }
    }
  }

  void _emit() {
    if (_isDisposed) return;
    stateStreamValue.addValue(
      TenantAdminGroupMembersPageState(
        items: List.unmodifiable(_itemsById.values),
        errorMessage: _errorMessage,
        initialLoading: _initialLoading,
        pageLoading: _pageLoading,
        mutationLoading: _mutationLoading,
        searchAvailable: _searchAvailable,
        search: _search,
        hasMore: _cursor != null,
      ),
    );
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _generation += 1;
    _searchTimer?.cancel();
    stateStreamValue.dispose();
  }
}
