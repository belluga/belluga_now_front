import 'dart:async';

import 'package:characters/characters.dart';
import 'package:belluga_now/application/tenant_admin/events/tenant_admin_event_occurrence_group_members_page_loader.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_candidate_selection_summary.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_profile_group.dart';
import 'package:stream_value/core/stream_value.dart';

final class TenantAdminOccurrenceRelatedProfilePickerController {
  TenantAdminOccurrenceRelatedProfilePickerController({
    required this.pageLoader,
    required this.eventId,
    required this.occurrenceId,
    required List<TenantAdminNestedProfileGroup> groups,
    required Set<String> excludedProfileIds,
    this.searchDebounce = const Duration(milliseconds: 250),
  }) : groups = List<TenantAdminNestedProfileGroup>.unmodifiable(
         groups.toList(growable: false)
           ..sort((left, right) => left.order.compareTo(right.order)),
       ),
       excludedProfileIds = Set<String>.unmodifiable(excludedProfileIds) {
    selectedGroupStreamValue.addValue(this.groups.firstOrNull);
  }

  final TenantAdminEventOccurrenceGroupMembersPageLoader pageLoader;
  final String eventId;
  final String occurrenceId;
  final List<TenantAdminNestedProfileGroup> groups;
  final Set<String> excludedProfileIds;
  final Duration searchDebounce;

  final StreamValue<TenantAdminNestedProfileGroup?> selectedGroupStreamValue =
      StreamValue<TenantAdminNestedProfileGroup?>();
  final StreamValue<List<TenantAdminAccountProfileSelectionSummary>>
  itemsStreamValue =
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
  final StreamValue<bool> searchAvailableStreamValue = StreamValue<bool>(
    defaultValue: false,
  );
  final StreamValue<String?> errorStreamValue = StreamValue<String?>();

  final Map<String, TenantAdminAccountProfileSelectionSummary> _itemsById =
      <String, TenantAdminAccountProfileSelectionSummary>{};
  Timer? _debounceTimer;
  String _search = '';
  String? _cursor;
  int _generation = 0;
  bool _isFetching = false;
  bool _isDisposed = false;
  bool _queuedReset = false;

  Future<void> initialize() => _requestPage(reset: true);

  Future<void> selectGroup(String groupId) async {
    if (_isDisposed || selectedGroupStreamValue.value?.id == groupId) return;
    final group = groups
        .where((candidate) => candidate.id == groupId)
        .firstOrNull;
    if (group == null) return;
    _generation += 1;
    _debounceTimer?.cancel();
    _search = '';
    selectedGroupStreamValue.addValue(group);
    await _requestPage(reset: true);
  }

  void updateSearch(String rawSearch) {
    if (_isDisposed) return;
    final search = rawSearch.trim();
    _generation += 1;
    _debounceTimer?.cancel();
    _search = search;
    if (search.isNotEmpty && search.characters.length < 2) {
      _queuedReset = false;
      _itemsById.clear();
      itemsStreamValue.addValue(const []);
      hasMoreStreamValue.addValue(false);
      isLoadingStreamValue.addValue(false);
      isPageLoadingStreamValue.addValue(false);
      return;
    }
    final expectedGeneration = _generation;
    _debounceTimer = Timer(searchDebounce, () {
      if (_isDisposed || expectedGeneration != _generation) return;
      unawaited(_requestPage(reset: true));
    });
  }

  Future<void> loadNextPage() async {
    if (_isDisposed || _isFetching || !hasMoreStreamValue.value) return;
    await _requestPage(reset: false);
  }

  Future<void> _requestPage({required bool reset}) async {
    if (_isDisposed) return;
    if (_isFetching) {
      if (reset) _queuedReset = true;
      return;
    }
    final group = selectedGroupStreamValue.value;
    if (group == null) {
      _itemsById.clear();
      itemsStreamValue.addValue(const []);
      hasMoreStreamValue.addValue(false);
      isLoadingStreamValue.addValue(false);
      return;
    }
    final generation = _generation;
    _isFetching = true;
    if (reset) {
      isLoadingStreamValue.addValue(true);
      isPageLoadingStreamValue.addValue(false);
    } else {
      isPageLoadingStreamValue.addValue(true);
    }
    try {
      final page = await pageLoader.loadPage(
        eventId: eventId,
        occurrenceId: occurrenceId,
        groupId: group.id,
        cursor: reset ? null : _cursor,
        search: _search,
      );
      if (_isDisposed || generation != _generation) return;
      if (reset) _itemsById.clear();
      for (final item in page.items) {
        if (!excludedProfileIds.contains(item.id)) {
          _itemsById.putIfAbsent(item.id, () => item);
        }
      }
      _cursor = page.nextCursor;
      itemsStreamValue.addValue(
        List<TenantAdminAccountProfileSelectionSummary>.unmodifiable(
          _itemsById.values,
        ),
      );
      hasMoreStreamValue.addValue(_cursor != null);
      if (reset && _search.isEmpty) {
        searchAvailableStreamValue.addValue(_cursor != null);
      }
      errorStreamValue.addValue(null);
    } catch (error) {
      if (_isDisposed || generation != _generation) return;
      if (reset) {
        _itemsById.clear();
        itemsStreamValue.addValue(const []);
      }
      hasMoreStreamValue.addValue(false);
      errorStreamValue.addValue(error.toString());
      itemsStreamValue.addValue(
        List<TenantAdminAccountProfileSelectionSummary>.unmodifiable(
          _itemsById.values,
        ),
      );
    } finally {
      _isFetching = false;
      if (!_isDisposed && generation == _generation) {
        isLoadingStreamValue.addValue(false);
        isPageLoadingStreamValue.addValue(false);
      }
      if (!_isDisposed && _queuedReset) {
        _queuedReset = false;
        unawaited(_requestPage(reset: true));
      }
    }
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _generation += 1;
    _debounceTimer?.cancel();
    selectedGroupStreamValue.dispose();
    itemsStreamValue.dispose();
    isLoadingStreamValue.dispose();
    isPageLoadingStreamValue.dispose();
    hasMoreStreamValue.dispose();
    searchAvailableStreamValue.dispose();
    errorStreamValue.dispose();
  }
}
